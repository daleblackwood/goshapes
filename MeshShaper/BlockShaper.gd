@tool
extends Shaper
class_name BlockShaper

@export var cap_type: CapStyles.Type = CapStyles.Type.Flat_Cap: set = set_cap_type

@export var cap_style: Resource: set = set_cap_style

@export var wall_type: WallStyles.Type = WallStyles.Type.Bevel_Wall: set = set_wall_type

@export var wall_style: Resource: set = set_wall_style

@export_range(0.0, 20.0, 0.5) var base_depth = 0.0: set = set_base_depth

@export var base_type: CapStyles.Type = CapStyles.Type.None: set = set_base_type

@export var base_style: Resource: set = set_base_style

enum ColliderType { None, CapOnly, Simple, Ridged, Accurate }
@export var collider_type: ColliderType = ColliderType.Simple:
	set(value):
		collider_type = value
		emit_changed()


@export_range(0.0, 10.0, 1.0) var collider_ridge: float = 0.0:
	set(value):
		collider_ridge = value
		emit_changed()
		

var watcher_cap := ResourceWatcher.new(Callable(self, "mark_dirty"))
var watcher_wall := ResourceWatcher.new(Callable(self, "mark_dirty"))
var watcher_base := ResourceWatcher.new(Callable(self, "mark_dirty"))

var is_dirty = false

func _init() -> void:
	if not cap_style:
		set_cap_style(CapStyles.create(cap_type))
	if not wall_style:
		set_wall_style(WallStyles.create(wall_type))


func set_cap_type(value: CapStyles.Type):
	if cap_type != value:
		cap_type = value
		set_cap_style(CapStyles.create(cap_type))


func set_cap_style(value: Resource):
	if cap_style != value:
		ResourceUtils.copy_props(cap_style, value)
		cap_style = value
		watcher_cap.watch(cap_style)
		mark_dirty()
	
	
func set_wall_type(value: WallStyles.Type):
	if wall_type != value:
		wall_type = value
		set_wall_style(WallStyles.create(wall_type))
	
	
func set_wall_style(value: Resource):
	if wall_style != value:
		ResourceUtils.copy_props(wall_style, value)
		wall_style = value
		watcher_wall.watch(wall_style)
		mark_dirty()
	
	
func set_base_depth(value: float):
	if base_depth != value:
		base_depth = value
		mark_dirty()
	
	
func set_base_type(value: CapStyles.Type):
	if base_type != value:
		base_type = value
		set_base_style(CapStyles.create(base_type))


func set_base_style(value: Resource):
	if base_style != value:
		ResourceUtils.copy_props(base_style, value)
		base_style = value
		watcher_base.watch(base_style)
		mark_dirty()

	
func mark_dirty():
	if is_dirty:
		return
	is_dirty = true
	_update.call_deferred()
	
	
func _update():
	is_dirty = false
	emit_changed()
	

func get_builder() -> ShapeBuilder:
	return BlockBuilder.new(self)
	

class BlockBuilder extends ShapeBuilder:
	
	var style: BlockShaper
	func _init(_style: BlockShaper):
		style = _style
		
	func build(_host: Node3D, _path: PathData) -> void:
		host = _host
		path = _path
		if style.cap_style != null:
			style.cap_style.get_builder().build(host, path)
		if style.wall_style != null:
			style.wall_style.get_builder().build(host, path)
		
		
	func add_cap_job(joblist = []) -> void:
		if style.cap_style != null:
			joblist.append(style.cap_style.get_build_job(path))
		
#
#	func build(runner: JobRunner, _host: Node3D, _path: PathData) -> void:
#		host = _host
#		path = _path
#		if style.collider_type == BlockShaper.ColliderType.Accurate:
#			runner.run_group(get_build_jobs(), host, apply_all_meshes)
#		elif style.collider_type == BlockShaper.ColliderType.None:
#			runner.run_group(get_build_jobs(), host, apply_block_meshes)
#		else:
#			runner.run_group(get_build_jobs(), host, apply_block_meshes)
#			runner.run_group(get_collider_jobs(), host, apply_collider)
#
##
#	func get_build_jobs(joblist = Array[Job]) -> Array[Job]:
#		var cap_job = get_cap_job(path_data)
#		if cap_job != null:
#			joblist.append(cap_job)
#		if style.wall_style != null:
#			style.wall_style.get_build_job(path)
#			var wall_builder = style.wall_style.get_builder()
#			if wall_builder != null:
#				joblist.append(BuildJob.new(wall_builder, style.wall_style.duplicate(), path_data))    
#		if style.base_style != null:
#			var base_cap_builder = CapStyles.create_builder(style.base_type)
#			if base_cap_builder != null:
#				var base_builder = BaseBuilder.new(base_cap_builder, style.base_depth)
#				joblist.append(BuildJob.new(base_builder, style.base_style.duplicate(), path_data))
#		return joblist
		
		
#	func get_cap_job(joblist = Array[Job], path_data: PathData) -> Job:
#		if style.cap_style != null:
#			return style.cap_style.get_build_job()
#		return null
#
#
#	func get_collider_jobs(joblist = Array[Job]) -> Array[Job]:
#		var cap_job = get_cap_job(path_data)
#		if cap_job != null:
#			joblist.append(cap_job)
#		if style.collider_type != ColliderType.CapOnly:
#			var wall_builder = WallStyles.create_builder(WallStyles.Type.Bevel_Wall)
#			if wall_builder != null:
#				var wall_style = WallStyles.create_style(WallStyles.Type.Bevel_Wall)
#				wall_style.height = style.base_depth
#				if style.wall_type == WallStyles.Type.Bevel_Wall:
#					wall_style.height = style.wall_style.height
#				elif style.wall_type == WallStyles.Type.Mesh_Wall and wall_style.height == 0:
#					wall_style.height = MeshUtils.calc_mesh_height(style.wall_style.mesh, style.wall_style.scale)
#				if style.collider_type == ColliderType.Ridged:
#					path_data = PathUtils.move_path_down(path_data, -style.collider_ridge)
#					wall_style.height += style.collider_ridge
#				joblist.append(BuildJob.new(wall_builder, wall_style, path_data))
#		return joblist
		
		
	func build_done(group: JobGroup) -> void:
		if group.output.size() < 1:
			printerr("No output")
			return
		var block_mesh: ArrayMesh = group.output[0]
		apply_mesh(block_mesh)
		var collider_mesh: ArrayMesh = null
		if group.output.size() == 2:
			collider_mesh = group.output[1]
		elif style.collider_type == ColliderType.ACCURATE:
			collider_mesh = group.output[0]
		if collider_mesh != null:
			apply_collider(collider_mesh)
		
		

	func apply_mesh(mesh: ArrayMesh) -> void:
		var mesh_node = SceneUtils.get_or_create(host, "Mesh", MeshInstance3D)
		mesh_node.transform = Transform3D()
		mesh_node.mesh = mesh
		
		
	func apply_collider(mesh: ArrayMesh) -> void:
		var collider_body = SceneUtils.get_or_create(host, "Collider", StaticBody3D)
		collider_body.transform = Transform3D()
		var collider_shape = SceneUtils.get_or_create(collider_body, "CollisionShape", CollisionShape3D)
		collider_shape.shape = mesh.create_trimesh_shape()
		collider_shape.transform = Transform3D()
