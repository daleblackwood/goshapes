@tool
extends WallStyle

@export_range(0.0, 100.0, 0.2) var height = 1.0:
	set(value):
		if height != value:
			height = value
			emit_changed()
	
@export_range(0, 10.0, 0.2) var bevel = 0.0:
	set(value):
		if bevel != value:
			bevel = value
			emit_changed()
	
@export_range(0.0, 100.0, 0.2) var taper = 0.0:
	set(value):
		if taper != value:
			taper = value
			emit_changed()
			
@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()
