extends BlockBuilder
class_name CapBuilder


func get_cap_points(style, path: PathData) -> PoolVector3Array:
	if style.conform_to_wall and style.wall_style != null and style.wall_style.has_method("get_mesh"):
		var mesh = style.wall_style.get_mesh() as Mesh
		var scale = 1.0
		if style.wall_style.has_method("get_scale"):
			scale = style.wall_style.get_scale()
		var points = mesh_to_cap_points(mesh, path, scale)
		return points
	return path.points

	
func mesh_to_top_points(mesh: Mesh) -> PoolVector3Array:
	var top_points = []
	var verts = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for v in verts:
		if abs(v.y) > 0.001:
			continue
		if abs(v.z) > 0.1:
			continue
		top_points.append(v)
	top_points.sort_custom(self, "sort_on_x")
	return PoolVector3Array(top_points)
	
	
func sort_on_x(a, b) -> bool:
	return a.x < b.x
		
	
func mesh_to_cap_points(mesh: Mesh, path: PathData, scale: float) -> PoolVector3Array:
	var result = PoolVector3Array()
	var top_points = mesh_to_top_points(mesh)
	var meshset = MeshUtils.MeshSet.new()
	var vert_count = top_points.size()
	meshset.set_vert_count(vert_count)
	for i in vert_count:
		meshset.set_vert(i, top_points[i])
	meshset = MeshUtils.scale_mesh(meshset, scale)
	var outmesh = MeshUtils.wrap_mesh_to_path(meshset, path, true)
	return outmesh.verts
