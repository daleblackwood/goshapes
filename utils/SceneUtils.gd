@tool
class_name SceneUtils

static func get_or_create(parent: Node, name: String, type: Object) -> Node:
	if not parent:
		return null
	var result: Node = parent.find_child(name, false)
	if not result:
		var owner = get_owner(parent)
		if not owner:
			return null
		result = type.new()
		result.name = name
		parent.add_child(result)
		result.set_owner(owner)
	return result
	
		
static func get_owner(parent: Node):
	if Engine.is_editor_hint():
		var tree = parent.get_tree()
		if not tree:
			return null
		return tree.edited_scene_root
	return parent.get_scene()
	
	
static func switch_signal(owner: Object, signal_name: String, method: String, old_target: Object, new_target: Object) -> void:
	if old_target and old_target.is_connected(signal_name, Callable(owner, method)):
		old_target.disconnect(signal_name, Callable(owner, method))
	if new_target and not new_target.is_connected(signal_name, Callable(owner, method)):
		new_target.connect(signal_name, Callable(owner, method))
		
		
static func remove(owner: Node, name: String) -> void:
	var node = owner.find_child(name, false)
	if node:
		owner.remove_child(node)
		
		
static func get_edited_scene_root() -> Node:
	if not Engine.is_editor_hint():
		return null
	return EditorScript.new().get_editor_interface().get_edited_scene_root()
