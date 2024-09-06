@tool
class_name GoshBuildRunner

enum JobState { Init, Running, Done, Cancelled }

class GoBuildJob:
	var id := 0
	var host: Node3D
	var builder: ShapeBuilder
	var state := JobState.Init
	var path: GoshPath
	var thread: Thread
	var callback = null
	
	
class GoDeferredStep:	
	var job: GoBuildJob
	var callable: Callable
	var is_done := false
	func _init(job: GoBuildJob, callable: Callable) -> void:
		self.job = job
		self.callable = callable
		if job.state == JobState.Cancelled:
			is_done = true
		else:
			_run.call_deferred()
	func _run() -> void:		
		if job.state == JobState.Running:
			callable.call(job)
		is_done = true
	func wait() -> void:
		while not is_done and job.state == JobState.Running:
			OS.delay_msec(10)
		

var queue: Array[GoBuildJob] = []
var run_count := 0
var is_busy := false: get = get_is_busy

func get_is_busy() -> bool:
	return queue.size() > 0 and queue[0].state < JobState.Done
		
		
func cancel(host: Node) -> void:
	for i in range(queue.size() - 1, -1 , -1):
		var job = queue[i]
		if job.host == host:
			queue.remove_at(i)
		if job.state == JobState.Running:
			job_cancel(job)
	
	
func enqueue(host: Node3D, path: GoshPath, builders: Array[ShapeBuilder], callback: Callable) -> Array[int]:
	var result: Array[int] = []
	for builder in builders:
		result.append(enqueue_one(host, path, builder, callback))
	return result
				

func enqueue_one(host: Node3D, path: GoshPath, builder: ShapeBuilder, callback: Callable) -> int:
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
	while queue.size() > 0 and queue[0].state >= JobState.Done:
		queue.pop_front()
		
	if queue.size() < 1:
		return
		
	var job = queue[0]
	if job.state == JobState.Running:
		return
		
	job.state = JobState.Running
	job.thread = Thread.new()
	job.thread.start(run_job, Thread.PRIORITY_NORMAL)
	
	
func run_job() -> void:
	var job = queue[0]
	job.state = JobState.Running
	build_run(job)
	var step = GoDeferredStep.new(job, build_commit)
	step.wait()
	step = GoDeferredStep.new(job, build_colliders)
	step.wait()
	job_complete.call_deferred(job)
		
	
func build_run(job: GoBuildJob) -> void:
	if job.state == JobState.Cancelled:
		return
	job.builder.build(job.host, job.path)
	
	
func build_commit(job: GoBuildJob) -> void:
	if job.state == JobState.Cancelled:
		return
	job.builder.commit()
	
	
func build_colliders(job: GoBuildJob) -> void:
	if job.state == JobState.Cancelled:
		return
	job.builder.commit_colliders()
	
	
func job_complete(job: GoBuildJob) -> void:
	job.thread.wait_to_finish()
	job.state = JobState.Done
	if job.callback != null:
		job.callback.call_deferred()
	next()
	
func job_cancel(job: GoBuildJob) -> void:
	if job.state == JobState.Cancelled:
		return
	job.state == JobState.Cancelled
