@tool
class_name MeshBuilder
extends ShapeBuilder
## The base type for all geometry shape builders
	
var mesh: ArrayMesh
var mesh_low: ArrayMesh
var child_mesh: MeshInstance3D
var tag := "Shape"
var base_style: MeshShaper

func _init(_style: MeshShaper) -> void:
	base_style = _style
	

func build(data: GoshapeBuildData) -> void:
	var meshsets = build_sets(data.path)
	mesh = MeshUtils.build_meshes(meshsets, null)
	

func commit(data: GoshapeBuildData) -> void:
	child_mesh = apply_mesh(data.parent, mesh)
	
	
func commit_colliders(data: GoshapeBuildData) -> void:
	if should_build_colliders():
		var collision_mesh = mesh_low if mesh_low != null else mesh
		apply_collider(data.parent, collision_mesh)
	

func build_sets(path: GoshapePath) -> Array[MeshSet]:
	printerr("Not implemented")
	return []
	
	
func apply_mesh(parent: Node3D, new_mesh: ArrayMesh, prefix := "Mesh") -> MeshInstance3D:
	if new_mesh == null:
		return
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = new_mesh
	mesh_node.name = "%s%s%s" % [prefix, tag, parent.get_child_count()]
	return SceneUtils.add_child(parent, mesh_node) as MeshInstance3D
		
		
func apply_collider(parent: Node3D, collision_mesh: ArrayMesh) -> void:
	if collision_mesh == null:
		return
	var collider_body = StaticBody3D.new()
	collider_body.name = "%sBody%s" % [tag, parent.get_child_count()]
	collider_body.collision_layer = base_style.collision_layer
	SceneUtils.add_child(parent, collider_body)
	var collider_shape = CollisionShape3D.new()
	collider_shape.name = "%sCollider%s" % [tag, parent.get_child_count()]
	collider_shape.shape = collision_mesh.create_trimesh_shape()
	SceneUtils.add_child(collider_body, collider_shape)
	
	
func get_build_jobs(data: GoshapeBuildData, offset: int) -> Array[GoshapeJob]:
	var result: Array[GoshapeJob] = []
	result.append(GoshapeJob.new(self, data, build, offset + 1, false))
	result.append(GoshapeJob.new(self, data, commit, offset + 2, true))
	if should_build_colliders():
		result.append(GoshapeJob.new(self, data, commit_colliders, offset + 10, true))
	return result
	
	
func should_build_colliders() -> bool:
	return base_style != null and base_style.build_collider
