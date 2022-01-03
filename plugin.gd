tool
extends EditorPlugin

const GDBPATH = "res://addons/gdblocks"
var selection_handler = get_editor_interface().get_selection()
var selected_block: Node = null
var reselecting = false

class EditorProxy:
	var runner = JobRunner.new()
	
var proxy = EditorProxy.new()
	

func _enter_tree() -> void:
	add_custom_type("Block", "Path", load(GDBPATH + "/Block.gd"), null)
	selection_handler.connect("selection_changed", self, "_on_selection_changed")
	
	
func _on_selection_changed() -> void:
	if reselecting:
		return
		
	var editor_root = get_editor_interface().get_edited_scene_root()
	if not editor_root:
		selected_block = null
		return
	var selected_nodes = selection_handler.get_selected_nodes()
	if selected_nodes.size() != 1:
		if selected_block:
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
		if block and selected_block != selected_node:
			select_block(block)
				
				
func _on_tree_exiting() -> void:
	print("tree exiting")
	selected_block = null


func select_block(block: Block) -> void:
	if block != selected_block:
		if selected_block:
			selected_block.emit_signal("edit_end")
		selected_block = null
		reselecting = false
		
	if block and block is Block and block != selected_block:
		print("selected block " + block.name)
		selected_block = block
		call_deferred("connect_block")
		
		
func connect_block() -> void:
	print("selected block " + selected_block.name)
	selected_block.emit_signal("edit_begin", proxy)
	var selected_nodes = selection_handler.get_selected_nodes()
	if selected_nodes.size() != 1 || selected_nodes[0] != selected_block:
		selection_handler.clear()
		selection_handler.add_node(selected_block)
	reselecting = false
		

func _exit_tree() -> void:
	selection_handler.disconnect("selection_changed", self, "_on_selection_changed")
	print("GDBlocks disconnected ")
	remove_autoload_singleton("BuildRunner")
