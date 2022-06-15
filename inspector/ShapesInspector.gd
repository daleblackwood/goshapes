@tool
extends EditorInspectorPlugin
class_name ShapesInspector

var editor: EditorInterface
var shaper_types: Array

func _init(_editor: EditorInterface):
	editor = _editor


func _can_handle(object):
	print("_can_handle", object)
	return object is Goshape or object is Array
	

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	return false
		
		
func _parse_end(object):
	if not object is Goshape:
		return
		
	var inspector = editor.get_inspector()
	var pickers = find_resource_pickers(inspector)
	for picker in pickers:
		var idx = picker.set_script(ShaperResourcePicker)
		
		
func find_resource_pickers(parent: Node, results = []) -> Array[EditorResourcePicker]:
	for child in parent.get_children():
		if child is EditorResourcePicker:
			results.append(child)
		find_resource_pickers(child, results)
	return results
	
	
