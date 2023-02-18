@tool
class_name ShaperInspectorHeader
extends MenuButton

const ID_UNIQUE = 200
const ID_LOAD = 201
const ID_SAVE = 202

var controller: ShaperInspectorController
var shaper: Shaper
var shaper_types: Array
var is_local = false
var is_root = false

func _init(_controller: ShaperInspectorController):
	controller = _controller
	flat = false
	get_popup().id_pressed.connect(on_type_select)


func _enter_tree():
	var style_box = StyleBoxFlat.new()
	custom_minimum_size.y = 28
	style_box.content_margin_top = -1
	style_box.content_margin_left = 8
	style_box.bg_color = Color.DARK_SLATE_BLUE
	add_theme_stylebox_override("normal", style_box)
	update_prop()


func update_prop() -> void:
	shaper = controller.shaper
	shaper_types = ShaperTypes.get_sibling_types(shaper)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	is_root = controller.host is Goshape
	is_local = false
	var shaper_path = ResourceUtils.get_local_path(shaper)
	if shaper_path.length() < 1:
		if is_root:
			shaper_path = "(local)"
		is_local = true

	var type_name = ShaperTypes.get_type_name(shaper.get_script())
	type_name = type_name.replace("Shaper", "")
	text = " " + type_name + ": " + shaper_path
	icon = controller.get_editor_icon("GuiOptionArrow")

	get_popup().clear()
	for i in range(shaper_types.size()):
		get_popup().add_item("To " + ShaperTypes.get_type_name(shaper_types[i]), i)
	if is_root:
		if not is_local:
			get_popup().add_item("Make Local...", ID_UNIQUE)
		get_popup().add_item("Load...", ID_LOAD)
		get_popup().add_item("Save...", ID_SAVE)


func on_type_select(index: int) -> void:
	if index == ID_LOAD:
		controller.load_shaper()
	elif index == ID_SAVE:
		controller.save_shaper()
	elif index == ID_UNIQUE:
		controller.make_unique()
	else:
		controller.switch_type(shaper_types[index])


