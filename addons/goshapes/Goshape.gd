@tool
class_name Goshape
extends Path3D
## Goshape is the main node that generates shapes from paths using Shapers

const AXIS_X = 1
const AXIS_Y = 2
const AXIS_Z = 4
const BLOCKING = false


## Invert the direction of the path
@export var inverted = false:
	set(value):
		inverted = value
		mark_dirty()
	
## A toggle that moves the origin of the path to the center
@export var recenter = false:
	set(value):
		if value:
			recenter_points()
	
## The PathOptions Resource that contains the options for this shape
@export var path_options := PathOptions.new():
	set = set_path_options

## The Shaper Resource that configures how to build this Goshape
@export var shaper: Shaper:
	set = set_shaper
	
## Cause path twists to build along the path (useful for loop-de-loops) 
@export var cascade_twists = false:
	set(value):
		cascade_twists = value
		mark_dirty()
		
## An array of twists to apply to each point in the path
@export var path_twists : Array[int]:
	set = set_path_twists
	
var is_editing: bool: get = _get_is_editing

var is_dirty := false
var edit_proxy = null
var cap_data: GoshapePath = null
var watcher_shaper := ResourceWatcher.new(mark_dirty)
var watcher_pathmod := ResourceWatcher.new(mark_dirty)
var axis_match_index = -1
var axis_match_points := PackedInt32Array()
var last_curve_points := PackedVector3Array()
var last_edited_point := -1

func _ready() -> void:
	if curve == null:
		curve = Curve3D.new()
	if not ResourceUtils.is_local(curve):
		curve = curve.duplicate(true)
		

func _enter_tree() -> void:
	set_display_folded(true)
	set_meta("_edit_group_", true)
	
	
func _exit_tree() -> void:
	if _get_is_editing():
		_edit_end()
		
		
func _get_is_editing() -> bool:
	return Engine.is_editor_hint() and self.edit_proxy != null
	
		
func _edit_begin(edit_proxy) -> void:
	if _get_is_editing():
		return
	self.edit_proxy = edit_proxy
	_edit_update()
		
	if not curve_changed.is_connected(on_curve_changed):
		curve_changed.connect(on_curve_changed)
	watcher_shaper.watch(shaper)
	watcher_pathmod.watch(path_options)
	
	
	
func _edit_update() -> void:
	if not Engine.is_editor_hint():
		return
	set_display_folded(true)
	if not is_instance_of(shaper, Shaper):
		set_shaper(edit_proxy.create_shaper())
	if not is_instance_of(path_options, PathOptions):
		set_path_options(edit_proxy.create_path_options())
	if not curve is GoCurve3D:
		curve.set_script(GoCurve3D.new().get_script())
	if not is_instance_of(curve, Curve3D) or curve.get_point_count() < 2:
		_init_curve()
	curve = ResourceUtils.make_local(self, curve)
	shaper = ResourceUtils.make_local(self, shaper)
	path_options = ResourceUtils.make_local(self, path_options)
	last_edited_point = -1
	last_curve_points.resize(curve.point_count)
	for i in curve.point_count:
		last_curve_points.set(i, curve.get_point_position(i))
	
	
func _edit_end() -> void:
	self.edit_proxy = null
	watcher_shaper.unwatch()
	watcher_pathmod.unwatch()
	if curve_changed.is_connected(on_curve_changed):
		curve_changed.disconnect(on_curve_changed)
	
	
func _init_curve() -> void:
	if curve == null:
		curve = GoCurve3D.new()
	curve.clear_points()
	if path_options != null and path_options.line > 0.0:
		var extent = path_options.line * 0.5
		curve.add_point(Vector3(extent, 0, 0))
		curve.add_point(Vector3(-extent, 0, 0))
	else:
		var extent = 4.0
		curve.add_point(Vector3(-extent, 0, extent))
		curve.add_point(Vector3(extent, 0, extent))
		curve.add_point(Vector3(extent, 0, -extent))
		curve.add_point(Vector3(-extent, 0, -extent))
	
	
func set_shaper(value: Shaper) -> void:
	shaper = value
	mark_dirty()
	watcher_shaper.watch(shaper)
	
	
func set_path_options(value: PathOptions) -> void:
	path_options = value
	watcher_pathmod.watch(path_options)
	mark_dirty()
	
		
func recenter_points():
	var center = PathUtils.get_curve_center(curve)
	PathUtils.move_curve(curve, -center)
	transform.origin += center
	mark_dirty()
	
	
