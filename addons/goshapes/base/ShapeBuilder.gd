@tool
class_name ShapeBuilder
	
var host: Node3D
var path: GoshPath
var base_shaper: Shaper

func _init(_shaper: Shaper):
	base_shaper = _shaper

func build(_host: Node3D, _path: GoshPath) -> void:
	host = _host
	path = _path
	printerr("Can't build %s on %s as it's a base type" % [ResourceUtils.get_type(base_shaper), host.name])
	
func commit() -> void:
	printerr("Can't commit %s on %s as it's a base type" % [ResourceUtils.get_type(base_shaper), host.name])
	
func commit_colliders() -> void:
	pass
		
	
