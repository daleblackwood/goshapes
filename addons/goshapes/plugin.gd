@tool
extends EditorPlugin

const GDBPATH = "res://addons/gdblocks"
var editor = get_editor_interface()
var editor_util: EditorUtil
var selection_handler = editor.get_selection()

var block_select = true
var reselecting = false
var toolbar: HBoxContainer
var block_menu_button: MenuButton
var block_menu_items = []
var tools_default: Array[MenuButton] = []
var tools_block: Array[MenuButton] = []
var create_i: int = 0

class BlockAttributes:
	
	var shaper: Resource
	var path_options: Resource
	
	func get_copy(r: Resource) -> Resource:
		if ResourceUtils.is_local(r):
			return r.duplicate(true)
		else:
			return r
	
	func copy(block: Goshape) -> void:
		shaper = get_copy(block.shaper)
		path_options = get_copy(block.path_options)
		
	func apply(block: Goshape) -> void:
		block.shaper = shaper
		block.path_options = path_options
		
	func apply_shaper(block: Goshape) -> void:
		block.shaper = shaper
		
	func apply_path_options(block: Goshape) -> void:
		block.path_options = path_options
	

class EditorProxy:
	
	var runner = JobRunner.new()
	var attributes_last := BlockAttributes.new()
	var attributes_copied := BlockAttributes.new()
	var selected_block: Goshape = null
	var last_selected: Goshape = null
	var mouse_down = false
	var mouse_pos = Vector2.ZERO
	var scene_mouse_pos = Vector3.ZERO
	
	func set_selected(block: Goshape) -> void:
		if block == selected_block:
			return
		if selected_block != null:
			attributes_last.copy(selected_block)
		selected_block = block
		if block != null:
			last_selected = block
	
	func create_shaper() -> Resource:
		if attributes_last.shaper is Shaper:
			return _get_resource(attributes_last.shaper)
		return BlockShaper.new()
		
	func create_path_options() -> Resource:
		if attributes_last.path_options is PathOptions:
			return _get_resource(attributes_last.path_options)
		return PathOptions.new()
		
	func copy_attributes() -> void:
		if not last_selected:
			return
		print("Copy attributes from %s" % last_selected.name)
		attributes_copied.copy(last_selected)
		
	func paste_attributes() -> void:
		attributes_copied.apply(selected_block)
		
	func paste_shaper() -> void:
		attributes_copied.apply_shaper(selected_block)
		
	func paste_path_options() -> void:
		attributes_copied.apply_path_options(selected_block)
		
	func clear_shaper() -> void:
		selected_block.shaper = MeshShaper.new()
		selected_block._build(runner)
		
	func _get_resource(resource: Resource) -> Resource:
		if ResourceUtils.is_local(resource):
			return resource.duplicate()
		return resource
		
	
var proxy: EditorProxy = EditorProxy.new()

enum MenuSet { NORMAL, BLOCK, DEFAULT }

func get_menuset(menuset: MenuSet):
	var result = [
		["Add New BlockShape", self, "add_block"],
		["Add New ScatterShape", self, "add_scatter"],
		["Select All Blocks", self, "select_all_blocks"],
		["%s Block Select" % ("[x]" if block_select else "[-]"), self, "toggle_block_select"]
	]
	if menuset == MenuSet.BLOCK:
		result = [
			["Redraw Selected", self, "modify_selected"],
			["Copy Attributes", proxy, "copy_attributes"],
			["Paste Attributes", proxy, "paste_attributes"],
			["Paste Shaper", proxy, "paste_shaper"],
			["Paste Path Mods", proxy, "paste_path_options"],
			["Reset Shaper", proxy, "reset_shaper"],
			["Remove Control Points", self, "modify_selected", "remove_control_points"],
			["Recenter Shape", self, "modify_selected", "recenter_points"],
			["Add New Similar", self, "add_block_similar"]
		] + result
	if menuset != MenuSet.DEFAULT:
		result += [
			["Place Objects on Ground", self, "ground_objects"]
		]
	return result
	

