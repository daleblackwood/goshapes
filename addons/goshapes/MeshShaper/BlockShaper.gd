@tool
class_name BlockShaper
extends Shaper
## Builds a cap and walls and a floor on the Goshape

var watcher_cap := ResourceWatcher.new(mark_dirty)

## The Shaper used for the building the cap
@export var cap_shaper: CapShaper:
	set(value):
		cap_shaper = value
		watcher_cap.watch(cap_shaper)
		mark_dirty()
		

var watcher_wall := ResourceWatcher.new(mark_dirty)

## The Shaper used for the building the walls
@export var wall_shaper: WallShaper:
	set(value):
		wall_shaper = value
		watcher_wall.watch(wall_shaper)
		mark_dirty()
		

var watcher_bottom := ResourceWatcher.new(mark_dirty)

## The Shaper used for the building the base
@export var bottom_shaper: BottomShaper:
	set(value):
		bottom_shaper = value
		watcher_bottom.watch(bottom_shaper)
		mark_dirty()
		

## Controls the depth of the shape
@export_range(0.0, 20.0, 0.5) var bottom_depth = 0.0:
	set(value):
		bottom_depth = value
		mark_dirty()
		

enum ColliderType { None, CapOnly, Simple, Ridged, Accurate }

## Changes which colliders are generated for the shape
@export var collider_type: ColliderType = ColliderType.Simple:
	set(value):
		collider_type = value
		emit_changed()


## Extrudes a small ridge along the cap used for containing actors
@export_range(0.0, 10.0, 1.0) var collider_ridge: float = 0.0:
	set(value):
		collider_ridge = value
		emit_changed()
		

var is_dirty = false

func _init() -> void:
	if cap_shaper == null:
		cap_shaper = CapFlatShaper.new()
	if wall_shaper == null:
		wall_shaper = WallBevelShaper.new()
	watcher_cap.watch(cap_shaper)
	watcher_wall.watch(wall_shaper)
	watcher_bottom.watch(bottom_shaper)

	
func mark_dirty():
	if is_dirty:
		return
	is_dirty = true
	_update.call_deferred()
	
	
func _update():
	is_dirty = false
	emit_changed()
	

func create_builders() -> Array[ShapeBuilder]:
	var result: Array[ShapeBuilder] = []
	if cap_shaper != null and cap_shaper.enabled:
		result += cap_shaper.create_builders()
	if wall_shaper != null and wall_shaper.enabled:
		result += wall_shaper.create_builders()
	if bottom_shaper != null and bottom_shaper.enabled:
		bottom_shaper.cap_shaper = cap_shaper
		result += bottom_shaper.create_builders()
	return result
	
	
func get_build_jobs(data: GoshapeBuildData) -> Array[GoshapeJob]:
	var local_data = data.duplicate()
	local_data.owner = self
	var result: Array[GoshapeJob] = []
	if cap_shaper != null and cap_shaper.enabled:
		result += cap_shaper.get_build_jobs(local_data)
	if wall_shaper != null and wall_shaper.enabled:
		result += wall_shaper.get_build_jobs(local_data)
	if bottom_shaper != null and bottom_shaper.enabled:
		bottom_shaper.cap_shaper = cap_shaper
		result += bottom_shaper.get_build_jobs(local_data)
	return result
