@tool
extends CapStyle

@export var material: Material: set = set_material

func set_material(value):
	material = value
	emit_changed()
