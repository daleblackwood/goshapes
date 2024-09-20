@tool
class_name Shaper
extends Resource

## Enables or disables the building of this Shaper
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()

@export_group("Path Mods")
## Offsets the path by a certain vertical distance		
@export var path_offset_y := 0.0:
	set(value):
		if path_offset_y != value:
			path_offset_y = value
			emit_changed()
	
## Offsets the path by a certain vertical distance		
@export_range(-50.0, 50.0) var path_inset := 0.0:
	set(value):
		if path_inset != value:
			path_inset = value
			emit_changed()		
		
var builders: Dictionary = {}
		
func create_builders() -> Array[ShapeBuilder]:
	return []
	
func get_builders(owner_id: int) -> Array[ShapeBuilder]:
	if not builders.has(owner_id):
		var local_builders = create_builders()
		for builder in local_builders:
			builder.reset()
		builders[owner_id] = local_builders
	return builders[owner_id]
	
func clear_builders(owner_id: int) -> void:
	if builders.has(owner_id):
		builders.erase(owner_id)
	
func get_build_jobs(data: GoshapeBuildData) -> Array[GoshapeJob]:
	if data.rebuild:
		clear_builders(data.get_owner_id())
	return []
	
func apply_path_mods(data: GoshapeBuildData) -> GoshapeBuildData:
	var result = data.duplicate()
	if path_offset_y != 0.0:
		result.path = PathUtils.move_path(result.path, Vector3.UP * path_offset_y)
	if path_inset != 0.0:
		result.path = PathUtils.taper_path(result.path, -path_inset)
	return result
	
func get_name() -> String:
	return ResourceUtils.get_type(self)
	
func build(data: GoshapeBuildData) -> void:
	if not Engine.is_editor_hint():
		return
		
	var start_time = Time.get_ticks_msec()
	var builders = get_builders(data.get_owner_id())
	if builders.size() > 0:
		for builder in builders:
			if builder != null:
				builder.build(data)
				builder.commit(data)
				builder.commit_colliders(data)
	else:
		printerr("No builder for host %s" % data.host.name)
	print("build job took %dms" % (Time.get_ticks_msec() - start_time))
