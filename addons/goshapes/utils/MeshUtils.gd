@tool
class_name MeshUtils
## Utilities that manipulate mesh data


static func make_cap(points: PackedVector3Array) -> MeshSet:
	var point_count = points.size()
	
	var set = MeshSet.new()
	set.set_vert_count(point_count)
	set.verts = points
	
	var tri_points = PackedVector2Array()
	tri_points.resize(point_count)
	
	for i in range(point_count):
		set.set_uv(i, Vector2(points[i].x, points[i].z))
		set.set_normal(i, Vector3.UP)
		tri_points[i] = Vector2(points[i].x, points[i].z)
	
	set.tris = Geometry2D.triangulate_polygon(tri_points)
	return set
	

static func fill_concentric_paths(paths: Array[PathData], forward_uvs: bool = true) -> MeshSet:
	var ms = MeshSet.new()
	
	var segment_count = paths.size()
	var reference = paths[0] if forward_uvs else paths[segment_count - 1]
	var point_count = reference.point_count
	var distances = reference.get_distances(2.0)
	var uv_scale = 1.0
	
	var quad_count = point_count * segment_count
	var vert_count = quad_count * 4
	var index_count = quad_count * 6
	ms.set_counts(vert_count, index_count)
	
	var normals = PackedVector3Array()
	normals.resize(quad_count)
	
	# generate quads
	var dist = 0.0
	for i in range(1, segment_count):
		var top_path = paths[i - 1]
		var bottom_path = paths[i]
		var dl = (top_path.points[0] - bottom_path.points[0]).length() * uv_scale
		var top_dist = dist
		dist += dl
		for j in range(0, point_count):
			var quad_i = (i * point_count + j)
			var jn = (j + 1) % point_count
			var tl = top_path.get_point(j)
			var tr = top_path.get_point(jn)
			var bl = bottom_path.get_point(j)
			var br = bottom_path.get_point(jn)
			
			var vi = quad_i * 4
			ms.verts.set(vi    , tl)
			ms.verts.set(vi + 1, tr)
			ms.verts.set(vi + 2, bl)
			ms.verts.set(vi + 3, br)
			
			var da = distances[j]
			var db = distances[jn]
			ms.uvs.set(vi    , Vector2(da, top_dist))
			ms.uvs.set(vi + 1, Vector2(db, top_dist))
			ms.uvs.set(vi + 2, Vector2(da, dist))
			ms.uvs.set(vi + 3, Vector2(db, dist))
			
			var ti = quad_i * 6
			ms.tris.set(ti    , vi)
			ms.tris.set(ti + 1, vi + 1)
			ms.tris.set(ti + 2, vi + 3)
			ms.tris.set(ti + 3, vi + 2)
			ms.tris.set(ti + 4, vi + 0)
			ms.tris.set(ti + 5, vi + 3)
			
			var normal = -(tr - tl).cross(bl - tl)
			if normal.length_squared() > 0.001:
				normal = normal.normalized()
			else:
				normal = Vector3.UP
			normals.set(quad_i, normal)
	
	# smooth normals		
	for seg_i in range(1, segment_count):
		for point_i in range(0, point_count):
			var i = seg_i * point_count + point_i
			var normal = normals[i]
			var tn = normal if i < point_count else normals[i - point_count]
			var bn = normal if i >= quad_count - point_count else normals[i + point_count]
			var ln = normals[seg_i * point_count + (point_i + point_count - 1) % point_count]
			var rn = normals[seg_i * point_count + (point_i + point_count + 1) % point_count]
			var vi = i * 4
			ms.normals.set(vi    , (tn + ln + normal) / 3.0)
			ms.normals.set(vi + 1, (tn + rn + normal) / 3.0)
			ms.normals.set(vi + 2, (bn + ln + normal) / 3.0)
			ms.normals.set(vi + 3, (bn + rn + normal) / 3.0)
	return ms

	
