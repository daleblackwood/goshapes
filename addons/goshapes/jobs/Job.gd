@tool
class_name Job
extends Node


enum State { INIT, RUNNING, DONE }
var state = State.INIT
var thread: Thread
var mutex: Mutex
var input
var output
var host
var callback: Callable
var id = -1
var group
var is_async = true


func run(host, callback: Callable) -> void:
	self.host = host
	self.callback = callback
	state = State.RUNNING
	if is_async:
		run_async()
	else:
		run_sync()
	
	
func run_sync() -> void:
	output = _run(input)
	done()


func run_async() -> void:
	thread = Thread.new()
	mutex = Mutex.new()
	thread.start(_async_begin, input.duplicate())
	
	
func _async_begin(input):
	var result = _run(input.duplicate())
	call_deferred("_async_end")
	return result
	
	
func _async_end():
	lock(true)
	output = thread.wait_to_finish()
	lock(false)
	done()

	
func _run(input):
	push_error("can't run base job")
	
	
func set_input(data) -> void:
	lock(true)
	self.input = data
	lock(false)
	
	
func lock(value: bool) -> void:
	if value:
		if mutex:
			mutex.lock()
	else:
		if mutex:
			mutex.unlock()
		
	
func done() -> void:
	state = State.DONE
	callback_job(self)
	
	
func _exit_tree() -> void:
	if thread:
		thread.wait_to_finish()
			
			
static func callback_job(job: Job) -> void:
	if not job.host:
		print("nothing waiting on job ", job.id, ": ", job, ": ", job.group)
		return
	callback_host(job.host, job.callback, job)
	
		
static func callback_host(host, callback: Callable, jobHost) -> void:
	if not host:
		return
	if host is Node:
		callback.call_deferred(jobHost)
	else:
		callback.call(jobHost)
	
