@tool
class_name ShapeBuilder
	
var host: Node3D
var path: GoshapePath
var base_shaper: Shaper

func _init(_shaper: Shaper):
	base_shaper = _shaper
	
func setup(host: Node3D, path: GoshapePath) -> void:
	self.host = host
	self.path = path

func build() -> void:
	printerr("Can't build %s on %s as it's a base type" % [ResourceUtils.get_type(base_shaper), host.name])
	
func commit() -> void:
	printerr("Can't commit %s on %s as it's a base type" % [ResourceUtils.get_type(base_shaper), host.name])
	
func commit_colliders() -> void:
	pass
		
	