static func make_quad(tl: Vector3, tr: Vector3, bl: Vector3, br: Vector3, u_size: Vector2 = Vector2.ZERO) -> MeshSet:
	var normal = -(tr - tl).cross(bl - tl).normalized()
	var set = MeshSet.new()
	set.verts = PackedVector3Array([tl, tr, bl, br])
	if u_size != Vector2.ZERO:
		set.uvs = PackedVector2Array([
			Vector2(u_size.x, tl.y),
			Vector2(u_size.y, tr.y),
			Vector2(u_size.x, bl.y),
			Vector2(u_size.y, br.y)
		])
	elif false:
		set.uvs = PackedVector2Array([
			Vector2(0, 0),
			Vector2(1, 0),
			Vector2(0, 1),
			Vector2(1, 1)
		])
	else:
		set.uvs = vert_uv(set.verts, normal)
	set.normals = PackedVector3Array([normal, normal, normal, normal])
	set.tris = PackedInt32Array([0, 1, 3, 2, 0, 3])
	return set
	
	
static func make_tri(a: Vector3, b: Vector3, c:Vector3) -> MeshSet:
	var normal = -(b - a).cross(c - a)
	var set = MeshSet.new()
	set.verts = PackedVector3Array([a, b, c])
	if false:
		set.uvs = PackedVector2Array([
			Vector2(0, 0),
			Vector2(1, 0),
			Vector2(1, 1)
		])
	else:
		set.uvs = vert_uv(set.verts, normal)
	set.normals = PackedVector3Array([normal, normal, normal])
	set.tris = PackedInt32Array([0, 2, 1])
	return set
	
	
static func vert_uv(points: PackedVector3Array, normal: Vector3) -> PackedVector2Array:
	normal.y = 0
	var dot = normal.normalized().dot(Vector3.RIGHT)
	var use_x = abs(dot) < 0.5
	var point_count = points.size()
	var result = PackedVector2Array()
	result.resize(point_count)
	for i in range(point_count):
		var v = points[i]
		var x = v.x if use_x else v.z
		result.set(i, Vector2(x, v.y))
	return result
	
	
static func flip_normals(meshset: MeshSet) -> MeshSet:
	var result = meshset.clone()
	var vert_vount = result.vert_count
	for i in range(vert_vount):
		result.set_normal(i, -result.verts[i])
	return result
	
	
static func calc_mesh_height(mesh: Mesh, scale: float = 1.0) -> float:
	if mesh == null:
		return 0.0
	var min_y = 0.0
	for i in range(mesh.get_surface_count()):
		var arr = mesh.surface_get_arrays(i)
		var verts = arr[ArrayMesh.ARRAY_VERTEX]
		for vert in verts:
			if vert.y < min_y:
				min_y = vert.y
	return min_y * -scale
	

static func wrap_mesh_to_path(meshset: MeshSet, path: PathData, close: bool) -> MeshSet:
	var points = path.points
	var point_count = points.size()
	if point_count < 2:
		return MeshSet.new()
	# close if needed
	if close:
		points.append(points[0])
		point_count += 1
	# calculate directions for segments
	var lengths: Array[float] = []
	lengths.resize(point_count)
	var path_length = 0.0
	for i in range(point_count):
		var n = (i + 1) % point_count
		var dif = points[n] - points[i]
		var section_length = dif.length()
		lengths[i] = section_length
		path_length += section_length
	
	var set = mesh_clone_to_length(meshset, path_length)
	# wrap combined verts around path
	var vert_count = set.verts.size()
	for i in range(vert_count):
		var v = set.verts[i]
		var ai = 0
		var len_start = 0.0
		var len_end = 0.0
		for j in point_count:
			ai = j
			len_end = len_start + lengths[j]
			if v.x < len_end:
				break
			len_start = len_end
		ai = clampi(ai, 0, point_count - 1)
		var bi = ai + 1
		bi = clampi(bi, 0, point_count - 1)
		var pa = points[ai]
		var pb = points[bi]
		var ua = path.get_up(ai)
		var ub = path.get_up(bi)
		var pc = 0.0 if len_end == len_start else (v.x - len_start) / (len_end - len_start)
		var up = ua.lerp(ub, pc)
		var right = (pb - pa).normalized()
		var out = right.cross(up)
		var down = -up
		var orig_x = v.x - len_start
		var xt = orig_x * right
		var pt = pa + orig_x * right - v.y * down + v.z * out
		set.set_vert(i, pt)
		var n = set.normals[i]
		n = (n.x * right + n.y * up + n.z * out).normalized()
		set.set_normal(i, n)
	return set
	
	
