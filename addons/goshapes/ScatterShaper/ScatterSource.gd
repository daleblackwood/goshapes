@tool
class_name ScatterSource
extends Resource
# A base type for instantiating scattershape items

@export var scale := 1.0:
	set(value):
		scale = value
		emit_changed()
		

@export var angle := 0.0:
	set(value):
		angle = value
		emit_changed()
		
		
@export var offset := Vector3.ZERO:
	set(value):
		offset = value
		emit_changed()

	
func instantiate(pick: int = 0) -> Node3D:
	return null


func has_resource() -> bool:
	return false
