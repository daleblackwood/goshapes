@tool
extends CapStyle

@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()
