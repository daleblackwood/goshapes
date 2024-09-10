class_name GoshapeJob

enum State { Init, Running, Done, Cancelled }


var id := 0
var host: Node3D
var builder: ShapeBuilder
var callable: Callable
var state := State.Init
var path: GoshapePath
var thread: Thread
var order := 0
var is_scene := false
var has_ran := false


func _init(builder: ShapeBuilder, path: GoshapePath, callable: Callable, order := 0, is_scene := false) -> void:
	self.host = builder.host
	self.builder = builder
	self.path = path
	self.callable = callable
	self.order = order
	self.is_scene = is_scene
	

func run() -> void:
	if is_scene:
		do_run.call_deferred()
	else:
		do_run.call()
		

func do_run() -> void:
	if state > State.Running:
		has_ran = true
		return
	if callable is Callable:
		callable.call()
	has_ran = true
