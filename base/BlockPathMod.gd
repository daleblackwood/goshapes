@tool
extends Resource
class_name BlockPathMod

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
		

enum ColliderType { None, CapOnly, Simple, Ridged, Accurate }
@export var collider_type: ColliderType = ColliderType.Simple:
	set(value):
		collider_type = value
		emit_changed()


@export_range(0.0, 10.0, 1.0) var collider_ridge: float = 0.0:
	set(value):
		collider_ridge = value
		emit_changed()
