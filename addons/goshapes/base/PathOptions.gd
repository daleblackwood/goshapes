@tool
class_name PathOptions
extends Resource
## A Resource that controls the Goshape paths shape

## Causes the path to remain flat
@export var flatten = true: 
	set(value):
		flatten = value
		emit_changed()
		

## Allows the path to be twisted		
@export var twist = false:
	set(value):
		twist = value
		emit_changed()
		

## Makes the path a line of the specified depth, zero to fill
@export_range(0.0, 40.0, 0.5) var line: float = 0.0:
	set(value):
		line = value
		emit_changed()
	

## Rounds the corners of the path
@export_range(0.0, 40.0, 0.1) var rounding: float = 0.0: 
	set(value):
		rounding = value
		emit_changed()


## Increases the resolution of path curve data
@export_range(1, 4, 1) var interpolate: int = 1:
	set(value):
		interpolate = value
		emit_changed()
		
	
## Causes the path to align to underlying ground
@export var points_on_ground = false:
	set(value):
		if points_on_ground != value:
			points_on_ground = value
			emit_changed()
			

## Offsets the path by a certain vertical distance		
@export var offset_y = 0.0:
	set(value):
		if offset_y != value:
			offset_y = value
			emit_changed()
			
		
## If using underlying ground, uses this collision mask (inverted)	
@export_flags_3d_physics var ground_placement_mask = 0:
	set(value):
		if ground_placement_mask != value:
			ground_placement_mask = value
			emit_changed()
