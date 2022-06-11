@tool
extends Resource
class_name Shaper


func get_builder() -> ShapeBuilder:
	return null
	
	
func get_name() -> String:
	var result = get_script().resource_name
	var dotI = result.findn(".")
	if dotI > 0:
		result = result.substr(0, dotI)
	result = result.substr(result.findn("/") + 1)
	result = result.replace("Shaper", "")
	return result
	
	
func build(host: Node3D, path: PathData) -> void:
	var builder = get_builder()
	if builder != null:
		builder.build(host, path)
		
		
func get_build_job(path: PathData) -> Job:
	var builder = get_builder()
	if builder != null:
		return builder.get_build_job(path)
	return null
