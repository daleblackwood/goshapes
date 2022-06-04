class_name ResourceUtils		
		
static func is_local(resource: Resource) -> bool:
	if not resource:
		return true
	var resource_path = resource.resource_path
	if resource_path == null or resource_path.find("::") > 0:
		return true
	return false
	
	
static func switch_signal(owner: Object, method: String, old_target: Resource, new_target: Resource) -> void:
	var signal_target = new_target if is_local(new_target) else null
	SceneUtils.switch_signal(owner, "changed", method, old_target, signal_target)
					
	
static func is_readonly(resource: Resource) -> bool:
	if not resource:
		return false
	if resource.resource_path != null and not resource.resource_local_to_scene:
		return true
	return false

static func to_dict(resource: Resource):
	if not resource:
		return null
	var result = {}
	for prop in resource.get_property_list():
		var key = prop.name as String
		if key.begins_with("resource"):
			continue
		var value = resource.get(key)
		print("parse ", key, value)
		if value:
			result[key] = parse_dict_value(value)
	return result
	

static func parse_dict_value(value):
	if value:
		if value is Array:
			var count = value.size()
			var arr = []
			arr.resize(count)
			for i in count:
				arr[i] = parse_dict_value(value)
			return arr
		if value is Resource:
			return to_dict(value)
	return value
