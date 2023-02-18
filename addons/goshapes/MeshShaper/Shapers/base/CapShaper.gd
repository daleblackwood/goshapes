@tool
class_name CapShaper
extends MeshShaper
## A base Shaper that all CapShapers extend from

## Causes the shape to more closely conform to the wall geometry (experimental)
@export var conform_to_wall: bool = false:
	set(value):
		if conform_to_wall != value:
			conform_to_wall = value
			emit_changed()


## The material to draw on the cap mesh
@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()	
				

var wall_style

