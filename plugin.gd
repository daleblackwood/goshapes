tool
extends EditorPlugin

const GDBPATH = "res://addons/gdblocks"
var selection_handler = get_editor_interface().get_selection()

var reselecting = false
var toolbar: HBoxContainer

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

var menu_items = [
	["Add New Block", self, "add_block"],
	["Copy Attributes", proxy, "copy_attributes"],
	["Paste Attributes", proxy, "paste_attributes"],
	["Redraw Selected", self, "call_selected", "build"],
	["Remove Control Points", self, "call_selected", "remove_control_points"],
	["Recenter Shape", self, "call_selected", "recenter"]
]

func _enter_tree() -> void:
	add_custom_type("Block", "Path", preload("Block.gd"), null)
	selection_handler.connect("selection_changed", self, "_on_selection_changed")
	
	toolbar = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
	toolbar.hide()
	
	var menu := MenuButton.new()
	menu.set_text("Shapes")
	for i in range(menu_items.size()):
		menu.get_popup().add_item(menu_items[i][0], i)
	menu.get_popup().connect("id_pressed", self, "_menu_item_selected")
	toolbar.add_child(menu)
	
	
func _menu_item_selected(index: int) -> void:
	var mi = menu_items[index]
	if mi.size() > 3:
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
			
			
func call_selected(method: String, arg = null) -> void:
	var selected_nodes = selection_handler.get_selected_nodes()
	for node in selected_nodes:
		if node is Block:
			var is_editing = node.is_editing
			if not is_editing:
				node._edit_begin(proxy)
			if arg != null:
				node.call(method, arg)
			else:
				node.call(method)
			if not is_editing:
				node._edit_end()
	
	
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
		toolbar.show()
	else:
		toolbar.hide()
				
				
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
		
		
func copy_block_params(block: Block) -> void:
	proxy.last_style = block.style
	proxy.last_path_mod = block.path_mod
		
		
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
