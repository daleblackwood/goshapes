@tool
class_name ScatterMesh
extends ScatterSource
## A single scene item

## the scene objects (prefabs) to fetch
@export var mesh: Mesh = null:
	set(value):
		mesh = value
		emit_changed()
		

func instantiate(pick: int = 0) -> Node3D:
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	return instance
	

func has_resource() -> bool:
	return mesh != null
