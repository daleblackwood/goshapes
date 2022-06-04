@tool
extends Job
class_name BuildJob
	

func _init(builder, style, path: PathData) -> void:
	super.set_input({
		"builder": builder,
		"style": style,
		"path": path
	})


func _run(input):
	var meshset = input.builder.build(input.style, input.path)
	
	#var mesh = ArrayMesh.new()
	#MeshUtils.build_meshes(meshset, mesh)
				
	return meshset
