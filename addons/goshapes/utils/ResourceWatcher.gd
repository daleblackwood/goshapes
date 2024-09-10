@tool
class_name ResourceWatcher
## Utilities that allow for monitoring changes on Goshapes resources

var resource: Resource
var callback: Callable

func _init(_callback: Callable, initial_resource: Resource = null):
	callback = _callback
	watch(initial_resource)
	
	
func watch(new_resource: Resource) -> void:
	unwatch()
	resource = new_resource
	if resource != null:
		resource.changed.connect(_on_change)
		
		
func unwatch() -> void:
	if resource != null && resource.changed.is_connected(_on_change):
		resource.changed.disconnect(_on_change)
	resource = null
	
	
func _on_change() -> void:
	if callback != null:
		callback.call()