static func mesh_clone_to_length(meshset: MeshSet, path_length: float) -> MeshSet:
	# calculate segment sizes
	var min_x = INF
	var max_x = -INF
	for v in meshset.verts:
		if v.x < min_x:
			min_x = v.x
		if v.x > max_x:
			max_x = v.x
	var mesh_length = max_x - min_x
	var seg_count = get_segment_count_for_path(path_length, mesh_length)
	if seg_count < 1:
		seg_count = 1
	var seg_length = path_length / seg_count
	var x_multi = seg_length / mesh_length
	# tile verts along x, build sets
	var sets: Array[MeshSet] = []
	for i in range(seg_count):
		var set = meshset.clone()
		var vert_count = set.verts.size()
		var start_x = i * seg_length
		for j in vert_count:
			var v = set.verts[j]
			v.x = start_x + v.x * x_multi
			set.set_vert(j, v)
			var uv = set.uvs[j]
			uv.x += float(i)
			set.set_uv(j, uv)
		sets.append(set)
	var set = combine_sets(sets)
	return set
	
	
static func get_segment_count_for_path(path_length: float, segment_length: float) -> int:
	return int(round(path_length / segment_length))
	

static func weld_sets(sets: Array[MeshSet], threshhold: float = 0.01) -> MeshSet:
	var merged = combine_sets(sets)
	
	var theshholdsq = threshhold * threshhold
	
	var tri_count = merged.tris.size()
	var trimap: Array[int] = []
	trimap.resize(tri_count)
	
	var vert_i = 0
	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var normals: Array[Vector3] = []
	
	var merged_vert_count = merged.verts.size()
	for i in range(merged_vert_count):
		var ivert = merged.verts[i]
		var remap = -1
		for j in vert_i:
			var jvert = verts[j]
			var difsq = jvert.distance_squared_to(ivert)
			if difsq < theshholdsq:
				remap = j
				break
		if remap < 0:
			verts.append(ivert)
			normals.append(merged.normals[i])
			uvs.append(merged.uvs[i])
			trimap[i] = vert_i
			vert_i += 1
		else:
			normals[remap] += merged.normals[i]
			trimap[i] = remap
			
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	var set = MeshSet.new()
	set.verts = PackedVector3Array(verts)
	set.uvs = PackedVector2Array(uvs)
	set.normals = PackedVector3Array(normals)
	set.set_tri_count(tri_count)
	
	for i in range(tri_count):
		var value = merged.tris[i]
		set.set_tri(i, trimap[value])
	
	return merged
	
	
static func smooth_mesh(meshset: MeshSet) -> MeshSet:
	var theshholdsq = 0.1
	var vert_count = meshset.get_vert_count()
	var normals = PackedVector3Array(meshset.normals);
	for i in range(vert_count):
		var ivert = meshset.verts[i]
		var remap = -1
		for j in range(0, i):
			var jvert = meshset.verts[j]
			var difsq = jvert.distance_squared_to(ivert)
			if difsq < theshholdsq:
				remap = j
				break
		if remap >= 0:
			var merged = normals[i] + normals[remap]
			normals.set(i, merged)
			normals.set(remap, merged)
			
	for i in range(vert_count):
		normals.set(i, normals[i].normalized())
	meshset.normals = normals
	return meshset
	
	
static func offset_mesh(meshset: MeshSet, offset: Vector3) -> MeshSet:
	var result = meshset.clone()
	var vert_count = meshset.vert_count
	for i in range(vert_count):
		var v = result.verts[i]
		v += offset
		result.set_vert(i, v)
	return result
			
			
