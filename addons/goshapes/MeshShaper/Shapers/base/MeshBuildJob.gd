@tool
class_name MeshBuildJob
extends Job


var builder: MeshBuilder
var path: PathData
var dest_mesh: Mesh
	
	
func _init(_builder: MeshBuilder, _path: PathData, _dest_mesh: Mesh = null):
	builder = _builder
	path = _path
	dest_mesh = _dest_mesh
	

func _run():
	var mesh = builder.build_sets(path)
	return mesh
