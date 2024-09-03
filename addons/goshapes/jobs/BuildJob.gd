@tool
class_name BuildJob
extends Job

var builder: ShapeBuilder
var path: PathData
	

func _init(builder: ShapeBuilder, path: PathData):
	self.builder = builder
	self.path = path


func _run():
	#var build_func = builder.build.bind(builder) as Callable
	#var mesh = build_func.call(host, input.path)
	builder.build(host, path)
