@tool
extends EditorPlugin

const GDBPATH = "res://addons/gdblocks"
var editor = get_editor_interface()
var editor_util: GoshapeEditorUtil
var selection_handler = editor.get_selection()

var reselecting = false
var toolbar: HBoxContainer
var toolbar_menu_button: MenuButton
var tools_default: Array[MenuButton] = []
var tools_block: Array[MenuButton] = []
var create_i: int = 0
var toolbar_menu

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
		block._edit_update()
		
	func apply_shaper(block: Goshape) -> void:
		block.shaper = shaper
		block._edit_update()
		
	func apply_path_options(block: Goshape) -> void:
		block.path_options = path_options
		block._edit_update()
	

class EditorProxy:
	
	var runner := GoshapeRunner.new()
	var attributes_last := BlockAttributes.new()
	var attributes_copied := BlockAttributes.new()
	var selected_block: Goshape = null
	var last_selected: Goshape = null
	var mouse_down := false
	var mouse_pos := Vector2.ZERO
	var scene_mouse_pos := Vector3.ZERO
	var use_shape_select := true
	var use_axis_matching := false
	var use_y_lock := false
	
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
		
	func set_shape_select(on: bool) -> void:
		use_shape_select = on
		
	func set_axis_matching(on: bool) -> void:
		use_axis_matching = on
		
	func set_y_lock(on: bool) -> void:
		use_y_lock = on
		
	
var proxy := EditorProxy.new()

enum MenuSet { NORMAL, BLOCK, DEFAULT }

func _enter_tree() -> void:
	editor_util = GoshapeEditorUtil.new(editor)
	
	add_custom_type("Goshape", "Path3D", preload("Goshape.gd"), null)
	selection_handler.selection_changed.connect(_on_selection_changed)
	
	toolbar = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
	
	toolbar_menu_button = MenuButton.new()
	toolbar_menu_button.set_text("Goshape")
	toolbar.add_child(toolbar_menu_button)
	
	tools_default = []
	tools_block = [
		editor_util.toolbar_button("Add Shape", "New", add_block_similar),
		editor_util.toolbar_button("Copy Attributes", "ActionCopy", proxy.copy_attributes),
		editor_util.toolbar_button("Paste Attributes", "ActionPaste", proxy.paste_attributes),
	]
	
	set_menu(MenuSet.DEFAULT, tools_default)
	print("Goshapes addon intialized.")
			
			
func set_menu(menuset: MenuSet, tools: Array[MenuButton] = []) -> void:
	var popup := toolbar_menu_button.get_popup()
	var menu := GoshapeMenus.GSMenu.new()
	var create_menu := GoshapeMenus.GSMenu.new()
	create_menu.add_items([
		GoshapeMenus.GSButton.new("Create Blockshape", add_block),
		GoshapeMenus.GSButton.new("Create ScatterShape", add_scatter),
		GoshapeMenus.GSButton.new("Create MultiShaper", add_multishaper)
	])
	if menuset == MenuSet.BLOCK:
		create_menu.add_item(GoshapeMenus.GSButton.new("Create Similar", add_block_similar), 0)
	menu.add_item(GoshapeMenus.GMPopup.new("Create", create_menu))
	
	if menuset == MenuSet.BLOCK:
		var block_menu := GoshapeMenus.GSMenu.new()
		block_menu.add_items([
			GoshapeMenus.GSButton.new("Copy Attributes", proxy.copy_attributes),
			GoshapeMenus.GSButton.new("Paste Attributes", proxy.paste_attributes),
			GoshapeMenus.GSButton.new("Paste Shaper", proxy.paste_shaper),
			GoshapeMenus.GSButton.new("Paste Path Mods", proxy.paste_path_options),
			GoshapeMenus.GSButton.new("Remove Control Points", modify_selected, "remove_control_points"),
			GoshapeMenus.GSButton.new("Recenter Shape", modify_selected, "recenter_points"),
			GoshapeMenus.GSButton.new("Place on Ground", ground_objects)
		])
		menu.add_item(GoshapeMenus.GMPopup.new("Shape", block_menu))
		menu.add_item(GoshapeMenus.GSButton.new("Redraw Selected", modify_selected))
	
	menu.add_items([
		GoshapeMenus.GSButton.new("Select All Shapes", select_all_blocks),
	])
	
	menu.add_items([
		GoshapeMenus.GSToggle.new("Shape Selection", proxy, "use_shape_select"),
		GoshapeMenus.GSToggle.new("Axis Matching", proxy, "use_axis_matching"),
		GoshapeMenus.GSToggle.new("Y-Axis Locking", proxy, "use_y_lock")
	])
		
	menu.populate(popup)
	toolbar_menu = menu
	
	# reset tools
	if toolbar.get_child_count() > 1:
		for i in range(1, toolbar.get_child_count() - 1, 1):
			var child = toolbar.get_child(i)
			if not child in tools:
				toolbar.remove_child(child)
	for item in tools:
		if item.get_parent() != toolbar:
			toolbar.add_child(item)


