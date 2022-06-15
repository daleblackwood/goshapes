@tool
extends MenuButton
class_name ShaperInspectorHeader

const ID_UNIQUE = 254
const ID_LOAD = 255

var host: Object
var propname: String
var shaper: Shaper
var shaper_types: Array
var is_local = false
var is_root = false

func _init(_host: Object, _propname: String):
	host = _host
	propname = _propname
	get_popup().id_pressed.connect(on_type_select)
	print("init ", host, propname)
	
	
func _enter_tree():
	update_prop()
	

func update_prop() -> void:
	shaper = host.get(propname)
	print("update ", propname, " ", shaper)
	shaper_types = ShaperTypes.get_sibling_types(shaper)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	is_root = host is Goshape
	is_local = false
	var shaper_filename = ResourceUtils.get_local_path(shaper)
	if shaper_filename.length() < 1:
		name = "[LOCAL]"
		is_local = true
		
	var type_name = ResourceUtils.get_type(shaper.get_script())
	text = shaper_filename + " (" + type_name + ")"
	get_popup().clear()
	
	var prefix = "New " if is_root else "To "
	for i in range(shaper_types.size()):
		get_popup().add_item(prefix + ResourceUtils.get_type(shaper_types[i]), i)
	if is_root:
		if not is_local:
			get_popup().add_item("Make Unique...", ID_UNIQUE)
		get_popup().add_item("Load...", ID_LOAD)
	

func on_type_select(index: int) -> void:
	if index == ID_LOAD:
		print("Load")
	elif index == ID_UNIQUE:
		print("Make Unique")
	else:
		print("Selected " + ResourceUtils.get_local_path(shaper_types[index]))
		
		
