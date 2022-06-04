extends Resource
class_name CapStyle

@export var conform_to_wall: bool = false: set = set_conform_to_wall

var wall_style


func _init():
	pass
	

func set_conform_to_wall(value: bool) -> void:
	conform_to_wall = value
	emit_changed()
