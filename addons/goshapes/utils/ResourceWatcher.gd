class_name ResourceWatcher

var resource: Resource
var callback: Callable

func _init(_callback: Callable, initial_resource: Resource = null):
	callback = _callback
	watch(initial_resource)
	
	
func watch(new_resource: Resource) -> void:
	unwatch()
	resource = new_resource
	if resource != null:
		resource.changed.connect(callback)
		
		
func unwatch() -> void:
	if resource != null && resource.changed.is_connected(callback):
		resource.changed.disconnect(callback)
	resource = null
