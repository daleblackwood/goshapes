@tool
class_name MeshShaper
extends Shaper
## The base shaper for all shapers

## Toggles whether or not to build a collider
@export var build_collider: bool = true:
	set(value):
		if build_collider != value:
			build_collider = value
			emit_changed()
			

## Sets which physics layers the collider uses
@export_flags_3d_physics var collision_layer: int = 1:
	set(value):
		if collision_layer != value:
			collision_layer = value
			emit_changed()
