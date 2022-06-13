@tool
extends Shaper
class_name MeshShaper

@export var build_collider: bool = true:
	set(value):
		if build_collider != value:
			build_collider = value
			emit_changed()
			
@export_flags_3d_physics var collision_layer: int = 1:
	set(value):
		if collision_layer != value:
			collision_layer = value
			emit_changed()
