@tool
class_name MeshShaper
extends Shaper
## The base shaper for all shapers

## Toggles whether or not to build a collider
@export_group("Groups & Collisions")
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
			
	
func get_build_jobs(data: GoshapeBuildData) -> Array[GoshapeJob]:
	var result: Array[GoshapeJob] = []
	var owner_id = data.get_owner_id()
	if data.rebuild:
		clear_builders(owner_id)
	var builders := get_builders(owner_id)
	var offset = get_order_offset()
	for builder in builders:
		result += builder.get_build_jobs(data, offset)
	return result
	
	
func get_order_offset() -> int:
	return 0
