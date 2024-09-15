@tool
class_name ShapeBuilder
	
var base_shaper: Shaper

func _init(_shaper: Shaper):
	base_shaper = _shaper
	reset()
	
func reset():
	pass

func build(data: GoshapeBuildData) -> void:
	printerr("Can't build %s on %s as it's a base type" % [ResourceUtils.get_type(base_shaper), data.parent.name])
	
func commit(data: GoshapeBuildData) -> void:
	printerr("Can't commit %s on %s as it's a base type" % [ResourceUtils.get_type(base_shaper), data.parent.name])
	
func commit_colliders(data: GoshapeBuildData) -> void:
	pass
		
	
