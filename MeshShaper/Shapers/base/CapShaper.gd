@tool
extends MeshShaper
class_name CapShaper

@export var conform_to_wall: bool = false:
	set(value):
		if conform_to_wall != value:
			conform_to_wall = value
			emit_changed()


@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()	
				

var wall_style

