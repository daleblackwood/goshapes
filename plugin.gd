@tool
extends EditorPlugin

const GDBPATH = "res://addons/gdblocks"
var selection_handler = get_editor_interface().get_selection()

var reselecting = false
var toolbar: HBoxContainer
var block_menu_button: MenuButton
var block_menu_items = []

class BlockAttributes:
	
	var style: Resource
	var path_mod: Resource
	
	func copy(block: Block) -> void:
		style = block.style
		path_mod = block.path_mod
		
	func apply(block: Block) -> void:
		block.style = style
		block.path_mod = path_mod
		
	func apply_style(block: Block) -> void:
		block.style = style
		
	func apply_path_mod(block: Block) -> void:
		block.path_mod = path_mod
		
	

class EditorProxy:
	
	var runner = JobRunner.new()
	var attributes_last := BlockAttributes.new()
	var attributes_copied := BlockAttributes.new()
	var selected_block: Block = null
	var last_selected: Block = null
	
	func set_selected(block: Block) -> void:
		if block == selected_block:
			return
		if selected_block != null:
			attributes_last.copy(selected_block)
		selected_block = block
		if block != null:
			last_selected = block
	
	func create_block_style() -> Resource:
		if attributes_last.style != null:
			return _get_resource(attributes_last.style)
		return BlockStyle.new()
		
	func create_path_mod() -> Resource:
		if attributes_last.path_mod != null:
			return _get_resource(attributes_last.path_mod)
		return BlockPathMod.new()
		
	func copy_attributes() -> void:
		attributes_copied.copy(last_selected)
		
	func paste_attributes() -> void:
		attributes_copied.apply(selected_block)
		
	func paste_style() -> void:
		attributes_copied.apply_style(selected_block)
		
	func paste_path_mod() -> void:
		attributes_copied.apply_path_mod(selected_block)
		
	func clear_style() -> void:
		selected_block.style = BlockStyle.new()
		selected_block._build(runner)
		
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
	["Redraw Selected", self, "modify_selected"],
	["Copy Attributes", proxy, "copy_attributes"],
	["Paste Attributes", proxy, "paste_attributes"],
	["Paste Style", proxy, "paste_style"],
	["Paste Path Mods", proxy, "paste_path_mod"],
	["Reset Style", proxy, "reset_style"],
	["Remove Control Points", self, "modify_selected", "remove_control_points"],
	["Recenter Shape", self, "modify_selected", "recenter"]
] + menu_items_all
var menu_items_other = menu_items_all + [
	["Place Objects on Ground", self, "ground_objects"]
]

func _enter_tree() -> void:
	add_custom_type("Block", "Path", preload("Block.gd"), null)
	selection_handler.connect("selection_changed", Callable(self, "_on_selection_changed"))
	
	toolbar = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
	
	block_menu_button = MenuButton.new()
	block_menu_button.set_text("Blocks")
	block_menu_button.get_popup().connect("id_pressed", Callable(self, "_menu_item_selected"))
	toolbar.add_child(block_menu_button)
	set_menu_items(menu_items_other)
	
	print("Blocks addon inited.")
	
	
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
	var parent = proxy.selected_block as Node3D
	if parent == null:
		var selected_nodes = selection_handler.get_selected_nodes()
		if selected_nodes.size() > 0:
			parent = selected_nodes.front() as Node3D
	if parent == null:
		parent = get_editor_interface().get_edited_scene_root()
	if parent is Block:
		parent = parent.get_parent_node_3d()
	var block = Path3D.new()
	block.name = "Block"
	block.set_script(preload("Block.gd"))
	parent.add_child(block)
	block.set_owner(parent)
	if proxy.last_selected != null and parent == proxy.last_selected.get_parent_spatial():
		block.global_transform.origin = proxy.last_selected.global_transform.origin + Vector3(5, 0, 0)
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
		select_block(null)
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
	proxy.set_selected(null)


func select_block(block: Block) -> void:
	if block != proxy.selected_block:
		if proxy.selected_block != null:
			proxy.selected_block._edit_end()
		proxy.set_selected(null)
		reselecting = false
		
	if block and block is Block and block != proxy.selected_block:
		proxy.set_selected(block)
		call_deferred("connect_block")
		
		
func select_all_blocks(parent: Node = null) -> void:
	if parent == null:
		parent = get_tree().root
		selection_handler.clear()
	if parent is Block:
		selection_handler.add_node(parent)
	for i in range(parent.get_child_count()):
		select_all_blocks(parent.get_child(i))
		
		
func copy_block_params(block: Block) -> void:
	proxy.last_style = block.style
	proxy.last_path_mod = block.path_mod
		
		
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
	print("selected block %s" % proxy.selected_block.name)
	proxy.selected_block._edit_begin(proxy)
	var selected_nodes = selection_handler.get_selected_nodes()
	if selected_nodes.size() != 1 || selected_nodes[0] != proxy.selected_block:
		selection_handler.clear()
		selection_handler.add_node(proxy.selected_block)
	reselecting = false
		

func _exit_tree() -> void:
	selection_handler.disconnect("selection_changed", Callable(self, "_on_selection_changed"))
	print("GDBlocks disconnected ")
	remove_autoload_singleton("BuildRunner")
