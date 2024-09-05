@tool
class_name GoshBuildRunner

class GoBuildJob:
	var id := 0
	var host: Goshape
	var builder: ShapeBuilder
	var state := BuildState.Init
	var path: GoshPath
	var callback: Callable

var queue: Array[GoBuildJob] = []
var run_count := 0
var is_busy := false: get = get_is_busy
var thread: Thread = null

enum BuildState { Init, Running, Done, Cancelled }


func get_is_busy() -> bool:
	return queue.size() > 0 and queue[0].state < BuildState.Done
		
		
func clear_from(host: Node) -> void:
	for i in range(queue.size() - 1, -1 , -1):
		if queue[i].host == host:
			queue.remove_at(i)
		
		
func clear_job(id: int) -> void:
	for i in range(queue.size() - 1, -1 , -1):
		if queue[i].id == id:
			queue.remove_at(i)
	
	
func enqueue(host: Goshape, path: GoshPath, builders: Array[ShapeBuilder], callback: Callable) -> Array[int]:
	var result: Array[int] = []
	for builder in builders:
		result.append(enqueue_one(host, path, builder, callback))
	return result
				

func enqueue_one(host: Goshape, path: GoshPath, builder: ShapeBuilder, callback: Callable) -> int:
	var job = GoBuildJob.new()
	run_count += 1
	job.id = run_count
	job.host = host
	job.builder = builder
	job.builder.host = host
	job.path = path
	job.callback = callback
	queue.append(job)
	if queue.size() == 1:
		next()
	return job.id
	

func next() -> void:
	while queue.size() > 0 and queue[0].state >= BuildState.Done:
		queue.pop_front()
		
	if queue.size() < 1:
		return
		
	var current_job = queue[0]
	if current_job.state == BuildState.Running:
		current_job.state == BuildState.Cancelled
		
	if thread != null:
		thread.cancel_free()
		thread = null
		
	current_job.state = BuildState.Running
	thread = Thread.new()
	thread.start(run_job, Thread.PRIORITY_HIGH)
	
	
func run_job() -> void:
	var job = queue[0]
	job.state = BuildState.Running
	build_run(job)
	
	
func build_run(job: GoBuildJob) -> void:
	if job.state == BuildState.Cancelled:
		return
	job.builder.build(job.host, job.path)
	if job.state == BuildState.Cancelled:
		return
	build_commit.call_deferred(job)
	
	
func build_commit(job: GoBuildJob) -> void:
	job.builder.commit()
	job.builder.commit_colliders()
	job.state = BuildState.Done
	thread.wait_to_finish()
	next()
