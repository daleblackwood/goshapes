@tool
class_name JobRunner

var queue: Array[Job] = []
var run_count = 0
var current_job: Job
var groups: Array[JobGroup] = []
var group_count = 0
var is_busy: bool = false: get = get_is_busy


func get_is_busy() -> bool:
	return current_job != null or groups.size() > 0 or queue.size() > 0
		
		
func clear_jobs(host: Node) -> void:
	for i in range(queue.size() - 1, -1 , -1):
		if queue[i].host == host:
			queue.remove_at(i)
	for i in range(groups.size() - 1, -1 , -1):
		if groups[i].host == host:
			groups.remove_at(i)
	if current_job and current_job.host == host:
		current_job.host = null
		current_job = null
		
		
func clear_job(id: int) -> void:
	for i in range(queue.size() - 1, -1 , -1):
		if queue[i].id == id:
			queue.remove_at(i)
	for i in range(groups.size() - 1, -1 , -1):
		if groups[i].id == id:
			groups.remove_at(i)
		

func run(job_jobs_or_group, host, callback: Callable) -> int:
	if job_jobs_or_group is Job:
		return run_job(job_jobs_or_group, host, callback)
	elif job_jobs_or_group is Array:
		return run_jobs(job_jobs_or_group, host, callback)
	elif job_jobs_or_group is JobGroup:
		return run_group(job_jobs_or_group, host, callback)
	return -1
		
		
func run_job(job: Job, host, callback: Callable) -> int:
	if job.id < 1:
		job.id = get_id()
	job.host = host
	job.callback = callback
	queue.append(job)
	if queue.size() == 1:
		next()
	return job.id
		
		
func run_jobs(jobs: Array[Job], host, callback: Callable) -> int:
	var group = JobGroup.new()
	var job_count = jobs.size()
	for i in range(job_count):
		jobs[i].group = group
	return run_group(group, host, callback)
	
	
func run_group(group, host, callback: Callable) -> int:
	if group.id < 1:
		group.id = get_id()
	group.host = host
	group.callback = callback
	group.runner = self
	groups.append(group)
	return group.id
	
	
func get_id() -> int:
	run_count += 1
	return run_count
				

func next() -> void:
	if queue.size() < 1:
		current_job = null
		return
		
	current_job = queue.pop_front()
	current_job.run(current_job.host, current_job.callback)
	job_done.call_deferred(current_job)
	
	
func job_done(job: Job) -> void:
	next()
	

func group_done(group: JobGroup) -> void:
	var index = groups.find(group)
	if index >= 0:
		groups.remove_at(index)
	
