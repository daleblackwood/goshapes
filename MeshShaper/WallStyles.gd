@tool
class_name WallStyles

enum Type {
	None,
	Bevel_Wall,
	Mesh_Wall
}


static func get_name(type_value: int):
	match type_value:
		Type.Bevel_Wall: return "WallBevel"
		Type.Mesh_Wall: return "WallMesh"
	return null
	

static func load_class(type_value: int):
	var shaper_name = get_name(type_value)
	var result = load("res://addons/goshapes/MeshShaper/Shapers/%sShaper.gd" % shaper_name)
	return result
	
	
static func create(type_value: int):
	if type_value == Type.None:
		return null
	var shaper_class = load_class(type_value)
	if shaper_class:
		var result = shaper_class.new()
		return result
	return null
