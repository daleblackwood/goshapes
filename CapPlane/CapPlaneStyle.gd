tool
extends CapStyle

export(Material) var material setget set_material
export(float, 0.5, 5.0) var grid_size = 1.0 setget set_grid_size

func set_material(value):
	material = value
	emit_changed()
	
	
func set_grid_size(value):
	grid_size = value
	emit_changed()
