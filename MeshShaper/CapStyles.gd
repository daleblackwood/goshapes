@tool
class_name CapStyles

enum Type {
	None,
	Flat_Cap,
	Line_Cap,
	Plane_Cap
}

static func get_name(type_value: int):
	match type_value:
		Type.Flat_Cap: return "CapFlat"
		Type.Line_Cap: return "CapLine"
		Type.Plane_Cap: return "CapPlane"
	return null
	

static func load_class(type_value: int):
	var shaper_name = get_name(type_value)
	var result = load("res://addons/gdblocks/MeshShaper/Shapers/%sShaper.gd" % shaper_name)
	return result
	
	
static func create(type_value: int):
	if type_value == Type.None:
		return null
	var shaper_class = load_class(type_value)
	if shaper_class:
		var result = shaper_class.new()
		return result
	return null
