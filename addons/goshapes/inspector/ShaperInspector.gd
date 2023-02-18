@tool
class_name ShaperInspector
extends EditorInspectorPlugin

var editor: EditorInterface
var change_button: MenuButton
var controllers: Array[ShaperInspectorController] = []


func _init(_editor: EditorInterface):
	editor = _editor


func _can_handle(object):
	if object is Goshape:
		for ctrl in controllers:
			if ctrl != null:
				ctrl.queue_free()
		controllers.clear()
		return true
	if object is Shaper:
		return true
	return false
	

func _parse_begin(object):
	if object is Shaper:
		for ctrl in controllers:
			if ctrl == null or not ctrl.shaper == object:
				continue
			add_custom_control(ShaperInspectorHeader.new(ctrl))
			break
		
		
func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if (object is Goshape or object is Shaper) and hint_string == "Resource":
		var value = object.get(name)
		if value is Shaper:
			var ctrl = ShaperInspectorController.new(editor, object, name)
			add_custom_control(ctrl)
			controllers.append(ctrl)
	return false
	
