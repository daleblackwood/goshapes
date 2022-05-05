tool
extends Resource
class_name BlockPathMod

export var flatten = true setget set_flatten
export var twist = false setget set_twist
export(float, 0.0, 40.0, 0.5) var line setget set_line
export(float, 0.0, 40.0, 0.1) var rounding setget set_rounding
export(int, 1, 4, 1) var interpolate = 1 setget set_interpolate
enum ColliderType { None, CapOnly, Simple, Ridged, Accurate }
export(ColliderType) var collider_type setget set_collider_type
export(float, 0.0, 10.0, 1.0) var collider_ridge setget set_collider_ridge


func set_flatten(value):
	flatten = value
	emit_changed()
	
	
func set_twist(value):
	twist = value
	emit_changed()


func set_line(value):
	line = value
	emit_changed()
	

func set_rounding(value):
	rounding = value
	emit_changed()
	

func set_interpolate(value):
	interpolate = value
	emit_changed()
	

func set_collider_type(value):
	collider_type = value
	emit_changed()
	
	
func set_collider_ridge(value):
	collider_ridge = value
	emit_changed()