func _enter_tree() -> void:
	editor_util = EditorUtil.new(editor)
	
	add_custom_type("Goshape", "Path3D", preload("Goshape.gd"), null)
	selection_handler.selection_changed.connect(_on_selection_changed)
	
	toolbar = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
	
	block_menu_button = MenuButton.new()
	block_menu_button.set_text("Goshape")
	block_menu_button.get_popup().id_pressed.connect(_menu_item_selected)
	toolbar.add_child(block_menu_button)
	
	tools_default = []
	tools_block = [
		editor_util.toolbar_button("Add Shape", "New", add_block_similar),
		editor_util.toolbar_button("Copy Attributes", "ActionCopy", proxy.copy_attributes),
		editor_util.toolbar_button("Paste Attributes", "ActionPaste", proxy.paste_attributes),
	]
	
	set_menu_items(get_menuset(MenuSet.DEFAULT), tools_default)
	
	print("Goshapes addon intialized.")
	
	
func set_menu_items(menu_items: Array, tools: Array[MenuButton] = []) -> void:
	var popup = block_menu_button.get_popup()
	popup.clear()
	block_menu_items = menu_items
	for i in range(menu_items.size()):
		popup.add_item(menu_items[i][0], i)
	if toolbar.get_child_count() > 1:
		for i in range(1, toolbar.get_child_count() - 1, 1):
			var child = toolbar.get_child(i)
			if not child in tools:
				toolbar.remove_child(child)
	for item in tools:
		if item.get_parent() != toolbar:
			toolbar.add_child(item)
	
	
func _menu_item_selected(index: int) -> void:
	var mi = block_menu_items[index]
	if mi.size() > 4:
		mi[1].call(mi[2], mi[3], mi[4])
	elif mi.size() > 3:
		mi[1].call(mi[2], mi[3])
	else:
		mi[1].call(mi[2])
	
	
func toggle_block_select() -> void:
	block_select = not block_select
	_on_selection_changed()
	
		
func add_blank() -> Goshape:
	var parent = proxy.selected_block as Node3D
	if parent == null:
		var selected_nodes = selection_handler.get_selected_nodes()
		if selected_nodes.size() > 0:
			parent = selected_nodes.front() as Node3D
	if parent == null:
		parent = editor.get_edited_scene_root()
	if parent is Goshape:
		parent = parent.get_parent_node_3d()
	var result = Path3D.new()
	create_i += 1
	result.name = StringName("Shape%d" % create_i)
	result.set_script(preload("Goshape.gd"))
	parent.add_child(result)
	result.set_owner(parent)
	if proxy.last_selected != null and parent == proxy.last_selected.get_parent():
		result.global_transform.origin = proxy.last_selected.global_transform.origin + Vector3(5, 0, 0)
	select_block(result)
	return result
	
	
func add_block() -> void:
	var shape = add_blank()
	shape.name = StringName("BlockShape%d" % shape.get_parent().get_child_count())
	shape.set_shaper(BlockShaper.new())
	
	
func add_block_similar() -> void:
	proxy.copy_attributes()
	var name = ResourceUtils.inc_name_number(proxy.last_selected.name)
	var shape = add_blank()
	shape.name = StringName(name)
	proxy.set_selected(shape)
	proxy.paste_attributes()
	
	
func add_scatter() -> void:
	var shape = add_blank()
	shape.name = StringName("ScatterShape%d" % shape.get_parent().get_child_count())
	shape.set_shaper(ScatterShaper.new())

# returns a sort order for the shape, used to determine the order of modifications
func get_shape_sort_order(shape: Goshape) -> int:
	if shape.shaper is BottomShaper:
		return 1
	if shape.shaper is BlockShaper:
		return 2
	if shape.shaper is CapShaper and not shape.shaper is CapLineShaper:
		return 3
	if shape.shaper is CapLineShaper:
		return 4
	if shape.shaper is WallShaper:
		return 5
	if shape.shaper is ScatterShaper:
		return 6
	# multishapers probably needs to be handles separately 
	return 99

