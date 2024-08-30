@tool
class_name ResourceUtils		
## Utilities that manipulate Goshapes resources
		
static func is_local(resource: Resource) -> bool:
	return not is_file(resource)	
	
	
static func is_file(resource: Resource) -> bool:
	if not resource is Resource:
		return false
	var resource_path = resource.resource_path
	if resource_path and resource_path.begins_with("res:") and resource_path.find("::") < 0:
		return true
	return false
	
	
static func make_local(owner: Variant, resource: Resource):
	if not resource is Resource:
		return null
	var owner_name = get_owner_name(owner)
	var local_name = owner_name + "-" + get_type(resource)
	if is_file(resource):
		return resource
	if resource.resource_name == local_name:
		return resource
	var duplicate = resource.duplicate(false)
	duplicate.resource_name = local_name
	duplicate.setup_local_to_scene()	
	var script = resource.get_script() as Script
	if script:
		for prop in script.get_script_property_list():
			var key = prop.name as String
			var value = resource.get(key)
			if value and value is Resource:
				script.set(key, make_local(resource, value))
	return duplicate
	
	
static func get_owner_name(owner: Variant) -> String:
	if owner is Resource:
		return owner.resource_name
	if owner is Node:
		return owner.name
	printerr("Invalid owner")
	return "?"


static func get_type(resource: Resource) -> String:
	var script = resource if resource is Script else resource.get_script()
	var name = get_local_path(script)
	var last_dot = name.rfind(".")
	if last_dot > 0:
		name = name.substr(0, last_dot)
	return name
	
	
static func get_local_path(resource: Resource) -> String:
	var name = null if not resource else resource.resource_path
	if name == null or name.length() < 1:
		return ""
	if name.find("::") > 0:
		return ""
	name = name.substr(name.rfindn("/") + 1)
	return name	
	
	
static func inc_name_number(name: String) -> String:
	var append_index := name.length()
	while name[append_index - 1] >= '0' and name[append_index - 1] <= '9':
		append_index -= 1
	var prefix = name.substr(0, append_index)
	var suffix = int(name.substr(append_index))
	suffix += 1
	return prefix + str(suffix)
