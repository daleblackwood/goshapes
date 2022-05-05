tool
extends Path
class_name Block

export var inverted = false setget set_inverted
export(float, -1.0, 2.0) var taper = 0.0 setget set_taper
export var recenter = false setget set_recenter
export var cascade_twists = false
export(Array, int) var path_twists setget set_path_twists
export(Resource) var path_mod = BlockPathMod.new() setget set_path_mod
export(String, FILE, "*.tres") var style_file setget set_style_file, get_style_file
export(Resource) var style = BlockStyle.new()  setget set_style

signal edit_begin(edit_proxy)
signal edit_end
signal on_built(output)

var is_dirty = false
var is_dragging = false
var mesh_node: MeshInstance
var collider_body: StaticBody
var collider_shape: CollisionShape
var edit_proxy = null
var is_line: bool setget ,get_is_line
var cap_data: PathData = null

func _enter_tree() -> void:
	connect("edit_begin", self, "_edit_begin")
	connect("edit_end", self, "_edit_end")
	set_display_folded(true)
	
	
func _ready() -> void:
	if ResourceUtils.is_local(curve):
		SceneUtils.switch_signal(self, "curve_changed", "set_dirty", self, null)
		curve = curve.duplicate(true)
	
	
func _exit_tree() -> void:
	disconnect("edit_begin", self, "_edit_begin")
	disconnect("edit_end", self, "_edit_end")
	_edit_end()
		
		
func _edit_begin(edit_proxy) -> void:
	self.edit_proxy = edit_proxy
	set_display_folded(true)
	if not style:
		set_style(edit_proxy.create_block_style())
	if not path_mod:
		set_path_mod(edit_proxy.create_path_mod())
	SceneUtils.switch_signal(self, "curve_changed", "set_dirty", self, self)
	SceneUtils.switch_signal(self, "on_built", "_on_built", self, self)
	
	
func _edit_end() -> void:
	self.edit_proxy = null
	ResourceUtils.switch_signal(self, "_on_style_changed", style, null)
	SceneUtils.switch_signal(self, "curve_changed", "set_dirty", self, null)
	SceneUtils.switch_signal(self, "on_built", "_on_built", self, null)
	

func set_style_file(path: String) -> void:
	var res = load(path)
	set_style(res)
	
	
func get_style_file() -> String:
	if style == null or style.resource_local_to_scene:
		return ""
	return style.resource_path
	
	
func set_style(value: Resource) -> void:
	ResourceUtils.switch_signal(self, "set_dirty", style, value)
	style = value
	set_dirty()
	
	
func set_taper(value: float) -> void:
	taper = value
	set_dirty()
	
	
func set_path_mod(value: Resource) -> void:
	ResourceUtils.switch_signal(self, "set_dirty", path_mod, value)
	path_mod = value
	set_dirty()
	

func set_inverted(value):
	inverted = value
	set_dirty()
	

func set_path_twists(value: Array):
	if value and path_twists and cascade_twists:
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
	set_dirty()
	
	
func set_recenter(value):
	if value:
		var center = PathUtils.get_curve_center(curve)
		PathUtils.move_curve(curve, -center)
		transform.origin += center
		if mesh_node:
			mesh_node.transform = Transform()
		if collider_body:
			collider_body.transform = Transform()
		set_dirty()
	

	
func set_dirty():
	is_dirty = true
	call_deferred("_update")
	
	
func get_is_line():
	return path_mod.line > 0.0
	
	
func _update():
	if not Engine.editor_hint:
		return
	if not get_tree():
		return
	if not edit_proxy:
		return
	if not is_dirty:
		return
	if is_dragging:
		call_deferred("_update")
		return
	build()
	is_dirty = false

	
func build():
	if path_mod.flatten:
		PathUtils.flatten_curve(curve)
		
	if not path_mod.flatten:
		PathUtils.twist_curve(curve)
	
	if not style:
		print("no style")
		return
	
	var runner = edit_proxy.runner
	if runner.is_busy:
		set_dirty()
		return
		
	var use_collider = path_mod.collider_type > 0
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
	
	
func get_build_jobs(joblist: Array = []) -> Array:
	var path_data = get_path_data(path_mod.interpolate)
	var cap_job = get_cap_job(path_data)
	if cap_job != null:
		joblist.append(cap_job)
	if style.wall_style:
		var wall_builder = WallStyles.create_builder(style.wall_type)
		if wall_builder:
			joblist.append(BuildJob.new(wall_builder, style.wall_style.duplicate(), path_data))	
	if style.base_style:
		var base_cap_builder = CapStyles.create_builder(style.base_type)
		if base_cap_builder:
			var base_builder = BaseBuilder.new(base_cap_builder, style.base_depth)
			joblist.append(BuildJob.new(base_builder, style.base_style.duplicate(), path_data))
	return joblist
	
	
func get_cap_job(path_data: PathData) -> BuildJob:
	if style.cap_style:
		var cap_builder = CapStyles.create_builder(style.cap_type)
		if cap_builder:
			var cap_style_copy = style.cap_style.duplicate()
			if style.wall_style:
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
		if wall_builder:
			var wall_style = WallStyles.create_style(WallStyles.Type.Bevel_Wall)
			wall_style.height = style.base_depth
			if style.wall_type == WallStyles.Type.Bevel_Wall:
				wall_style.height = style.wall_style.height
			if path_mod.collider_type == BlockPathMod.ColliderType.Ridged:
				path_data = PathUtils.move_path_down(path_data, -path_mod.collider_ridge)
				wall_style.height += path_mod.collider_ridge
			joblist.append(BuildJob.new(wall_builder, wall_style, path_data))
	return joblist
	

func get_path_data(interpolate: int) -> PathData:
	var twists = null if not path_mod.twist else PoolIntArray(path_twists)
	var path_data = PathUtils.curve_to_path(curve, interpolate, inverted, twists)
	if path_mod.line > 0:
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
		if meshset:
			MeshUtils.build_meshes(meshset, mesh)
	if not mesh_node:
		mesh_node = SceneUtils.get_or_create(self, "Mesh", MeshInstance)
	mesh_node.transform = Transform()
	mesh_node.mesh = mesh
	
	
func apply_collider(group) -> void:
	var mesh = ArrayMesh.new()
	for meshset in group.output:
		if meshset:
			MeshUtils.build_meshes(meshset, mesh)
	if not collider_body:
		collider_body = SceneUtils.get_or_create(self, "Collider", StaticBody)
	collider_body.transform = Transform()
	collider_shape = SceneUtils.get_or_create(collider_body, "CollisionShape", CollisionShape)
	#mesh.regen_normalmaps()
	collider_shape.shape = mesh.create_trimesh_shape()
	collider_shape.transform = Transform()
	
