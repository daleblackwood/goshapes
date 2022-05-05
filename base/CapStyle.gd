extends Resource
class_name CapStyle

export(bool) var conform_to_wall = false setget set_conform_to_wall

var wall_style


func _init():
	pass
	

func set_conform_to_wall(value: bool) -> void:
	conform_to_wall = value
	emit_changed()
