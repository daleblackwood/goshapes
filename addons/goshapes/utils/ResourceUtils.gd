@tool
class_name ResourceUtils		
## Utilities that manipulate Goshapes resources
		
static func is_local(resource: Resource) -> bool:
	if not resource:
		return true
	var resource_path = resource.resource_path
	if resource_path == null or resource_path.find("::") > 0:
		return true
	return false
					
	
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
		if value:
			result[key] = parse_dict_value(value)
	return result
	
	
static func local_duplicate(resource: Resource):
	if not resource is Resource:
		return null
	var result = Resource.new()
	var script = resource.get_script() as Script
	result.set_script(script)
	result.setup_local_to_scene()
	for prop in script.get_script_property_list():
		var key = prop.name as String
		var value = resource.get(key)
		if value:
			result.set(key, value)
	return result
	

static func parse_dict_value(value):
	if value:
		if value is Array:
			var count = value.size()
			var arr = []
			arr.resize(count)
			for i in range(count):
				arr[i] = parse_dict_value(value)
			return arr
		if value is Resource:
			return to_dict(value)
	return value


static func get_type(resource: Resource) -> String:
	if resource.resource_name != null and resource.resource_name.length() > 0:
		return resource.resource_name
	var name = get_local_path(resource)
	return name
	
	
static func get_local_path(resource: Resource) -> String:
	var name = null if not resource else resource.resource_path
	if name == null or name.length() < 1:
		return ""
	if name.find("::") > 0:
		return ""
	name = name.substr(name.rfindn("/") + 1)
	return name
	
	
static func get_local_name(resource: Resource) -> String:
	var name = get_local_path(resource)
	if name.length() < 1:
		return ""
	var dotI = name.rfindn(".")
	if dotI > 0:
		name = name.substr(0, dotI)
	return name
	
	
static func copy_props(src: Resource, dest: Resource) -> void:
	if src == null or dest == null:
		return
	var src_props = src.get_property_list()
	var dest_props = dest.get_property_list()
	if src_props.size() < 1 or dest_props.size() < 1:
		return
	for src_prop in src_props:
		if (src_prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		for dest_prop in dest_props:
			if src_prop.name == dest_prop.name and src_prop.type == dest_prop.type:
				dest.set(src_prop.name, src.get(src_prop.name))
				
		
static func inc_name_number(name: String) -> String:
	var append_index := name.length()
	while name[append_index - 1] >= '0' and name[append_index - 1] <= '9':
		append_index -= 1
	var prefix = name.substr(0, append_index)
	var suffix = int(name.substr(append_index))
	print(prefix, " ", suffix)
	suffix += 1
	return prefix + str(suffix)
	
