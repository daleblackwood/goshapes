@tool
class_name MeshBuilder
extends ShapeBuilder
## The base type for all geometry shape builders
	
var tag := "Shape"
var base_style: MeshShaper
var meshes: Array[ArrayMesh] = []
var instances: Array[MeshInstance3D] = []

func _init(_style: MeshShaper) -> void:
	base_style = _style
	reset()
	

func build(data: GoshapeBuildData) -> void:
	var meshsets := build_sets(data.path)
	var mesh := MeshUtils.build_meshes(meshsets, null)
	if mesh == null:
		return
	mesh.resource_name = "%s%s%d" % [data.parent.name, tag, data.index]
	if meshes.size() <= data.index:
		meshes.resize(data.index + 1)
	meshes[data.index] = mesh
	

func commit(data: GoshapeBuildData) -> void:
	var mesh := meshes[meshes.size() - 1]
	var instance := apply_mesh(data.parent, mesh)
	instances.append(instance)
	
	
func commit_colliders(data: GoshapeBuildData) -> void:
	if should_build_colliders():
		var collision_mesh := meshes[0]
		apply_collider(data.parent, collision_mesh)
	

func build_sets(path: GoshapePath) -> Array[MeshSet]:
	printerr("Not implemented")
	return []
	
	
func apply_mesh(parent: Node3D, new_mesh: ArrayMesh, name_tag := "Mesh") -> MeshInstance3D:
	if new_mesh == null:
		return
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = new_mesh
	mesh_node.name = "%s%s" % [new_mesh.resource_name, name_tag]
	commit_to_group(mesh_node)
	return SceneUtils.add_child(parent, mesh_node) as MeshInstance3D
		
		
func apply_collider(parent: Node3D, collision_mesh: ArrayMesh) -> StaticBody3D:
	if collision_mesh == null:
		return
	var collider_body := StaticBody3D.new()
	collider_body.name = "%sBody" % collision_mesh.resource_name
	collider_body.collision_layer = base_style.collision_layer
	SceneUtils.add_child(parent, collider_body)
	var collider_shape := CollisionShape3D.new()
	collider_shape.name = "%sCollider" % collision_mesh.resource_name
	collider_shape.shape = collision_mesh.create_trimesh_shape()
	SceneUtils.add_child(collider_body, collider_shape)
	collider_body.set_display_folded(true)
	commit_to_group(collider_shape)
	commit_to_group(collider_body)
	return collider_body
	
	
func get_build_jobs(data: GoshapeBuildData, offset: int) -> Array[GoshapeJob]:
	var result: Array[GoshapeJob] = []
	result.append(GoshapeJob.new(self, data, build, offset + 1))
	result.append(GoshapeJob.new(self, data, commit, offset + 2, GoshapeJob.Mode.Scene))
	if should_build_colliders():
		result.append(GoshapeJob.new(self, data, commit_colliders, offset + 10, GoshapeJob.Mode.Scene))
	return result
	
	
func commit_to_group(node: Node3D) -> void:
	if base_style.group_name != null and base_style.group_name.length() > 0:
		node.add_to_group(base_style.group_name, true)
		
	
func should_build_colliders() -> bool:
	return base_style != null and base_style.build_collider
