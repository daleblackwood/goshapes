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
	

static func make_walls(path: PathData, height: float, taper: float = 0.0, bevel: float = 0.0) -> MeshSet:
	var sets: Array[MeshSet] = []
	var top_path = path;
	if bevel > 0.0:
		var bevel_path = PathUtils.taper_path(top_path, bevel)
		bevel_path = PathUtils.move_path_down(bevel_path, bevel)
		build_extruded_sets(top_path.points, bevel_path.points, sets)
		top_path = bevel_path
	var bottom_path = PathUtils.move_path_down(top_path, height - bevel)
	if taper != 0.0:
		bottom_path = PathUtils.taper_path(bottom_path, taper)
	build_extruded_sets(top_path.points, bottom_path.points, sets)
	var set = weld_sets(sets)
	return set
	
	
static func make_walls_tapered(path: PathData, height: float, taper: float = 0.0) -> MeshSet:
	var sets: Array[MeshSet] = []
	var bottom_path = PathUtils.taper_path(path, taper)
	bottom_path = PathUtils.move_path(bottom_path, Vector3.DOWN * height)
	build_extruded_sets(path.points, bottom_path.points, sets)
	var set = combine_sets(sets)
	return set
	

# slow bevel function for later user
#static func make_walls_bevelled(path: PathData, height: float, taper: float = 0.0, bevel: float = 0.0, bevel_stages: int = 0) -> MeshSet:
#	var point_count = path.points.size()
#	var up_count = path.ups.size()
#
#	var sets = []
#	var bevel_dir = 1.0 if height >= 0.0 else -1.0
#
#	var top_path = path
#	if bevel_stages > 0 and bevel > 0.0:
#		var current_bevel = 0.0
#		var bevel_ratio = 1.0 / float(bevel_stages)
#		var bevel_inc = bevel_ratio * bevel
#		for i in range(bevel_stages):
#			var pc = cos((i + 1) * PI) * 0.5 + 0.5
#			current_bevel = pc * bevel - current_bevel
#			var bottom_points = PathUtils.bevel_path(top_points, current_bevel)
#			bottom_points = PathUtils.move_path(bottom_points, Vector3.DOWN * bevel_inc)
#			build_tapered_sets(top_points, bottom_points, sets)
#			top_points = bottom_points
#
#	var bottom_points = PathUtils.bevel_path(top_points, taper)
#	bottom_points = PathUtils.move_path(bottom_points, Vector3.DOWN * (height - taper))
#	build_tapered_sets(top_points, bottom_points, sets)
#
#	var set = combine_sets(sets)
#	return set
	
	
static func build_tapered_sets(points: PackedVector3Array, bevelled_points: PackedVector3Array, sets: Array[MeshSet] = []) -> Array[MeshSet]:
	var point_count = points.size()
	
	for i in range(point_count):
		var tl = points[i]
		var tr = points[(i + 1) % point_count]
		var bl = bevelled_points[i * 2]
		var br = bevelled_points[(i * 2 + 1) % (point_count * 2)]
		var brn = bevelled_points[(i * 2 + 2) % (point_count * 2)]
		sets.append(make_quad(tl, tr, bl, br))
		sets.append(make_tri(tr, br, brn))
		
	return sets
	
	
static func build_extruded_sets(points: PackedVector3Array, extruded_points: PackedVector3Array, sets: Array[MeshSet] = []) -> Array[MeshSet]:
	var point_count = points.size()
	
	var length = 0.0
	for i in range(point_count):
		var tl = points[i]
		var tr = points[(i + 1) % point_count]
		var tdif = (tr - tl)
		tdif.y = 0
		var length_add = tdif.length()
		var u_size = Vector2(length, length + length_add)
		length += length_add
		var bl = extruded_points[i]
		var br = extruded_points[(i + 1) % point_count]
		sets.append(make_quad(tl, tr, bl, br, u_size))
		
	return sets

	
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
			trimap[i] = remap
	
	var set = MeshSet.new()
	set.verts = PackedVector3Array(verts)
	set.uvs = PackedVector2Array(uvs)
	set.normals = PackedVector3Array(normals)
	set.set_tri_count(tri_count)
	
	for i in range(tri_count):
		var value = merged.tris[i]
		set.set_tri(i, trimap[value])
	
	return merged
	
	
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
