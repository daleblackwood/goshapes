@tool
class_name MeshBuilder
extends ShapeBuilder
## The base type for all geometry shape builders
	
var meshsets: Array[MeshSet]
var mesh: ArrayMesh
var mesh_name := "Mesh"
var base_style: MeshShaper

func _init(_style: MeshShaper) -> void:
	base_style = _style
	

func build(host: Node3D, path: GoshPath) -> void:
	self.host = host
	build_meshes(host, path)
	

func commit() -> void:
	apply_mesh(host, mesh)
	
	
func commit_colliders() -> void:
	if base_style.build_collider:
		apply_collider(host, mesh)
		
	
func build_meshes(host: Node3D, path: GoshPath, dest_mesh: Mesh = null) -> void:
	meshsets = build_sets(path)
	mesh = MeshUtils.build_meshes(meshsets, dest_mesh)
	

func build_sets(path: GoshPath) -> Array[MeshSet]:
	printerr("Not implemented")
	return []
	
	
func apply_mesh(host: Node3D, new_mesh: ArrayMesh) -> void:
	if new_mesh == null:
		return
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = new_mesh
	mesh_node.name = "Mesh%s" % host.get_child_count()
	SceneUtils.add_child(host, mesh_node)
		
		
func apply_collider(host: Node3D, mesh: ArrayMesh) -> void:
	if mesh == null:
		return
	var collider_body = StaticBody3D.new()
	collider_body.name = "Collider%s" % host.get_child_count()
	collider_body.collision_layer = base_style.collision_layer
	SceneUtils.add_child(host, collider_body)
	var collider_shape = CollisionShape3D.new()
	collider_shape.name = "CollisionShape"
	collider_shape.shape = mesh.create_trimesh_shape()
	SceneUtils.add_child(collider_body, collider_shape)
