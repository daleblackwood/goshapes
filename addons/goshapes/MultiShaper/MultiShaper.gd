@tool
class_name MultiShaper
extends Shaper
## Builds a cap and walls and a floor on the Goshape

## The Shaper used for the building the cap
@export var shapers: Array[Shaper]:
	set(value):
		shapers = value
		watchers_dirty = true
		mark_dirty()
		

var is_dirty = false
var watchers_dirty = false
var watchers: Array[ResourceWatcher]

func _init() -> void:
	pass

	
func mark_dirty():
	if is_dirty:
		return
	is_dirty = true
	_update.call_deferred()
	
	
func _update():
	is_dirty = false
	watchers_dirty = watchers_dirty or watchers.size() != shapers.size()
	if watchers_dirty:
		watchers_dirty = false
		for watcher in watchers:
			watcher.unwatch()
		watchers.resize(shapers.size())
		for i in range(shapers.size()):
			watchers[i] = ResourceWatcher.new(mark_dirty)
			watchers[i].watch(shapers[i])
	emit_changed()
	

func create_builders() -> Array[ShapeBuilder]:
	var result: Array[ShapeBuilder] = []
	for shaper in shapers:
		if shaper != null and shaper.enabled:
			result += shaper.create_builders()
	return result
	
	
func get_build_jobs(data: GoshapeBuildData) -> Array[GoshapeJob]:
	var local_data = data.duplicate()
	local_data.owner = self
	var result: Array[GoshapeJob] = []
	for shaper in shapers:
		if shaper != null and shaper.enabled:
			result += shaper.get_build_jobs(local_data)
	return result
