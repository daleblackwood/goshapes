@tool
class_name ShaperTypes
## Utilities and types that control, set and retreive Shapers
	
static func get_base_types() -> Array:
	return [
		BlockShaper,
		ScatterShaper,
		MultiShaper
	]
	
	
static func get_cap_types() -> Array:
	return [
		CapFlatShaper,
		CapLineShaper,
		CapPlaneShaper,
		CapMoundShaper
	]
	
	
static func get_wall_types() -> Array:
	return [
		WallBevelShaper,
		WallMeshShaper,
		WallCurveShaper
	]
	
	
static func get_bottom_types() -> Array:
	return [
		BottomShaper
	]
	
	
static func get_sibling_types(shaper: Shaper) -> Array:
	if not shaper or is_base_type(shaper):
		return get_base_types()
	if is_cap_type(shaper):
		return get_cap_types()
	if is_wall_type(shaper):
		return get_wall_types()
	if is_bottom_type(shaper):
		return get_bottom_types()
	return []
	
	
static func get_type_name(shaper: Resource) -> String:
	return ResourceUtils.get_type(shaper)
	
	
static func get_types_string(shapers: Array) -> String:
	var result = ""
	for i in range(shapers.size()):
		result += get_type_name(shapers[i])
		if i < shapers.size() - 1:
			result += ","
	return result
	

static func is_base_type(shaper: Shaper) -> bool:
	for type in get_base_types():
		if is_instance_of(shaper, type):
			return true
	return false
	
		
static func is_cap_type(shaper: Shaper) -> bool:
	for type in get_cap_types():
		if is_instance_of(shaper, type):
			return true
	return false
	
	
static func is_wall_type(shaper: Shaper) -> bool:
	for type in get_wall_types():
		if is_instance_of(shaper, type):
			return true
	return false


static func is_bottom_type(shaper: Shaper) -> bool:
	for type in get_bottom_types():
		if is_instance_of(shaper, type):
			return true
	return false
