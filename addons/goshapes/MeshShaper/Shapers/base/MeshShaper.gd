@tool
class_name MeshShaper
extends Shaper
## The base shaper for all shapers

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
			
	
func get_build_jobs(host: Node3D, path: GoshapePath) -> Array[GoshapeJob]:
	var result: Array[GoshapeJob] = []
	var builders := get_builders()
	var offset = get_order_offset()
	for builder in builders:
		builder.setup(host, path)
		result += builder.get_build_jobs(host, path, offset)
	return result
	
	
func get_order_offset() -> int:
	return 0
