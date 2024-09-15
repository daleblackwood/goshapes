@tool
class_name WallMeshSegmentShaper
extends WallShaper
## A Shaper that wraps repeating mesh geometry around the path

## The mesh to repeat around the path (repeats along the x-axis)
@export var mesh: Mesh: 
	set(value):
		if mesh != value:
			mesh = value
			emit_changed()
	
## The scale to apply to each mesh segment	
@export_range(0.1, 10.0, 0.1) var scale := 1.0:
	set(value):
		if scale != value:
			scale = value
			emit_changed()
		
## Causes the path to close between the first and last point
@export var closed := true:
	set(value):
		if closed != value:
			closed = value
			emit_changed()
			

## The material to apply to the generated mesh
@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()


## An optional low poly mesh for collisions and quicker calculations
@export var lod_distance := 100.0: 
	set(value):
		if lod_distance != value:
			lod_distance = value
			emit_changed()
			

## The material to apply to the generated mesh
@export var gaps: Array[int] = []:
	set(value):
		if gaps != value:
			gaps = value
			emit_changed()
			

func create_builders() -> Array[ShapeBuilder]:
	return [WallMeshSegmentBuilder.new(self)]
	
			
class WallMeshSegmentBuilder extends WallBuilder:
	
	var style: WallMeshSegmentShaper
	var use_low_poly := false
	var corners := PackedVector3Array()
	var mesh_cache: Array[ArrayMesh] = []
	var centers := PackedVector3Array()
	var corner_cache := PackedVector3Array()
	
	func _init(_style: WallMeshSegmentShaper) -> void:
		super._init(_style)
		style = _style
		
	
	func reset() -> void:
		pass
		
		
	func get_build_jobs(data: GoshapeBuildData, offset: int) -> Array[GoshapeJob]:
		var jobs: Array[GoshapeJob] = []
		var corner_count := data.path.get_corner_count()
		if corner_count < 1:
			return []
		corners = PackedVector3Array()
		corners.resize(corner_count)
		for i in range(corner_count):
			corners.set(i, data.path.get_corner_position(i))
		var reuses := PackedByteArray()
		reuses.resize(corner_count)
		if data.rebuild:
			corner_cache.resize(0)
		if not data.rebuild and corner_cache.size() > 0:
			reuses.fill(1)
			for i in range(corner_count):
				var same := false
				if i < corner_cache.size():
					var cache_corner := corner_cache[i % corner_cache.size()]
					same = cache_corner == corners[i % corner_count]
				if not same or meshes[i % meshes.size()] == null:
					reuses.set(i, 0)
					reuses.set((i + 1) % corner_count, 0)
					reuses.set((i - 1 + corner_count) % corner_count, 0)
		
		var paths := PathUtils.split_path_by_corner(data.path)
		var path_count := paths.size()
		centers.resize(path_count)
		for i in range(path_count):
			var path := paths[i]
			var center := (path.get_point(0) + path.get_point(path.point_count - 1)) * 0.5
			centers.set(i, -center)
		for i in range(path_count):
			paths[i] = PathUtils.move_path(paths[i], -centers[i])
		
		meshes.resize(path_count)
			
		for i in range(path_count):
			var path_data := data.duplicate()
			path_data.path = paths[i]
			path_data.index = i
			var reuse = reuses[i] == 1
			if reuse:
				jobs.append(GoshapeJob.new(self, path_data, retreive, offset))
			else:
				jobs.append(GoshapeJob.new(self, path_data, build, offset))
			jobs.append(GoshapeJob.new(self, path_data, commit, offset + 1, GoshapeJob.Mode.Scene))
		return jobs
		
	
	func retreive(data: GoshapeBuildData) -> void:
		if data.index >= mesh_cache.size():#or data.index >= meshes.size():
			return
		meshes[data.index] = mesh_cache[data.index]
		
					
	func commit(data: GoshapeBuildData) -> void:
		if data.index >= meshes.size():
			return
		var mesh := meshes[data.index]
		#if mesh == null:
		#	return
		var instance := apply_mesh(data.parent, mesh)
		#if instance == null:
		#	return
		var center = centers[data.index % centers.size()]
		instance.transform.origin = center
		instances.append(instance)
		mesh_cache.resize(meshes.size())
		mesh_cache[data.index] = mesh
		corner_cache.resize(meshes.size())
		corner_cache[data.index] = corners[data.index]
		

	func build_sets(path: GoshapePath) -> Array[MeshSet]:
		var wall_mesh = style.mesh
		return build_wall_mesh(path, wall_mesh)
		
		
	func build_wall_mesh(path: GoshapePath, ref_mesh: Mesh) -> Array[MeshSet]:
		if not ref_mesh:
			return []
			
		var surface_count := ref_mesh.get_surface_count()
		var materials: Array[Material] = []
		if style.material != null:
			materials = [style.material]
		elif surface_count > 0 and ref_mesh.surface_get_material(0):
			materials.resize(surface_count)
			for i in range(surface_count):
				materials[i] = ref_mesh.surface_get_material(i)
		var scale := style.scale
		var closed := style.closed
		var material_count := materials.size()
		var point_count := path.points.size()
		for i in range(style.gaps.size()):
			style.gaps[i] = clamp(style.gaps[i], 0, path.get_corner_count())
		var gaps := style.gaps
		if point_count < 2:
			return []
			
		var meshsets := MeshUtils.mesh_to_sets(ref_mesh)
		var meshset_count := meshsets.size()
		for i in range(meshset_count):
			var meshset := meshsets[i]
			meshset = MeshUtils.scale_mesh(meshset, scale)
			meshset = MeshUtils.wrap_mesh_to_path(meshset, path, false, gaps)
			meshset = MeshUtils.taper_mesh(meshset, path, path.taper)
			if material_count > 0:
				meshset.material = materials[i % material_count]
			meshsets[i] = meshset
		return meshsets
