@tool
class_name ShaperTypes

static func get_types() -> Array:
	return get_base_types()
	
	
static func get_base_types() -> Array:
	return [
		BlockShaper,
		ScatterShaper
	]
	
	
static func get_cap_types() -> Array:
	return [
		CapFlatShaper,
		CapLineShaper,
		CapPlaneShaper
	]
	
	
static func get_wall_types() -> Array:
	return [
		WallBevelShaper,
		WallMeshShaper
	]
	
	
static func get_sibling_types(shaper: Shaper) -> Array:
	if is_base_type(shaper):
		return get_base_types()
	if is_cap_type(shaper):
		return get_cap_types()
	if is_wall_type(shaper):
		return get_wall_types()
	return []


static func is_base_type(shaper: Shaper) -> bool:
	for type in get_base_types():
		if shaper is type:
			return true
	return false
	
		
static func is_cap_type(shaper: Shaper) -> bool:
	for type in get_cap_types():
		if shaper is type:
			return true
	return false
	
	
static func is_wall_type(shaper: Shaper) -> bool:
	for type in get_wall_types():
		if shaper is type:
			return true
	return false
