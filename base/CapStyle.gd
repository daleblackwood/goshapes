@tool
extends Resource
class_name CapStyle

@export var conform_to_wall: bool = false:
	set(value):
		if conform_to_wall != value:
			conform_to_wall = value
			emit_changed()

var wall_style
