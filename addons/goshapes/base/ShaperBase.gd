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
	
func build(host: Node3D, path: GoshPath) -> void:
	if not Engine.is_editor_hint():
		return
		
	var start_time = Time.get_ticks_msec()
	var builder = get_builder()
	if builder != null:
		builder.build(host, path)
	else:
		printerr("No builder for host %s" % host.name)
	print("build job took %dms" % (Time.get_ticks_msec() - start_time))
	
func get_builders() -> Array[ShapeBuilder]:
	return [get_builder()]
