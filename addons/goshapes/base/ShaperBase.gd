@tool
class_name Shaper
extends Resource

## Enables or disables the building of this Shaper
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()
		
var builders: Array[ShapeBuilder] = []
		
func create_builders() -> Array[ShapeBuilder]:
	return []
	
func get_builders() -> Array[ShapeBuilder]:
	if builders.size() < 1:
		builders = create_builders()
	for builder in builders:
		builder.reset()
	return builders
	
func get_build_jobs(data: GoshapeBuildData) -> Array[GoshapeJob]:
	if data.rebuild:
		builders.resize(0)
	return []
	
func get_name() -> String:
	return ResourceUtils.get_type(self)
	
func build(data: GoshapeBuildData) -> void:
	if not Engine.is_editor_hint():
		return
		
	var start_time = Time.get_ticks_msec()
	var builders = get_builders()
	if builders.size() > 0:
		for builder in builders:
			if builder != null:
				builder.build(data)
				builder.commit(data)
				builder.commit_colliders(data)
	else:
		printerr("No builder for host %s" % data.host.name)
	print("build job took %dms" % (Time.get_ticks_msec() - start_time))
