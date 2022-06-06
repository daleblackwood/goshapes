@tool
class_name JobRunner

var queue: Array[Job] = []
var run_count = 0
var current_job
var groups: Array[JobGroup] = []
var group_count = 0
var is_busy: bool = false: get = get_is_busy


func get_is_busy() -> bool:
	return current_job != null or groups.size() > 0 or queue.size() > 0


func run(job, host, callback: String) -> void:
	run_count += 1
	job.id = run_count
	job.host = host
	job.callback = callback
	queue.append(job)
	if queue.size() == 1:
		next()
		
		
func clear_jobs(host) -> void:
	var job_count = queue.size()
	for i in range(job_count - 1, -1 , -1):
		if queue[i].host == host:
			queue.remove_at(i)
	if current_job:
		current_job.host = null
		current_job = null
	
		
func run_group(jobs: Array, host, callback: String) -> void:
	var job_count = jobs.size()
	var group = JobGroup.new()
	group.host = host
	group.callback = callback
	group.jobs = jobs
	group_count += 1
	group.id = group_count
	group.runner = self
	groups.append(group)
	for i in range(job_count):
		jobs[i].group = group
		run(jobs[i], group, "job_done")
				

func next() -> void:
	if queue.size() < 1:
		current_job = null
		return
		
	current_job = queue.pop_front()
	current_job.run(current_job.host, current_job.callback)
	call_deferred("job_done", current_job)
	
	
func job_done(job) -> void:
	next()
	

func group_done(group: JobGroup) -> void:
	var index = groups.find(group)
	if index >= 0:
		groups.remove_at(index)
	
