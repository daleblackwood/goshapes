@tool
extends CapStyle


@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()		
			
@export var grid_size: float = 1.0:
	set(value):
		if grid_size != value:
			grid_size = value
			emit_changed()
