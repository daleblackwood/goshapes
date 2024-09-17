@tool
class_name WallMeshShaper
extends WallShaper
## A Shaper that wraps repeating mesh geometry around the path

## The mesh to repeat around the path (repeats along the x-axis)
@export var mesh: Mesh: 
	set(value):
		mesh = value
		emit_changed()
	
## The scale to apply to each mesh segment	
@export_range(0.1, 10.0, 0.1) var scale := 1.0:
	set(value):
		scale = value
		emit_changed()
		
## Causes the path to close between the first and last point
@export var closed := true:
	set(value):
		closed = value
		emit_changed()

## The material to apply to the generated mesh
@export var material: Material:
	set(value):
		material = value
		emit_changed()

			
## An optional low poly mesh for collisions and quicker calculations
@export var mesh_low_poly: Mesh: 
	set(value):
		mesh_low_poly = value
		emit_changed()
			
## An optional low poly mesh for collisions and quicker calculations
@export var lod_distance := 100.0: 
	set(value):
		lod_distance = value
		emit_changed()
			
## The material to apply to the generated mesh
@export var gaps: Array[int] = []:
	set(value):
		if gaps != value:
			gaps = value
			emit_changed()
	

func create_builders() -> Array[ShapeBuilder]:
	return [WallMeshBuilder.new(self)]
	
			
class WallMeshBuilder extends WallBuilder:
	
	var style: WallMeshShaper
	var use_low_poly := false
	
	func _init(_style: WallMeshShaper):
		super._init(_style)
		style = _style
		
		
	func get_build_jobs(data: GoshapeBuildData, offset: int) -> Array[GoshapeJob]:
		var base_offset = offset
		if style.mesh_low_poly != null:
			base_offset += 2
			use_low_poly = true
		var jobs := super.get_build_jobs(data, base_offset)
		if use_low_poly:
			jobs.append(GoshapeJob.new(self, data, build_low, offset))
			jobs.append(GoshapeJob.new(self, data, commit_low, offset + 1, GoshapeJob.Mode.Scene))
		if should_build_colliders():
			jobs.append(GoshapeJob.new(self, data, commit_colliders, offset + 10, GoshapeJob.Mode.Scene))
		return jobs
		
		
	func build_low(data: GoshapeBuildData) -> void:
		var meshsets = build_wall_mesh(data.path, style.mesh_low_poly)
		var mesh_low = MeshUtils.build_meshes(meshsets, null)
		meshes.append(mesh_low)
		
		
	func commit_low(data: GoshapeBuildData) -> void:
		var mesh_low = meshes[0]
		var instance = apply_mesh(data.parent, mesh_low, "MeshLow")
		instances.append(instance)
		
		
	func commit(data: GoshapeBuildData) -> void:
		super.commit(data)
		var instance_count = instances.size()
		if instance_count > 1 and use_low_poly:
			var range = style.lod_distance
			for i in range(instance_count):
				var is_low = i < instance_count / 2
				var instance = instances[i]
				if is_low:
					instance.visibility_range_begin = range
				else:
					instance.visibility_range_end = range
		

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
			meshset = MeshUtils.wrap_mesh_to_path(meshset, path, closed, gaps)
			meshset = MeshUtils.taper_mesh(meshset, path, path.taper)
			if material_count > 0:
				meshset.material = materials[i % material_count]
			meshsets[i] = meshset
		return meshsets
