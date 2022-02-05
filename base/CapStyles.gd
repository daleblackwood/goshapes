class_name CapStyles

enum Type {
	None,
	Flat_Cap,
	Line_Cap,
	Plane_Cap
}


static func get_builder_class(type_value: int):
	return load_style_class(type_value, "Builder")
	
	
static func get_style_class(type_value: int):
	return load_style_class(type_value, "Style")
	

static func load_style_class(type_value: int, suffix: String):
	var name = get_type_name(type_value)
	if not name:
		push_error("no " + suffix + " for type " + String(type_value))
		return null
	return ClassUtils.load_style_class(name, suffix)
	

static func create_builder(type_value: int):
	if type_value == Type.None:
		return null
	var cls = get_builder_class(type_value)
	if cls:
		return cls.new()
	return null
	
	
static func create_style(type_value: int):
	if type_value == Type.None:
		return null
	var cls = get_style_class(type_value)
	if cls:
		var result = cls.new()
		return result
	return null
	

static func get_type_name(type_value: int):
	match type_value:
		Type.Flat_Cap: return "CapFlat"
		Type.Line_Cap: return "CapLine"
		Type.Plane_Cap: return "CapPlane"
	return null
