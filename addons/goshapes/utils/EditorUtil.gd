@tool
class_name EditorUtil

var editor: EditorInterface:
	get:
		return editor

var base_control: Control:
	get:
		return editor.get_base_control()

var last_resource_folder: String = ""


func _init(_editor: EditorInterface):
	editor = _editor
	

func get_icon(icon_name: String) -> Texture2D:
	return base_control.get_theme_icon(icon_name, "EditorIcons")


func file_dialog(title: String, file_mode: int, callback: Callable) -> void:
	var file_picker = FileDialog.new()
	file_picker.add_filter("*.shaper.tres")
	file_picker.file_mode = file_mode
	file_picker.title = title
	file_picker.mode_overrides_title = false
	file_picker.access = FileDialog.ACCESS_RESOURCES
	var current_path = last_resource_folder
	file_picker.current_path = current_path
	file_picker.file_selected.connect(func (file: String):
		if file == null:
			return
		var folder_i = file.rfind("/")
		if folder_i > 0:
			last_resource_folder = file.substr(0, folder_i + 1)
		callback.call(file)
	)
	base_control.add_child(file_picker)
	file_picker.popup_centered(Vector2i(750, 500))
	
	
func toolbar_button(text: String, icon: String, callable: Callable, parent: Control = null) -> MenuButton:
	var button := MenuButton.new()
	button.tooltip_text = text
	button.icon = get_icon(icon)
	button.pressed.connect(callable)
	if parent:
		parent.add_child(button)
	return button
