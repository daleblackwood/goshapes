@tool
extends Resource
class_name PathOptions

@export var flatten = true: 
	set(value):
		flatten = value
		emit_changed()
		
		
@export var twist = false:
	set(value):
		twist = value
		emit_changed()
		
	
@export_range(0.0, 40.0, 0.5) var line: float = 0.0:
	set(value):
		line = value
		emit_changed()
	
	
@export_range(0.0, 40.0, 0.1) var rounding: float = 0.0: 
	set(value):
		rounding = value
		emit_changed()


@export_range(1, 4, 1) var interpolate: int = 1:
	set(value):
		interpolate = value
		emit_changed()
		
	
@export var points_on_ground = false:
	set(value):
		if points_on_ground != value:
			points_on_ground = value
			emit_changed()
			
			
@export var offset_y = 0.0:
	set(value):
		if offset_y != value:
			offset_y = value
			emit_changed()
			
			
@export_flags_3d_physics var ground_placement_mask = 0:
	set(value):
		if ground_placement_mask != value:
			ground_placement_mask = value
			emit_changed()
