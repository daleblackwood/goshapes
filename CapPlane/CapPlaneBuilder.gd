tool
extends CapBuilder

func build(style, path: PathData):
	var gs := 1.0
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

	var coln = floor((pmax.x - pmin.x) / gs) + 2
	var rown = floor((pmax.z - pmin.z) / gs) + 2
		
	var meshes = []
	
	var cols = []
	for gx in range(coln):
		for gz in range(rown):
			var clipx = gx * gs + pmin.x
			var clipped = Geometry.clip_polygon(path.points, Plane(Vector3.LEFT, -clipx))
			if clipped.size() < 1:
				continue
			clipped = Geometry.clip_polygon(clipped, Plane(Vector3.RIGHT, clipx + gs))
			if clipped.size() < 1:
				continue
			var clipz = gz * gs + pmin.z
			clipped = Geometry.clip_polygon(clipped, Plane(Vector3.FORWARD, -clipz))
			if clipped.size() < 1:
				continue
			clipped = Geometry.clip_polygon(clipped, Plane(Vector3.BACK, clipz + gs))
			if clipped.size() < 1:
				continue
			meshes.append(MeshUtils.make_cap(clipped))
			
	var set = MeshUtils.combine_sets(meshes)
	set.material = style.material
	return set

	
func inside_count(path: PoolVector2Array, points: PoolVector2Array) -> int:
	var result = 0
	for p in points:
		if Geometry.is_point_in_polygon(p, path):
			result += 1
	return result
