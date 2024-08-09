@tool
class_name ScatterItem
extends SceneSource
## A single scene item

## the scene objects (prefabs) to fetch
@export var prefab: PackedScene = null:
	set(value):
		prefab = value
		emit_changed()
		

func get_resource(pick: int = 0) -> PackedScene:
	return prefab
	

func has_resource() -> bool:
	return prefab != null


