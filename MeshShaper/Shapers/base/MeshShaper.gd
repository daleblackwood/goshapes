@tool
extends Shaper
class_name MeshShaper

@export var build_collider: bool = true:
	set(value):
		if build_collider != value:
			build_collider = value
			emit_changed()
