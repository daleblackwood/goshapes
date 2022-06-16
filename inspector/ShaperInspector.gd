@tool
extends EditorInspectorPlugin
class_name ShaperInspector

var editor: EditorInterface
var change_button: MenuButton
var controllers: Array[ShaperInspectorController] = []
var last_folder: String = ""


func _init(_editor: EditorInterface):
	editor = _editor


func _can_handle(object):
	if object is Goshape:
		for ctrl in controllers:
			if ctrl != null:
				ctrl.queue_free()
		controllers.clear()
		return true
	if object is Shaper:
		return true
	return false
	

func _parse_begin(object):
	if object is Shaper:
		for ctrl in controllers:
			if ctrl == null or not ctrl.shaper == object:
				continue
			add_custom_control(ShaperInspectorHeader.new(ctrl))
			break
		
		
func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if (object is Goshape or object is Shaper) and hint_string == "Resource":
		var value = object.get(name)
		if value is Shaper:
			var ctrl = ShaperInspectorController.new(self, object, name)
			add_custom_control(ctrl)
			controllers.append(ctrl)
	return false
	
	
func file_dialog(title: String, file_mode: int, callback: Callable) -> void:
	var file_picker = FileDialog.new()
	file_picker.add_filter("*.shaper.tres")
	file_picker.file_mode = file_mode
	file_picker.title = title
	file_picker.mode_overrides_title = false
	file_picker.access = FileDialog.ACCESS_RESOURCES
	file_picker.current_path = last_folder
	file_picker.file_selected.connect(func (file: String):
		print("Selected file ", file)
		if file == null:
			return
		var folder_i = file.rfind("/")
		if folder_i > 0:
			last_folder = file.substr(0, folder_i + 1)
		callback.call(file)
	)
	editor.get_base_control().add_child(file_picker)
	file_picker.popup_centered(Vector2i(750, 500))
