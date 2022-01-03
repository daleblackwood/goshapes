tool
extends CapStyle

export(Material) var material setget set_material

func set_material(value):
	material = value
	emit_changed()
