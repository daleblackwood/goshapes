@tool
class_name ShapeBuilder
	
var host: Node3D
var path: PathData
var base_shaper: Shaper

func _init(_shaper: Shaper):
	base_shaper = _shaper

func build(_host: Node3D, _path: PathData) -> void:
	host = _host
	path = _path
	printerr("Can't use %s on %s as it's a base type" % [ResourceUtils.get_type(base_shaper), host.name])
	
func get_build_job(path: PathData) -> Job:
	return BuildJob.new(self, path)
