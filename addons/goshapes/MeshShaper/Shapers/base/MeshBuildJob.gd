@tool
class_name MeshBuildJob
extends Job
	
func _init(builder: MeshBuilder, path: PathData, dest_mesh: Mesh = null):
	super.set_input({
		"builder": builder,
		"path": path,
		"dest_mesh": dest_mesh
	})

func _run(input):
	var mesh = input.builder.build_sets(input.path, input.dest_mesh)
	return mesh
