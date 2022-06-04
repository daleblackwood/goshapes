@tool
extends CapStyle

@export var material: Material: set = set_material
@export_range(1, 20, 0.5) var grid_size = 1.0: set = set_grid_size


func set_material(value):
	material = value
	emit_changed()
	
	
func set_grid_size(value):
	grid_size = value
	emit_changed()
