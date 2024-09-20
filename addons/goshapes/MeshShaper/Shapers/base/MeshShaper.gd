@tool
class_name MeshShaper
extends Shaper
## The base shaper for all shapers

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

@export_group("Groups & Collisions")

## Toggles whether or not to build a collider
@export var build_collider: bool = true:
	set(value):
		if build_collider != value:
			build_collider = value
			emit_changed()
			

## Sets which physics layers the collider uses
@export_flags_3d_physics var collision_layer: int = 1:
	set(value):
		if collision_layer != value:
			collision_layer = value
			emit_changed()
			
## Sets a group name for the mesh and colliders
@export var group_name := "":
	set(value):
		if group_name != value:
			group_name = value
			emit_changed()
			

func apply_path_mods(data: GoshapeBuildData) -> GoshapeBuildData:
	var result = data.duplicate()
	if path_offset_y != 0.0:
		result.path = PathUtils.move_path(result.path, Vector3.UP * path_offset_y)
	if path_inset != 0.0:
		result.path = PathUtils.taper_path(result.path, -path_inset)
	return result
			
	
func get_build_jobs(data: GoshapeBuildData) -> Array[GoshapeJob]:
	var result: Array[GoshapeJob] = []
	var owner_id = data.get_owner_id()
	if data.rebuild:
		clear_builders(owner_id)
	var builders := get_builders(owner_id)
	var offset = get_order_offset()
	var local_data = apply_path_mods(data)
	for builder in builders:
		result += builder.get_build_jobs(local_data, offset)
	return result
	
	
func get_order_offset() -> int:
	return 0