func on_curve_changed():
	if not _get_is_editing():
		return
		
	if is_dirty:
		return
	
	# manual curve change detection
	var has_change = false
	var edited_point_changed = false
	if last_curve_points.size() != curve.point_count:
		last_curve_points.resize(curve.point_count)
		has_change = true
	var prev_last_edited_point = last_edited_point
	if last_edited_point > curve.point_count:
		last_edited_point = -1
	if last_curve_points[last_edited_point] != curve.get_point_position(last_edited_point):
		has_change = true
	else:
		for i in curve.point_count:
			if last_curve_points[i] != curve.get_point_position(i):
				last_edited_point = i
				has_change = true
				break
	if prev_last_edited_point != last_edited_point:
		edited_point_changed = true
		
	if not has_change:
		return
		
	is_dirty = true
	curve.updating = true
		
	if edit_proxy.use_y_lock:
		var p = curve.get_point_position(last_edited_point)
		if last_curve_points.size() > last_edited_point and last_curve_points[last_edited_point].y != p.y:
			p.y = last_curve_points[last_edited_point].y
			curve.set_point_position(last_edited_point, p)

	if edit_proxy.use_axis_matching:
		var edited_point := last_edited_point
		var edited_pos := last_curve_points[edited_point]
		if edited_point != axis_match_index:
			axis_match_index = edited_point
			axis_match_points = PackedInt32Array()
			# find matching axis points
			var neighbours = [
				(edited_point + curve.point_count - 1) % curve.point_count,
				(edited_point + 1) % curve.point_count
			]
			for i in neighbours:
				var p = last_curve_points[i]
				var axis_match = 0
				if absf(p.x - edited_pos.x) < 0.5:
					axis_match |= AXIS_X
				if absf(p.y - edited_pos.y) < 0.5:
					axis_match |= AXIS_Y
				if absf(p.z - edited_pos.z) < 0.5:
					axis_match |= AXIS_Z
				if axis_match != 0:
					axis_match_points.append(i)
					axis_match_points.append(axis_match)
		
		# apply matching axis points
		edited_pos = curve.get_point_position(axis_match_index)
		for i in range(0, axis_match_points.size(), 2):
			var index = axis_match_points[i]
			var axis_match = axis_match_points[i + 1]
			var p = curve.get_point_position(index)
			if (axis_match & AXIS_X) != 0:
				p.x = edited_pos.x
			if (axis_match & AXIS_Y) != 0:
				p.y = edited_pos.y
			if (axis_match & AXIS_Z) != 0:
				p.z = edited_pos.z
			curve.set_point_position(index, p)
			
	for i in curve.point_count:
		last_curve_points.set(i, curve.get_point_position(i))
			
	if path_options.flatten:
		PathUtils.flatten_curve(curve)
	if not path_options.flatten:
		PathUtils.twist_curve(curve)
		
	curve.updating = false
	mark_dirty()

	
func mark_dirty() -> void:
	if not _get_is_editing():
		is_dirty = false
		return
	is_dirty = true


func _process(delta: float) -> void:
	if is_dirty:
		_update()
		
	
func _update() -> void:	
	if not _get_is_editing():
		return
	if not get_tree():
		return
	if not edit_proxy:
		return
	if not is_dirty:
		return
	
	var runner = edit_proxy.runner
	if BLOCKING and runner.is_busy:
		mark_dirty()
		return
	
	build()
	
	
func build() -> void:
	if not shaper:
		return	
	
	var runner = edit_proxy.runner
	if BLOCKING and runner.is_busy:
		mark_dirty()
		return
		
	if not shaper:
		return
		
	build_run(runner)
	is_dirty = false
	
	
func _build(runner: GoshapeRunner) -> void:
	build_run(runner, true)
	
	
func build_clear(runner: GoshapeRunner) -> void:	
	runner.cancel(self)
	for child in get_children():
		child.free()
	
	
func build_run(runner: GoshapeRunner, rebuild := false) -> void:
	build_clear(runner)
	var data = GoshapeBuildData.new()
	data.parent = self
	data.path = get_path_data(path_options.interpolate)
	data.rebuild = rebuild
	var jobs = shaper.get_build_jobs(data)
	for job in jobs:
		runner.enqueue(job)
	runner.run()
	
	
func remove_control_points() -> void:
	PathUtils.remove_control_points(curve)
	mark_dirty()
	
	
func bake_path() -> void:
	var path := get_path_data(path_options.interpolate)
	curve = path.to_curve()
	path_options.rounding = 0.0
	mark_dirty()
	
	
func get_path_data(interpolate: int = -1) -> GoshapePath:
	if interpolate < 0:
		interpolate = path_options.interpolate
	var twists := _get_twists()
	var path_data := PathUtils.curve_to_path(curve, interpolate, inverted, twists)
	if path_options.line != 0:
		path_data = PathUtils.path_to_outline(path_data, path_options.line)
	if path_options.rounding > 0:
		path_data = PathUtils.round_path(path_data, path_options.rounding_mode, path_options.rounding, interpolate)
	path_data.curve = curve.duplicate()
	if path_options.ground_placement_mask:
		path_data.placement_mask = path_options.ground_placement_mask
	
	for i in range(path_data.point_count):
		var p := path_data.get_point(i)
		if path_options.points_on_ground:
			var space := get_world_3d().direct_space_state
			var ray := PhysicsRayQueryParameters3D.new()
			ray.from = global_transform * Vector3(p.x, 1000, p.z)
			ray.to = global_transform * Vector3(p.x, -1000, p.z)
			if path_options.ground_placement_mask:
				ray.collision_mask = path_options.ground_placement_mask
			var hit := space.intersect_ray(ray)
			if hit.has("position"):
				p = global_transform.inverse() * hit.position
		if path_options.offset_y:
			p.y += path_options.offset_y
		path_data.points.set(i, p)
	return path_data


func _get_twists() -> PackedInt32Array:
	return PackedInt32Array(path_twists)
	

func set_path_twists(value: Array[int]):
	if value != null and path_twists != null and cascade_twists:
		var prev_twist_count = path_twists.size()
		var new_twist_count = value.size()
		if new_twist_count == prev_twist_count:
			var change_i = -1
			var change_a = 0.0
			for i in range(new_twist_count):
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
