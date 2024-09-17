@tool
class_name WallMeshSegmentShaper
extends WallShaper
## A Shaper that wraps repeating mesh geometry around the path

@export var warning := "EXPERIMENTAL SHAPER":
	set(value):
		pass

## The mesh to repeat around the path (repeats along the x-axis)
@export var mesh: Mesh: 
	set(value):
		mesh = value
		set_dirty(true)
	
## The scale to apply to each mesh segment	
@export_range(0.1, 10.0, 0.1) var scale := 1.0:
	set(value):
		scale = value
		set_dirty(true)
	
## Causes the path to close between the first and last point
@export var closed := true:
	set(value):
		closed = value
		set_dirty()

## The material to apply to the generated mesh
@export var material: Material:
	set(value):
		material = value
		set_dirty()

## An optional low poly mesh for collisions and quicker calculations
@export var lod_distance := 500.0: 
	set(value):
		lod_distance = value
		set_dirty()
		
## The mesh to repeat around the path (repeats along the x-axis)
@export var low_poly_mesh: Mesh: 
	set(value):
		low_poly_mesh = value
		set_dirty(true)
			
## The material to apply to the generated mesh
@export var gaps: Array[int] = []:
	set(value):
		gaps = value
		set_dirty()
			
@export var mesh_caching := true:
	set(value):
		mesh_caching = value
		set_dirty(true)
		
var rebuild_next := false
		
func set_dirty(rebuild := false) -> void:
	if rebuild:
		rebuild_next = true
	emit_changed()
			

func create_builders() -> Array[ShapeBuilder]:
	return [WallMeshSegmentBuilder.new(self)]
	

class WallMeshSegmentData:
	var anchor := Vector3.ZERO
	var reuse := false
	var mesh: ArrayMesh
	var path: GoshapePath


class WallMeshSegmentBuilder extends WallBuilder:
	
	var style: WallMeshSegmentShaper
	var build_low_poly := false
	var commits: Array[WallMeshSegmentData] = []
	var builds: Array[WallMeshSegmentData] = []
	var build_count := 0
	var parents: Array[Node3D]
	
	func _init(_style: WallMeshSegmentShaper) -> void:
		super._init(_style)
		style = _style
		
	
	func reset() -> void:
		pass
		
		
	func get_build_jobs(data: GoshapeBuildData, offset: int) -> Array[GoshapeJob]:
		var jobs: Array[GoshapeJob] = []
		if style.mesh == null:
			return []
		
		var rebuild = data.rebuild or not style.mesh_caching
		if style.rebuild_next:
			rebuild = true
			style.rebuild_next = false
			
		build_low_poly = style.low_poly_mesh != null
		
		var paths := PathUtils.split_path_by_corner(data.path)
		var path_count = paths.size()
		build_count = path_count
		if build_low_poly:
			build_count *= 2
		builds.resize(build_count)
		
		# calculate builds and reuses
		var reuse_count := 0 # used to offset rebuilds 
		for i in range(build_count):
			var build := WallMeshSegmentData.new()
			var path = paths[i % path_count]
			build.anchor = (path.get_point(0) + path.get_point(path.point_count - 1)) * 0.5
			build.path = PathUtils.move_path(path, -build.anchor)
			build.reuse = not rebuild and commits.size() > i
			if build.reuse:
				var committed := commits[i]
				if committed == null or committed.mesh == null or committed.anchor != build.anchor:
					build.reuse = false
			if build.reuse:
				reuse_count += 1
			builds[i] = build
		
		# enqueue jobs
		for i in range(build_count):
			var build_info = builds[i]
			var build_data := data.duplicate()
			build_data.path = build_info.path
			build_data.index = i
			var build_order := offset
			var commit_order := build_order
			if build_low_poly and i > (build_count / 2):
				# build higher poly versions last
				build_order += path_count
				commit_order += path_count * 2
			if build_info.reuse:
				build_info.mesh = commits[i].mesh
			else:
				build_order += reuse_count # place at back of queue
				commit_order += reuse_count
			jobs.append(GoshapeJob.new(self, build_data, build_segment, build_order))
			jobs.append(GoshapeJob.new(self, build_data, commit_segment, commit_order, GoshapeJob.Mode.Scene))
			if should_build_colliders() and (not build_low_poly or i < (build_count / 2)):
				jobs.append(GoshapeJob.new(self, build_data, commit_collider, commit_order + build_count, GoshapeJob.Mode.Scene))
		return jobs
		
		
	func build_segment(data: GoshapeBuildData) -> void:
		var use_low_poly = build_low_poly and data.index < (build_count / 2)
		var build_info := builds[data.index]
		if build_info.reuse:
			build_info.mesh = commits[data.index].mesh
		if build_info.mesh == null:
			var mesh_in := style.mesh if not use_low_poly else style.low_poly_mesh
			var meshsets := build_wall_mesh(data.path, mesh_in)
			build_info.mesh = MeshUtils.build_meshes(meshsets, null)
			if build_info.mesh == null:
				return
			build_info.mesh.resource_name = "%s%s%d" % [data.parent.name, tag, data.index]
		if meshes.size() <= data.index:
			meshes.resize(data.index + 1)
		meshes[data.index] = build_info.mesh
		
					
	func commit_segment(data: GoshapeBuildData) -> void:
		if data.index >= builds.size():
			return
		var build := builds[data.index]
		if build == null or build.mesh == null:
			return
		var parent_name = build.mesh.resource_name
		var parent_index = data.index
		if build_low_poly and data.index >= (build_count / 2):
			parent_index = parent_index - (build_count / 2)
		if parent_index >= parents.size():
			parents.resize(parent_index + 1)
		if parents[parent_index] == null:
			parents[parent_index] = SceneUtils.add_child(data.parent, Node3D.new())
			parents[parent_index].name = parent_name
			parents[parent_index].transform.origin = build.anchor
		var parent = parents[parent_index]
		parent.set_display_folded(true)
		var instance := apply_mesh(parent, build.mesh)
		if instance == null:
			return
		var instance_name = parent_name + "Mesh"
		if build_low_poly:
			var range = style.lod_distance
			if data.index < (build_count / 2):
				instance_name = parent_name + "MeshLow"
			else:
				var low_poly_index := data.index - (build_count / 2)
				var low_poly_version := instances[low_poly_index] if low_poly_index < instances.size() else null
				if low_poly_version != null:
					low_poly_version.visibility_range_begin = range
					instance.visibility_range_end = range
					instance_name = parent_name + "MeshHigh"
		instance.name = instance_name
		if instances.size() < build_count:
			instances.resize(build_count)
		instances[data.index] = instance
		if commits.size() < build_count:
			commits.resize(build_count)
		commits[data.index] = build
		
		
	func commit_collider(data: GoshapeBuildData) -> void:
		if data.index >= builds.size():
			return
		var build := builds[data.index]
		if build == null or build.mesh == null:
			return
		var collision_mesh := build.mesh
		var parent = parents[data.index]
		apply_collider(parent, collision_mesh)
	
		
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
