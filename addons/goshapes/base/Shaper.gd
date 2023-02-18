@tool
class_name Shaper
extends Resource
## The base type that binds a builder to the Goshape

## Enables or disables the building of this Shaper
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()


func get_builder() -> ShapeBuilder:
	return null
	
	
func get_name() -> String:
	return ResourceUtils.get_type(get_script())
	
	
func build(host: Node3D, path: PathData) -> void:
	if not Engine.is_editor_hint():
		return
	var builder = get_builder()
	if builder != null:
		builder.build(host, path)
		
		
func get_build_job(path: PathData) -> Job:
	var builder = get_builder()
	if builder != null:
		return builder.get_build_job(path)
	return null
