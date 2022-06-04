@tool
extends WallStyle

@export_range(0.0, 100.0, 0.2) var height = 1.0: set = set_height
@export_range(0, 10.0, 0.2) var bevel = 0.0: set = set_bevel
@export_range(0.0, 100.0, 0.2) var taper = 0.0: set = set_taper
@export var material: Material: set = set_material

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
