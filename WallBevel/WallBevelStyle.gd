tool
extends WallStyle

export(float, -100.0, 100.0, 0.2) var height = 1.0 setget set_height
export(float, 0, 10.0, 0.2) var bevel = 0.0 setget set_bevel
export(float, -10.0, 100.0, 0.2) var taper = 0.0 setget set_taper
export(Material) var material setget set_material

func set_height(value):
	height = value
	emit_changed()

func set_bevel(value):
	bevel = value
	emit_changed()

func set_taper(value):
	taper = value
	emit_changed()
	
func set_material(value):
	material = value
	emit_changed()
