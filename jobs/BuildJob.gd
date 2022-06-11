@tool
extends Job
class_name BuildJob
	

func _init(builder: ShapeBuilder, path: PathData) -> void:
	super.set_input({
		"builder": builder,
		"path": path
	})


func _run(input):
	var builder = input.builder
	var build_func = builder.build.bind(builder) as Callable
	var mesh = build_func.call(host, input.path)
	return mesh
