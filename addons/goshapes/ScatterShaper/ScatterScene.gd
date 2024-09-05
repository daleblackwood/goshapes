@tool
class_name ScatterScene
extends ScatterSource
## A single scene item

## the scene objects (prefabs) to fetch
@export var resource: PackedScene = null:
	set(value):
		resource = value
		emit_changed()
		

func instantiate(pick: int = 0) -> Node3D:
	return resource.instantiate()
	

func has_resource() -> bool:
	return resource != null