static func combine_sets(sets: Array[MeshSet]) -> MeshSet:
	var tri_count = 0
	var vert_count = 0
	for set in sets:
		tri_count += set.tris.size()
		vert_count += set.verts.size()
		
	var result = MeshSet.new()
	result.set_counts(vert_count, tri_count)
	
	var tri_i = 0
	var vert_i = 0
	var vert_offset = 0
	
	for set in sets:
		if not set is MeshSet:
			push_error("merging sets need to be mesh sets")
			return null
		var set_vert_count = set.verts.size()
		for i in range(set_vert_count):
			result.set_vert(vert_i, set.verts[i])
			result.set_uv(vert_i, set.uvs[i])
			result.set_normal(vert_i, set.normals[i])
			vert_i += 1
			
		var set_tri_count = set.tris.size()
		for i in range(set_tri_count):
			result.set_tri(tri_i, set.tris[i] + vert_offset)
			tri_i += 1
			
		vert_offset += set_vert_count
		
	return result
	
	
static func scale_mesh(meshset: MeshSet, new_scale: float) -> MeshSet:
	var result = meshset.clone()
	var vert_count = meshset.verts.size()
	var verts = PackedVector3Array(meshset.verts)
	verts.resize(vert_count)
	for i in range(vert_count):
		var v = meshset.verts[i]
		verts[i] = v * new_scale
	result.verts = verts
	return result
	
	
static func taper_mesh(meshset: MeshSet, path: PathData, taper: float) -> MeshSet:
	var center = PathUtils.get_path_center(path)
	var result = meshset.clone()
	var vert_count = meshset.verts.size()
	var verts = PackedVector3Array(meshset.verts)
	verts.resize(vert_count)
	for i in range(vert_count):
		var v = meshset.verts[i]
		var p = PathUtils.get_closest_point(path, v)
		var t = (v.y - p.y) * taper
		var dir = v - center
		dir.y = 0.0
		dir = dir.normalized()
		verts[i] = v - t * dir
	result.verts = verts
	return result
	
	
static func mesh_to_sets(mesh: Mesh) -> Array[MeshSet]:
	var surface_count = mesh.get_surface_count()
	var result: Array[MeshSet] = []
	result.resize(surface_count)
	for i in range(surface_count):
		var meshset = MeshSet.new()
		var arr = mesh.surface_get_arrays(i)
		meshset.verts = arr[ArrayMesh.ARRAY_VERTEX]
		meshset.normals = arr[ArrayMesh.ARRAY_NORMAL]
		meshset.uvs = arr[ArrayMesh.ARRAY_TEX_UV]
		meshset.tris = arr[ArrayMesh.ARRAY_INDEX]
		result[i] = meshset
	return result
	
	
static func build_meshes(meshsets: Array[MeshSet], mesh: ArrayMesh = null) -> ArrayMesh:
	for meshset in meshsets:
		mesh = build_mesh(meshset, mesh)
	return mesh
	
	
static func build_mesh(meshset: MeshSet, mesh: ArrayMesh = null) -> ArrayMesh:
	if mesh == null:
		mesh = ArrayMesh.new()
	if meshset.vert_count > 0:
		var arr = []
		arr.resize(ArrayMesh.ARRAY_MAX)
		var verts = PackedVector3Array(meshset.verts)
		if verts.size() < meshset.vert_count:
			printerr("Incorrect vert count")
		arr[ArrayMesh.ARRAY_VERTEX] = verts
		var normals = PackedVector3Array(meshset.normals)
		if normals.size() < meshset.vert_count:
			normals.resize(meshset.vert_count)
		arr[ArrayMesh.ARRAY_NORMAL] = normals
		var uvs = PackedVector2Array(meshset.uvs)
		if uvs.size() < meshset.vert_count:
			uvs.resize(meshset.vert_count)
		arr[ArrayMesh.ARRAY_TEX_UV] = uvs
		arr[ArrayMesh.ARRAY_INDEX] = PackedInt32Array(meshset.tris)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if meshset.material:
		var surf_idx = mesh.get_surface_count() - 1
		mesh.surface_set_material(surf_idx, meshset.material)
	return mesh
	

static func append_mesh(base_mesh: ArrayMesh, appendage: ArrayMesh) -> void:
	var surface_count = appendage.get_surface_count()
	for i in range(surface_count):
		var arr = appendage.surface_get_arrays(i)
		var mat = appendage.surface_get_material(i)
		base_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var surf_idx = base_mesh.get_surface_count() - 1
		base_mesh.surface_set_material(surf_idx, mat)
