@tool
extends Path3D
class_name Block

@export var inverted = false:
	set(value): set_inverted(value)
	
#@export_range(-1.0, 2.0) var taper: float = 0.0: 
@export_range(0.0, 2.0) var taper: float = 0.0: 
	set = set_taper
	
@export var recenter = false:
	set = set_recenter
	
@export var cascade_twists = false

@export var path_twists : Array[int]:
	set = set_path_twists
	
@export var path_mod: Resource:
	set = set_path_mod
	
@export_file("*.tres") var style_file: String:
	set = set_style_file,
	get = get_style_file
	
@export var style: Resource:
	set = set_style

var is_dirty = false
var is_dragging = false
var mesh_node: MeshInstance3D
var collider_body: StaticBody3D
var collider_shape: CollisionShape3D
var edit_proxy = null
var is_line: bool:
	get = get_is_line
var cap_data: PathData = null
var is_editing = false:
	get = _get_is_editing
var mouse_down = false
var watcher_style := ResourceWatcher.new(Callable(self, "mark_dirty"))
var watcher_pathmod := ResourceWatcher.new(Callable(self, "mark_dirty"))

func _ready() -> void:
	if curve == null:
		curve = Curve3D.new()
	if ResourceUtils.is_local(curve):
		curve = curve.duplicate(true)
		

func _enter_tree() -> void:
	set_display_folded(true)
	
	
func _exit_tree() -> void:
	if _get_is_editing():
		_edit_end()
		
		
func _get_is_editing() -> bool:
	return self.edit_proxy != null
	
		
func _edit_begin(edit_proxy) -> void:
	if _get_is_editing():
		return
	self.edit_proxy = edit_proxy
	set_display_folded(true)
	if not style:
		print("new style")
		set_style(edit_proxy.create_block_style())
	if not path_mod:
		print("new path mod")
		set_path_mod(edit_proxy.create_path_mod())
	if curve.get_point_count() < 2:
		print("new curve")
		curve.clear_points()
		if path_mod.line > 0.0:
			var extent = path_mod.line * 0.5
			curve.add_point(Vector3(-extent, 0, 0))
			curve.add_point(Vector3(extent, 0, 0))
		else:
			var extent = 4.0
			curve.add_point(Vector3(-extent, 0, -extent))
			curve.add_point(Vector3(extent, 0, -extent))
			curve.add_point(Vector3(extent, 0, extent))
			curve.add_point(Vector3(-extent, 0, extent))
	curve_changed.connect(mark_dirty)
	watcher_style.watch(style)
	watcher_pathmod.watch(path_mod)
	print("Editing block %s" % name)
	
	
func _edit_end() -> void:
	self.edit_proxy = null
	watcher_style.unwatch()
	watcher_pathmod.unwatch()
	curve_changed.disconnect(mark_dirty)
	

func set_style_file(path: String) -> void:
	var res = load(path)
	set_style(res)
	
	
func get_style_file() -> String:
	if style == null or style.resource_local_to_scene:
		return ""
	return style.resource_path
	
	
func set_style(value: Resource) -> void:
	style = value
	watcher_style.watch(style)
	mark_dirty()
	
	
func set_taper(value: float) -> void:
	taper = value
	mark_dirty()
	
	
func set_path_mod(value: Resource) -> void:
	path_mod = value
	watcher_pathmod.watch(path_mod)
	mark_dirty()
	

func set_inverted(value):
	inverted = value
	mark_dirty()
	

func set_path_twists(value: Array[int]):
	if value != null and path_twists != null and cascade_twists:
		var prev_twist_count = path_twists.size()
		var new_twist_count = value.size()
		if new_twist_count == prev_twist_count:
			var change_i = -1
			var change_a = 0.0
			for i in new_twist_count:
				if not value[i]:
					continue
				if value[i] != path_twists[i]:
					change_i = i
					change_a = value[i] - path_twists[i]
					break
			if change_i >= 0 and change_i < new_twist_count - 1:
				value = value.duplicate(true)
				for i in range(change_i + 1, new_twist_count):
					value[i] = value[i] + change_a
	path_twists = value
	mark_dirty()
	
	
func set_recenter(value):
	if value:
		recenter_points()
		
		
func recenter_points():
	var center = PathUtils.get_curve_center(curve)
	PathUtils.move_curve(curve, -center)
	transform.origin += center
	if mesh_node:
		mesh_node.transform = Transform3D()
	if collider_body:
		collider_body.transform = Transform3D()
	mark_dirty()

	
func mark_dirty():
	is_dirty = true
	call_deferred("_update")
	
	
func get_is_line():
	return path_mod.line > 0.0
	
	
func _update():
	if not Engine.is_editor_hint():
		return
	if not get_tree():
		return
	if not edit_proxy:
		return
	if not is_dirty:
		return
	if mouse_down:
		call_deferred("_update")
		return
	if is_dragging:
		call_deferred("_update")
		return
	
	build()
	is_dirty = false
	
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == 0:
			mouse_down = event.is_pressed()
	
	
