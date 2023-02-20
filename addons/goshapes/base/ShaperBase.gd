@tool
class_name Shaper
extends Resource

## Enables or disables the building of this Shaper
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()

func get_builder() -> ShapeBuilder:
	return ShapeBuilder.new(self)
	
func get_name() -> String:
	return ResourceUtils.get_type(self)
	
func build(host: Node3D, path: PathData) -> void:
	if not Engine.is_editor_hint():
		return
	var builder = get_builder()
	if builder != null:
		builder.build(host, path)
	else:
		printerr("No builder for host %s" % host.name)
				
func get_build_job(path: PathData) -> Job:
	var builder = get_builder()
	if builder != null:
		return builder.get_build_job(path)
	return null
