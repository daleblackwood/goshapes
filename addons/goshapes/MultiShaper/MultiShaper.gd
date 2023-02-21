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
	

func get_builder() -> ShapeBuilder:
	return MultiShapeBuilder.new(self)
	

class MultiShapeBuilder extends ShapeBuilder:
	
	var style: MultiShaper
	func _init(_style: MultiShaper):
		style = _style
		
	func build(_host: Node3D, _path: PathData) -> void:
		host = _host
		path = _path
		for shaper in style.shapers:
			if shaper != null and shaper.enabled:
				shaper.get_builder().build(host, path)
