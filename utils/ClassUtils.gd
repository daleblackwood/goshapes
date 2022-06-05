@tool
class_name ClassUtils

const BASEPATH = "res://addons/gdblocks/"

static func get_style_class_path(style: String, suffix: String) -> String:
	return BASEPATH + style + "/" + style + suffix
	

static func load_style_class(style: String, suffix: String):
	return load_class(style + "/" + style + suffix)
	
	
static func parse_path(subpath: String, ext: String = "gd") -> String:
	if subpath.begins_with("res://") == false:
		subpath = BASEPATH + subpath
	if subpath.rfind(".") <= subpath.rfind("/"):
		subpath += "." + ext
	return subpath

	
static func load_class(subpath: String) -> Object:
	var path = parse_path(subpath, "gd")
	var result = load(path)
	if not result:
		push_error("no class at " + path)
		return null
	return result


static func create_instance(subpath: String):
	var cls = load_class(subpath)
	if cls:
		return cls.new()
	return null
