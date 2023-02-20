@tool
class_name SceneSource
extends Resource
# A base type for fetching scenes


func get_resource(pick: int = 0) -> PackedScene:
	return null


func has_resource() -> bool:
	return false
