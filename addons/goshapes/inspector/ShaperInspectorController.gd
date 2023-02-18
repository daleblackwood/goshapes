@tool
class_name ShaperInspectorController
extends Control
	
var editor: EditorInterface
var host: Object
var propname: String
var shaper: Shaper:
	get:
		return null if host == null else host.get(propname)


func _init(_editor: EditorInterface, _host: Object, _propname: String):
	editor = _editor
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
	print("load")
	file_dialog(
		"Select a shaper...", 
		FileDialog.FILE_MODE_OPEN_FILE, 
		func(x):
			set_shaper(load(x))
	)
	
	
func save_shaper() -> void:
	print("save")
	file_dialog(
		"Save shaper to file...", 
		FileDialog.FILE_MODE_SAVE_FILE, 
		func(x):
			ResourceSaver.save(shaper, x)
			set_shaper(shaper)
	)
	
	
func make_unique() -> void:
	print("make_unqiue")
	var dupe = shaper.duplicate(true)
	set_shaper(dupe)
	
	
func switch_type(type: Object) -> void:
	print("switch type ", type)
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
	var icon = editor.get_base_control().get_theme_icon(icon_name, "EditorIcons")
	return icon

	
func file_dialog(title: String, file_mode: int, callback: Callable) -> void:
	var file_picker = FileDialog.new()
	file_picker.add_filter("*.shaper.tres")
	file_picker.file_mode = file_mode
	file_picker.title = title
	file_picker.mode_overrides_title = false
	file_picker.access = FileDialog.ACCESS_RESOURCES
	var current_path = ""
	if editor.has_meta("last_resource_folder"):
		current_path = editor.get_meta("last_resource_folder")
	file_picker.current_path = current_path
	file_picker.file_selected.connect(func (file: String):
		print("Selected file ", file)
		if file == null:
			return
		var folder_i = file.rfind("/")
		if folder_i > 0:
			editor.set_meta("last_resource_folder", file.substr(0, folder_i + 1))	
		callback.call(file)
	)
	editor.get_base_control().add_child(file_picker)
	file_picker.popup_centered(Vector2i(750, 500))

