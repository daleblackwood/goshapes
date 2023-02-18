@tool
class_name ShapeBuilder
## The base type that builds geometry on top of Goshapes
	
var host: Node3D
var path: PathData


func build(_host: Node3D, _path: PathData) -> void:
	host = _host
	path = _path
	printerr("Not implemented")
	
	
func get_build_job(path: PathData) -> Job:
	return BuildJob.new(self, path)
