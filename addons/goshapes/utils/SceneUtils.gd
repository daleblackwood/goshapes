@tool
class_name SceneUtils
## Convenience utilities that manipulate scenes resources

static func get_or_create(parent: Node, name: String, type: Object) -> Node:
	if not parent:
		return null
	var result: Node = parent.find_child(name, false)
	if not result:
		result = create(parent, name, type)
	return result
	
	
static func create(parent: Node, name: String, type: Object) -> Node:
	if not parent:
		return null
	var owner = get_owner(parent)
	if not owner:
		return null
	var result = type.new()
	result.name = name
	add_child(parent, result)
	return result
	
	
static func add_child(parent: Node, child: Node) -> Node:
	if not parent:
		return null
	var owner = get_owner(parent)
	if not owner:
		return null
	parent.add_child(child)
	child.set_owner(owner)
	return child
	
		
static func get_owner(parent: Node):
	if Engine.is_editor_hint():
		var tree = parent.get_tree()
		if not tree:
			return null
		return tree.edited_scene_root
	return parent.get_scene()
		
		
static func remove(owner: Node, name: String) -> void:
	var node = owner.find_child(name, false)
	if node:
		owner.remove_child(node)
		
		
		
#static func get_edited_scene_root() -> Node:
#	if not Engine.is_editor_hint():
#		return null
#	return EditorScript.new().get_editor_interface().get_edited_scene_root()
