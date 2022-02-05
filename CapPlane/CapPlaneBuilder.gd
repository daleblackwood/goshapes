tool
extends CapBuilder

func build(style, path: PathData):
	var points = to_vec2s(path.points)
	
	var gs = 1.0
	if style != null and style.grid_size > 0.0:
		gs = style.grid_size
	
	var pmin = points[0]
	var pmax = points[0]
	for p in points:
		pmin.x = min(p.x, pmin.x)
		pmin.y = min(p.y, pmin.y)
		pmax.x = max(p.x, pmax.x)
		pmax.y = max(p.y, pmax.y)

	var cols = floor((pmax.x - pmin.x) / gs) + 1
	var rows = floor((pmax.y - pmin.y) / gs) + 1
		
	var meshes = []
		
	for cy in range(rows):
		for cx in range(cols):
			var a = Vector2(cx * gs + pmin.x, cy * gs + pmin.y)
			var b = a + Vector2(gs, 0)
			var c = a + Vector2(gs, gs)
			var d = a + Vector2(0, gs)
			var corners = PoolVector2Array([a, b, c, d])
			var icount = inside_count(points, corners)
			if icount == 4:
				meshes.append(MeshUtils.make_cap(to_vec3s(corners)))
				continue
			#var corners3 = to_vec3s(corners)
			#meshes.append(MeshUtils.make_cap(corners3))
			var intersections = Geometry.intersect_polygons_2d(points, corners)
			for intersection in intersections:
				var cap_points = to_vec3s(intersection)
				meshes.append(MeshUtils.make_cap(cap_points))
			
	var set = MeshUtils.combine_sets(meshes)
	set.material = style.material
	return set

	
func inside_count(path: PoolVector2Array, points: PoolVector2Array) -> int:
	var result = 0
	for p in points:
		if Geometry.is_point_in_polygon(p, path):
			result += 1
	return result
	
	
func to_vec3s(arr: PoolVector2Array) -> PoolVector3Array:
	var point_count = arr.size()
	var result = PoolVector3Array()
	result.resize(point_count)
	for i in range(point_count):
		var v = Vector3(arr[i].x, 0, arr[i].y)
		result.set(i, v)
	return result
	
	
func to_vec2s(arr: PoolVector3Array) -> PoolVector2Array:
	var point_count = arr.size()
	var result = PoolVector2Array()
	result.resize(point_count)
	for i in range(point_count):
		result.set(i, Vector2(arr[i].x, arr[i].z))
	return result
	
