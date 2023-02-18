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
	

func build(host: Node3D, path: PathData) -> void:
	build_meshes(host, path)
	
	
func build_meshes(host: Node3D, path: PathData, dest_mesh: Mesh = null) -> void:
	meshsets = build_sets(path)
	mesh = MeshUtils.build_meshes(meshsets, dest_mesh)
	apply_mesh(host, mesh)
	if base_style.build_collider:
		apply_collider(host, mesh)
	

func build_sets(path: PathData) -> Array[MeshSet]:
	printerr("Not implemented")
	return []
	
	
func build_done(group: JobGroup) -> void:
	if group.output.size() < 1:
		printerr("No output")
		return
	var output_mesh = group.output[0] as ArrayMesh
	apply_mesh(host, output_mesh)
	apply_collider.call_deferred(host, output_mesh)
	
		
func apply_mesh(host: Node3D, new_mesh: ArrayMesh) -> void:
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = new_mesh
	mesh_node.name = "Mesh%s" % host.get_child_count()
	SceneUtils.add_child(host, mesh_node)
		
		
func apply_collider(host: Node3D, mesh: ArrayMesh) -> void:
	var collider_body = StaticBody3D.new()
	collider_body.name = "Collider%s" % host.get_child_count()
	collider_body.collision_layer = base_style.collision_layer
	SceneUtils.add_child(host, collider_body)
	var collider_shape = CollisionShape3D.new()
	collider_shape.name = "CollisionShape"
	collider_shape.shape = mesh.create_trimesh_shape()
	SceneUtils.add_child(collider_body, collider_shape)
