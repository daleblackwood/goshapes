@tool
class_name ShaperInspectorController
extends Control
	
var editor_util: EditorUtil
var host: Object
var propname: String
var shaper: Shaper:
	get:
		return null if host == null else host.get(propname)


func _init(_editor_util: EditorUtil, _host: Object, _propname: String):
	editor_util = _editor_util
	host = _host
	propname = _propname
	_update_picker.call_deferred()
	
	
func _update_picker() -> void:
	if not visible:
		return
	var index = get_index()
	var shaper_types = ShaperTypes.get_sibling_types(shaper)
	var picker_types_string = ShaperTypes.get_types_string(shaper_types)
	var default_control = get_parent().get_child(index + 1)
	for child in default_control.get_children():
		if child is EditorResourcePicker:
			child.base_type = picker_types_string
			child.get_child(child.get_child_count() - 1).visible = false
			break
	visible = false
	
	
func load_shaper() -> void:
	editor_util.file_dialog(
		"Select a shaper...", 
		FileDialog.FILE_MODE_OPEN_FILE, 
		func(x):
			set_shaper(load(x))
	)
	
	
func save_shaper() -> void:
	editor_util.file_dialog(
		"Save shaper to file...", 
		FileDialog.FILE_MODE_SAVE_FILE, 
		func(x):
			ResourceSaver.save(shaper, x)
			set_shaper(shaper)
	)
	
	
func make_unique() -> void:
	var dupe = shaper.duplicate(true)
	set_shaper(dupe)
	
	
func switch_type(type: Object) -> void:
	var new_shaper = type.new()
	if shaper != null:
		ResourceUtils.copy_props(shaper, new_shaper)
	set_shaper(new_shaper)
	
	
func set_shaper(new_shaper: Shaper) -> void:
	if new_shaper != null:
		if ResourceUtils.is_local(new_shaper):
			new_shaper.resource_name = ShaperTypes.get_type_name(new_shaper)
		host.set(propname, new_shaper)
		
		
func get_editor_icon(icon_name: String) -> Texture2D:
	return editor_util.get_icon(icon_name)

	


