tool
extends EditorPlugin

const GDBPATH = "res://addons/gdblocks"
var selection_handler = get_editor_interface().get_selection()

var reselecting = false
var toolbar: HBoxContainer
var block_menu_button: MenuButton
var block_menu_items = []

class EditorProxy:
	
	var runner = JobRunner.new()
	var last_style: Resource
	var last_path_mod: Resource
	var copied_style: Resource
	var copied_path_mod: Resource
	var selected_block: Block = null
	
	func create_block_style() -> Resource:
		if last_style != null:
			return _get_resource(last_style)
		return BlockStyle.new()
		
	func create_path_mod() -> Resource:
		if last_path_mod != null:
			return _get_resource(last_path_mod)
		return BlockPathMod.new()
		
	func copy_attributes() -> void:
		copied_style = selected_block.style
		copied_path_mod = selected_block.path_mod
		
	func paste_attributes() -> void:
		if copied_style != null:
			selected_block.style = _get_resource(copied_style)
		if copied_path_mod != null:
			selected_block.path_mod = _get_resource(copied_path_mod)
		
	func _get_resource(resource: Resource) -> Resource:
		if resource.resource_local_to_scene:
			return resource.duplicate()
		return resource
		
	
var proxy: EditorProxy = EditorProxy.new()

var menu_items_all = [
	["Add New Block", self, "add_block"],
	["Select All Blocks", self, "select_all_blocks"],
]
var menu_items_block = [
	["Copy Attributes", proxy, "copy_attributes"],
	["Paste Attributes", proxy, "paste_attributes"],
	["Redraw Selected", self, "modify_selected"],
	["Remove Control Points", self, "modify_selected", "remove_control_points"],
	["Recenter Shape", self, "modify_selected", "recenter"]
] + menu_items_all
var menu_items_other = menu_items_all + [
	["Place Objects on Ground", self, "ground_objects"]
]

func _enter_tree() -> void:
	add_custom_type("Block", "Path", preload("Block.gd"), null)
	selection_handler.connect("selection_changed", self, "_on_selection_changed")
	
	toolbar = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
	
	block_menu_button = MenuButton.new()
	block_menu_button.set_text("Blocks")
	block_menu_button.get_popup().connect("id_pressed", self, "_menu_item_selected")
	toolbar.add_child(block_menu_button)
	set_menu_items(menu_items_other)
	
	
func set_menu_items(menu_items: Array) -> void:
	var popup = block_menu_button.get_popup()
	popup.clear()
	block_menu_items = menu_items
	for i in range(menu_items.size()):
		popup.add_item(menu_items[i][0], i)
	
	
func _menu_item_selected(index: int) -> void:
	var mi = block_menu_items[index]
	if mi.size() > 4:
		mi[1].call(mi[2], mi[3], mi[4])
	elif mi.size() > 3:
		mi[1].call(mi[2], mi[3])
	else:
		mi[1].call(mi[2])
	
		
func add_block() -> void:
	var block = Path.new()
	block.name = "Block"
	block.set_script(preload("Block.gd"))
	var parent = (proxy.selected_block as Spatial).get_parent_spatial()
	parent.add_child(block)
	block.set_owner(parent)
	select_block(block)
			
			
func modify_selected(method: String = "", arg = null) -> void:
	var selected_nodes = selection_handler.get_selected_nodes()
	for node in selected_nodes:
		if node is Block:
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
		
	var editor_root = get_editor_interface().get_edited_scene_root()
	if not editor_root:
		proxy.selected_block = null
		return
	var selected_nodes = selection_handler.get_selected_nodes()
	if selected_nodes.size() != 1:
		if proxy.selected_block:
			select_block(null)
	else:
		var selected_node = selected_nodes[0]
		var selected_parent = selected_node
		var block: Block = null
		while selected_parent != editor_root:
			if selected_parent is Block:
				block = selected_parent as Block
				break
			else:
				selected_parent = selected_parent.get_parent()
		if block and proxy.selected_block != selected_node:
			select_block(block)
			
	var block_selected = false
	for node in selected_nodes:
		if node is Block:
			block_selected = true
	
	if block_selected:
		set_menu_items(menu_items_block)
	else:
		set_menu_items(menu_items_other)
				
				
func _on_tree_exiting() -> void:
	print("tree exiting")
	proxy.selected_block = null


func select_block(block: Block) -> void:
	if block != proxy.selected_block:
		if proxy.selected_block:
			copy_block_params(proxy.selected_block)
			proxy.selected_block.emit_signal("edit_end")
		proxy.selected_block = null
		reselecting = false
		
	if block and block is Block and block != proxy.selected_block:
		print("selected block " + block.name)
		proxy.selected_block = block
		call_deferred("connect_block")
		
		
func select_all_blocks(parent: Node = null) -> void:
	if parent == null:
		parent = get_tree().root
		selection_handler.clear()
	if parent is Block:
		selection_handler.add_node(parent)
	for i in parent.get_child_count():
		select_all_blocks(parent.get_child(i))
		
		
func copy_block_params(block: Block) -> void:
	proxy.last_style = block.style
	proxy.last_path_mod = block.path_mod
		
		
func ground_objects() -> void:
	var space_state = get_tree().root.get_world().direct_space_state
	var selected_nodes = selection_handler.get_selected_nodes()
	for node in selected_nodes:
		var spatial = node as Spatial
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
	print("selected block " + proxy.selected_block.name)
	proxy.selected_block.emit_signal("edit_begin", proxy)
	var selected_nodes = selection_handler.get_selected_nodes()
	if selected_nodes.size() != 1 || selected_nodes[0] != proxy.selected_block:
		selection_handler.clear()
		selection_handler.add_node(proxy.selected_block)
	reselecting = false
		

func _exit_tree() -> void:
	selection_handler.disconnect("selection_changed", self, "_on_selection_changed")
	print("GDBlocks disconnected ")
	remove_autoload_singleton("BuildRunner")