func create_blank() -> Goshape:
	var parent = proxy.selected_block as Node3D
	if parent == null:
		var selected_nodes = selection_handler.get_selected_nodes()
		if selected_nodes.size() > 0:
			parent = selected_nodes.front() as Node3D
	if parent == null:
		parent = editor.get_edited_scene_root()
	if parent is Goshape:
		parent = parent.get_parent_node_3d()
	var result = Goshape.new()
	create_i += 1
	result.name = StringName("Shape%d" % create_i)
	parent.add_child(result)
	result.set_owner(parent)
	if proxy.last_selected != null and parent == proxy.last_selected.get_parent():
		result.global_transform.origin = proxy.last_selected.global_transform.origin + Vector3(5, 0, 0)
	result._init_curve()
	return result
	
		
func add_blank() -> Goshape:
	var shape := create_blank()
	return complete_new_shape(shape)
	
	
func add_block() -> Goshape:
	var shape := create_blank()
	shape.name = StringName("BlockShape%d" % shape.get_parent().get_child_count())
	shape.set_shaper(BlockShaper.new())
	return complete_new_shape(shape)
	
	
func add_scatter() -> Goshape:
	var shape := create_blank()
	shape.name = StringName("ScatterShape%d" % shape.get_parent().get_child_count())
	shape.set_shaper(ScatterShaper.new())
	return complete_new_shape(shape)
	
	
func add_multishaper() -> Goshape:
	var shape := create_blank()
	shape.name = StringName("MultiShape%d" % shape.get_parent().get_child_count())
	shape.set_shaper(MultiShaper.new())
	return complete_new_shape(shape)
	
	
func complete_new_shape(shape: Goshape) -> Goshape:
	if shape.path_options == null:
		shape.set_path_options(PathOptions.new())
	select_block(shape)
	modify_selected()
	return shape


func add_block_similar() -> Goshape:
	var attributes = BlockAttributes.new()
	var target = proxy.last_selected
	attributes.copy(target)
	var shape := create_blank()
	attributes.apply(shape)
	var name := ResourceUtils.inc_name_number(target.name)
	shape.name = StringName(name)
	return complete_new_shape(shape)
	
	
func modify_selected(method: String = "", arg = null) -> void:
	var selected_nodes = selection_handler.get_selected_nodes()
	
	var nodes_to_modify: Array[Goshape] = []
	for node in selected_nodes:
		if node is Goshape:
			nodes_to_modify.push_back(node as Goshape)

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
				if not proxy.use_shape_select:
					break
				selected_parent = selected_parent.get_parent()
		if block and proxy.selected_block != selected_node:
			select_block(block)
			
	var shape_selected = false
	for node in selected_nodes:
		if node is Goshape:
			shape_selected = true
	
	if shape_selected:
		set_menu(MenuSet.BLOCK, tools_block)
	else:
		set_menu(MenuSet.DEFAULT, tools_default)
				
				
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
