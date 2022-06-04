@tool
extends WallStyle

@export var mesh: Mesh: set = set_mesh, get = get_mesh
@export_range(0.1, 10.0, 0.1) var scale = 1.0: set = set_scale
@export var closed = true: set = set_closed
@export var materials: Array[Material]: set = set_materials

func set_mesh(value):
	mesh = value
	emit_changed()
	
func get_mesh():
	return mesh
	
func set_scale(value):
	scale = value
	emit_changed()
	
func get_scale():
	return scale

func set_closed(value):
	closed = value
	emit_changed()

func set_materials(value):
	materials = value
	emit_changed()
