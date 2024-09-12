class_name GoshapeJob

enum State { Init, Running, Done, Cancelled }

enum Mode { Normal, Immediate, Scene }

var id := 0
var data: GoshapeBuildData
var owner: Object
var callable: Callable
var state := State.Init
var path: GoshapePath
var thread: Thread
var order := 0
var is_scene := false
var has_ran := false
var mode := Mode.Normal
var start_time := 0


func _init(owner: Object, data: GoshapeBuildData, callable: Callable, order := 0, mode := Mode.Normal) -> void:
	self.owner = owner
	self.data = data
	self.callable = callable
	self.order = order
	self.mode = mode
	

func run() -> void:
	if mode == Mode.Scene:
		do_run.call_deferred()
	else:
		do_run.call()
		

func do_run() -> void:
	if state > State.Running:
		has_ran = true
		return
	if callable is Callable:
		callable.call(data)
	has_ran = true
