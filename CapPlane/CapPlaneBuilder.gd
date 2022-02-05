tool
extends CapBuilder

func build(style, path: PathData):
	var gs = 1.0
	if style != null and style.grid_size > 0.0:
		gs = style.grid_size
		
	var path2d = PoolVector2Array()
	path2d.resize(path.point_count)
	for i in range(path.point_count):
		path2d
	
	var pmin = path.points[0]
	var pmax = path.points[0]
	for p in path.points:
		pmin.x = min(p.x, pmin.x)
		pmax.x = max(p.x, pmax.x)
		pmin.z = min(p.z, pmin.z)
		pmax.z = max(p.z, pmax.z)

	var cols = floor((pmax.x - pmin.x) / gs) + 1
	var rows = floor((pmax.z - pmin.z) / gs) + 1
		
	var meshes = []
		
	for cy in range(rows):
		for cx in range(cols):
			var a = Vector2(cx * gs + pmin.x, cy * gs + pmin.z)
			var b = a + Vector2(gs, 0)
			var c = a + Vector2(gs, gs)
			var d = a + Vector2(0, gs)
			var plane = Plane(
				Vector3(a.x, 100, a.y),
				Vector3(b.x, 100, b.y),
				Vector3(c.x, 100, c.y)
			)
			var clipped = Geometry.clip_polygon(path.points, plane)
			if clipped.size() > 0:
				meshes.append(MeshUtils.make_cap(clipped))
			#var d = a + Vector2(0, gs)
			#var corners = PoolVector2Array([a, b, c, d])
			#var icount = inside_count(points, corners)
			#if icount == 4:
			#	meshes.append(MeshUtils.make_cap(to_vec3s(corners)))
			#	continue
			#var corners3 = to_vec3s(corners)
			#meshes.append(MeshUtils.make_cap(corners3))
			#var intersections = Geometry.intersect_polygons_2d(points, corners)
			#for intersection in intersections:
			#	var cap_points = to_vec3s(intersection)
			#	meshes.append(MeshUtils.make_cap(cap_points))
			
	var set = MeshUtils.combine_sets(meshes)
	set.material = style.material
	return set

	
func inside_count(path: PoolVector2Array, points: PoolVector2Array) -> int:
	var result = 0
	for p in points:
		if Geometry.is_point_in_polygon(p, path):
			result += 1
	return result
