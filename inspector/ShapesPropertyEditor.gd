# RandomIntEditor.gd
@tool
extends EditorProperty
class_name ShapesPropertyEditor

signal on_resource_edit(resource: Resource)

var shapers: Array[Resource] = []
var updating = false
var shaper_types: Array
var add_button := MenuButton.new()
var resource_container := VBoxContainer.new()
var resource_editors := []
var editor: EditorInterface

func _init(_editor: EditorInterface):
	editor = _editor
	add_child(add_button)
	add_focusable(add_button)
	add_child(resource_container)
	set_bottom_editor(resource_container)
	add_button.text = "Add Shaper"
	shaper_types = ShaperTypes.get_types()
	for i in range(shaper_types.size()):
		var type = shaper_types[i]
		var type_name = ResourceUtils.get_type(type)
		add_button.get_popup().add_item(type_name, i)
	add_button.get_popup().id_pressed.connect(_on_add_selected)
	refresh_display()
	

func _on_add_selected(id: int) -> void:
	var shaper_type = shaper_types[id]
	var shaper = shaper_type.new() as Shaper
	add_shaper(shaper)
	
	
func add_shaper(shaper: Shaper) -> void:
	print("add_block_shaper")
	shapers.append(shaper)
	emit_changed(get_edited_property(), shapers)
	refresh_display()


func _update_property() -> void:
	var new_value = get_edited_object()[get_edited_property()]
	if new_value == shapers:
		return

	updating = true
	shapers = new_value
	updating = false
	refresh_display()
	
	
func array_match(a: Array, b: Array) -> bool:
	if a == null and b == null:
		return true
	if a == null:
		return false
	if b == null:
		return false
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true
	
	
func refresh_display() -> void:
	while resource_editors.size() > shapers.size():
		resource_editors.back().free()
		resource_editors.remove_at(resource_editors.size() - 1)
	while resource_editors.size() < shapers.size():
		var redit = EditorResourcePicker.new()
		redit.editable = true
		redit.toggle_mode = true
		redit.grow_vertical = true
		resource_container.add_child(redit)
		resource_editors.append(redit)
		redit.resource_selected.connect(on_redit_changed)
	for i in range(shapers.size()):
		var shaper = shapers[i]
		var redit = resource_editors[i] as EditorResourcePicker
		if redit.edited_resource != shaper:
			redit.edited_resource = shaper
			redit.get_child(0).text = ResourceUtils.get_type(shaper.get_script())
			
			
func on_redit_changed(resource: Resource, edit: bool) -> void:
	var index = shapers.find(resource)
	print(resource.resource_path, " ", edit, index)
	if index < 0:
		return
	var redit = resource_editors[index] as EditorResourcePicker
	var inspector = EditorInspector.new()
	var inspector_idx = redit.get_index() + 1
	resource_container.add_child(inspector)
	resource_container.move_child(inspector, inspector_idx)
	#inspector.set_editable_instance(shapers[index], true)
