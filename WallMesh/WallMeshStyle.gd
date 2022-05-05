tool
extends WallStyle

export(Mesh) var mesh setget set_mesh, get_mesh
export(float, 0.1, 10.0, 0.1) var scale = 1.0 setget set_scale
export var closed = true setget set_closed
export(Array, Material) var materials setget set_materials

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
