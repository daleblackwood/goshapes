@tool
class_name Shaper
extends Resource

## Enables or disables the building of this Shaper
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()
		
func get_builders() -> Array[ShapeBuilder]:
	return []
	
func get_build_jobs(host: Node3D, path: GoshapePath) -> Array[GoshapeJob]:
	return []
	
func get_name() -> String:
	return ResourceUtils.get_type(self)
	
func build(host: Node3D, path: GoshapePath) -> void:
	if not Engine.is_editor_hint():
		return
		
	var start_time = Time.get_ticks_msec()
	var builders = get_builders()
	if builders.size() > 0:
		for builder in builders:
			if builder != null:
				builder.setup(host, path)
				builder.build()
				builder.commit()
				builder.commit_colliders()
	else:
		printerr("No builder for host %s" % host.name)
	print("build job took %dms" % (Time.get_ticks_msec() - start_time))