func build() -> void:
	if path_mod.flatten:
		PathUtils.flatten_curve(curve)
		
	if not path_mod.flatten:
		PathUtils.twist_curve(curve)
	
	if not style:
		print("no style")
		return
	
	var runner = edit_proxy.runner
	if runner.is_busy:
		mark_dirty()
		return
		
	_build(runner)
		

func _build(runner: JobRunner) -> void:
	if not style:
		return
		
	var use_collider = path_mod.collider_type != BlockPathMod.ColliderType.None
	if not use_collider:
		SceneUtils.remove(self, "Collider")
		collider_body = null
	
	if path_mod.collider_type == BlockPathMod.ColliderType.Accurate:
		runner.run_group(get_build_jobs(), self, "apply_all_meshes")
	elif path_mod.collider_type == BlockPathMod.ColliderType.None:
		runner.run_group(get_build_jobs(), self, "apply_block_meshes")
	else:
		runner.run_group(get_build_jobs(), self, "apply_block_meshes")
		runner.run_group(get_collider_jobs(), self, "apply_collider")
		
	is_dirty = false
		
		
func remove_control_points() -> void:
	PathUtils.remove_control_points(curve)
	mark_dirty()
	
	
func get_build_jobs(joblist: Array = []) -> Array:
	var path_data = get_path_data(path_mod.interpolate)
	var cap_job = get_cap_job(path_data)
	if cap_job != null:
		joblist.append(cap_job)
	if style.wall_style != null:
		var wall_builder = WallStyles.create_builder(style.wall_type)
		if wall_builder != null:
			joblist.append(BuildJob.new(wall_builder, style.wall_style.duplicate(), path_data))	
	if style.base_style != null:
		var base_cap_builder = CapStyles.create_builder(style.base_type)
		if base_cap_builder != null:
			var base_builder = BaseBuilder.new(base_cap_builder, style.base_depth)
			joblist.append(BuildJob.new(base_builder, style.base_style.duplicate(), path_data))
	return joblist
	
	
func get_cap_job(path_data: PathData) -> BuildJob:
	if style.cap_style != null:
		var cap_builder = CapStyles.create_builder(style.cap_type)
		if cap_builder != null:
			var cap_style_copy = style.cap_style.duplicate()
			if style.wall_style != null:
				cap_style_copy.wall_style = style.wall_style.duplicate()
			return BuildJob.new(cap_builder, cap_style_copy, path_data)
	return null
	
			
func get_collider_jobs(joblist: Array = []) -> Array:
	var path_data = get_path_data(path_mod.interpolate)
	var cap_job = get_cap_job(path_data)
	if cap_job != null:
		joblist.append(cap_job)
	if path_mod.collider_type != BlockPathMod.ColliderType.CapOnly:
		var wall_builder = WallStyles.create_builder(WallStyles.Type.Bevel_Wall)
		if wall_builder != null:
			var wall_style = WallStyles.create_style(WallStyles.Type.Bevel_Wall)
			wall_style.height = style.base_depth
			if style.wall_type == WallStyles.Type.Bevel_Wall:
				wall_style.height = style.wall_style.height
			elif style.wall_type == WallStyles.Type.Mesh_Wall and wall_style.height == 0:
				wall_style.height = MeshUtils.calc_mesh_height(style.wall_style.mesh, style.wall_style.scale)
			if path_mod.collider_type == BlockPathMod.ColliderType.Ridged:
				path_data = PathUtils.move_path_down(path_data, -path_mod.collider_ridge)
				wall_style.height += path_mod.collider_ridge
			joblist.append(BuildJob.new(wall_builder, wall_style, path_data))
	return joblist
	

func get_path_data(interpolate: int) -> PathData:
	var twists = null if not path_mod.twist else PackedInt32Array(path_twists)
	var path_data = PathUtils.curve_to_path(curve, interpolate, inverted, twists)
	if path_mod.line != 0:
		path_data = PathUtils.path_to_outline(path_data, path_mod.line)
	if path_mod.rounding > 0:
		path_data = PathUtils.round_path(path_data, path_mod.rounding, interpolate)
	if path_mod.line > 0:
		path_data.taper = taper
		path_data.curve = curve.duplicate()
	return path_data
	
	
func apply_all_meshes(group) -> void:
	apply_block_meshes(group)
	apply_collider(group)

	
func apply_block_meshes(group) -> void:
	var mesh = ArrayMesh.new()
	for meshset in group.output:
		if meshset != null:
			MeshUtils.build_meshes(meshset, mesh)
	if mesh_node == null:
		mesh_node = SceneUtils.get_or_create(self, "Mesh", MeshInstance3D)
	mesh_node.transform = Transform3D()
	mesh_node.mesh = mesh
	
	
func apply_collider(group) -> void:
	var mesh = ArrayMesh.new()
	for meshset in group.output:
		if meshset != null:
			MeshUtils.build_meshes(meshset, mesh)
	if collider_body == null:
		collider_body = SceneUtils.get_or_create(self, "Collider", StaticBody3D)
	collider_body.transform = Transform3D()
	collider_shape = SceneUtils.get_or_create(collider_body, "CollisionShape", CollisionShape3D)
	#mesh.regen_normalmaps()
	collider_shape.shape = mesh.create_trimesh_shape()
	collider_shape.transform = Transform3D()
	
