@tool
extends EditorInspectorPlugin
class_name ShaperInspector


class ShaperHeaderInjector extends Control:
	
	var host: Object
	var propname: String
	var shaper: Shaper
	
	func _init(_host: Object, _propname: String):
		host = _host
		propname = _propname
		shaper = host.get(propname)
		
	func takeover() -> void:
		if not visible:
			return
		var index = get_index()
		var sibling = get_parent().get_child(index + 1)
		for child in sibling.get_children():
			if child is EditorResourcePicker:
				child.get_child(1).visible = false
				break
		visible = false
		

var editor: EditorInterface
var change_button: MenuButton
var current: ShaperHeaderInjector
var headers: Array[ShaperHeaderInjector] = []


func _init(_editor: EditorInterface):
	editor = _editor


func _can_handle(object):
	if object is Goshape:
		headers.clear()
		return true
	if object is Shaper:
		return true
	return false
	

func _parse_begin(object):
	if object is Shaper:
		for header in headers:
			if not header.shaper == object:
				continue
			print("found it")
			add_custom_control(ShaperInspectorHeader.new(header.host, header.propname))
			break
		
		
func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if (object is Goshape or object is Shaper) and hint_string == "Resource":
		var value = object.get(name)
		if value is Shaper:
			print("it's a shaper")
			current = ShaperHeaderInjector.new(object, name)
			add_custom_control(current)
			headers.append(current)
	return false
	

func _parse_end(object):
	if headers.size() > 0:
		for header in headers:
			header.takeover()