# sorts a list of Goshapes by their type
# used when modifications needs to be applied in a specific order 
func sort_on_type(a: Goshape, b: Goshape) -> bool:
	var a_order := get_shape_sort_order(a)
	var b_order := get_shape_sort_order(b)
	return a_order < b_order

func modify_selected(method: String = "", arg = null) -> void:
	var selected_nodes = selection_handler.get_selected_nodes()
	
	var nodes_to_modify: Array[Goshape] = []
	for node in selected_nodes:
		if node is Goshape:
			nodes_to_modify.push_back(node as Goshape)

	nodes_to_modify.sort_custom(Callable(self, "sort_on_type"))
	for node in nodes_to_modify:
		var was_editing = node.is_editing
		if was_editing:
			node._edit_end()
		if method != "":
			if arg != null:
				node.call(method, arg)
			else:
				node.call(method)
		node._build(proxy.runner)
		if was_editing:
			node._edit_begin(proxy)
	
	
func _on_selection_changed() -> void:
	if reselecting:
		return
		
	var editor_root = editor.get_edited_scene_root()
	if not editor_root:
		select_block(null)
		return
	var selected_nodes = selection_handler.get_selected_nodes()
	if selected_nodes.size() != 1:
		if proxy.selected_block:
			select_block(null)
	else:
		var selected_node = selected_nodes[0]
		var selected_parent = selected_node
		var block: Goshape = null
		while selected_parent != editor_root:
			if selected_parent is Goshape:
				block = selected_parent as Goshape
				break
			else:
				if not block_select:
					break
				selected_parent = selected_parent.get_parent()
		if block and proxy.selected_block != selected_node:
			select_block(block)
			
	var block_selected = false
	for node in selected_nodes:
		if node is Goshape:
			block_selected = true
	
	if block_selected:
		set_menu_items(get_menuset(MenuSet.BLOCK), tools_block)
	else:
		set_menu_items(get_menuset(MenuSet.DEFAULT), tools_default)
				
				
func _on_tree_exiting() -> void:
	print("Goshapes disabled")
	proxy.set_selected(null)


func select_block(block: Goshape) -> void:
	if block != proxy.selected_block:
		if proxy.selected_block != null:
			proxy.selected_block._edit_end()
		proxy.set_selected(null)
		reselecting = false
		
	if block and block is Goshape and block != proxy.selected_block:
		proxy.set_selected(block)
		connect_block.call_deferred()
		
		
func select_all_blocks(parent: Node = null) -> void:
	if parent == null:
		parent = get_tree().root
		selection_handler.clear()
	if parent is Goshape:
		selection_handler.add_node(parent)
	for i in range(parent.get_child_count()):
		select_all_blocks(parent.get_child(i))
		
		
func copy_block_params(block: Goshape) -> void:
	proxy.last_shaper = block.shaper
	proxy.last_path_options = block.path_options
		
		
func ground_objects() -> void:
	var space_state = get_tree().root.get_world().direct_space_state
	var selected_nodes = selection_handler.get_selected_nodes()
	for node in selected_nodes:
		var spatial = node as Node3D
		if spatial == null:
			continue
		var from = spatial.global_transform.origin
		from.y = 1000.0
		var to = from
		to.y = -1000.0
		var result = space_state.intersect_ray(from, to, [spatial])
		if result.has("position"):
			spatial.global_transform.origin = result.position
		
		
func connect_block() -> void:
	proxy.selected_block._edit_begin(proxy)
	var selected_nodes = selection_handler.get_selected_nodes()
	if selected_nodes.size() != 1 || selected_nodes[0] != proxy.selected_block:
		selection_handler.clear()
		selection_handler.add_node(proxy.selected_block)
	reselecting = false
	
	
func _input(event):
	if event is InputEventMouseButton:
		proxy.mouse_down = event.pressed
	if event is InputEventMouse:
		proxy.mouse_pos = event.position
		

func _exit_tree() -> void:
	selection_handler.selection_changed.disconnect(_on_selection_changed)
