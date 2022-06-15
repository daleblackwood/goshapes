@tool
extends EditorResourcePicker
class_name ShaperResourcePicker

signal on_shaper_created(shaper: Shaper)

var shaper_types: Array
var menu: PopupMenu


func _enter_tree():
	super._enter_tree()
	shaper_types = ShaperTypes.get_types()
	menu = PopupMenu.new()
	for i in range(shaper_types.size()):
		menu.add_item(ResourceUtils.get_type(shaper_types[i]), i)
	_set_create_options(menu)


func _handle_menu_selected(idx: int):
	var inst = shaper_types[idx].new()
	edited_resource = inst
	on_shaper_created.emit(inst)
