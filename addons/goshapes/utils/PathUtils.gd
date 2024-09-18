@tool
class_name PathUtils
## Utilities that manipulate path data

const ROOT_2 = 1.41421356237

static func flatten_curve(curve: Curve3D) -> void:
	var point_count = curve.get_point_count()
	for i in range(point_count):
		var p = curve.get_point_position(i)
		p.y = 0.0
		curve.set_point_position(i, p)
		p = curve.get_point_in(i)
		p.y = 0
		curve.set_point_in(i, p)
		p = curve.get_point_out(i)
		p.y = 0
		curve.set_point_out(i, p)
		
		
static func remove_control_points(curve: Curve3D) -> void:
	for i in range(curve.get_point_count()):
		curve.set_point_in(i, Vector3.ZERO)
		curve.set_point_out(i, Vector3.ZERO)
	
	
static func twist_curve(curve: Curve3D, path_twists = PackedInt32Array()) -> void:
	var twist_count = 0 if path_twists == null else path_twists.size()
	var curve_point_count = curve.get_point_count()
	if twist_count > 0:
		if twist_count > 0:
			for i in range(curve_point_count):
				var twist_i = i if i < twist_count - 1 else twist_count - 1
				var twist = path_twists[twist_i]
				curve.set_point_tilt(i, twist / 180.0 * PI)
	else:
		for i in range(curve_point_count):
			curve.set_point_tilt(i, 0.0)
	
	
static func get_curve_center(curve: Curve3D) -> Vector3:
	var point_count = curve.get_point_count()
	var center = Vector3.ZERO
	for i in range(point_count):
		center += curve.get_point_position(i)
	return center / float(point_count)
	
	
static func move_curve(curve: Curve3D, offset: Vector3) -> void:
	var point_count := curve.get_point_count()
	var center := Vector3.ZERO
	for i in range(point_count):
		var p := curve.get_point_position(i)
		p += offset
		curve.set_point_position(i, p)
	
	
static func curve_to_points(curve: Curve3D, interpolate: int, inverted: bool) -> GoshapePath:
	var points := curve.tessellate(interpolate, 2)
	var ups := PackedVector3Array()
	ups.resize(points.size())
	ups.fill(Vector3.UP)
	var corners := PackedInt32Array()
	corners.resize(points.size())
	var ci = 0
	for i in range(points.size()):
		if points[i] == curve.get_point_position(ci):
			ci += 1
		corners[i] = max(0, ci - 1)
	var path = GoshapePath.new(points, ups, corners)
	if inverted:
		path.invert()
	return path
	
	
static func curve_to_path(curve: Curve3D, interpolate: int, inverted: bool, path_twists := PackedInt32Array()) -> GoshapePath:
	curve = curve.duplicate()
	var use_twists := path_twists != null and path_twists.size() > 0
	if use_twists:
		twist_curve(curve, path_twists)
	var result := curve_to_points(curve, interpolate, inverted)
	var length := 0.0
	result.ups.resize(result.point_count)
	for i in range(result.point_count):
		if not use_twists or i == 0:
			result.ups.set(i, Vector3.UP)
		else:
			var dif = result.points[i] - result.points[i - 1]
			length += dif.length()
			result.ups.set(i, curve.interpolate_baked_up_vector(length, true))
	return result
	

static func path_to_outline(path: GoshapePath, width: float) -> GoshapePath:
	var point_count := path.points.size()
	var point_total := point_count * 2
	var result = GoshapePath.new()
	result.points.resize(point_total)
	result.ups.resize(point_total)
	result.corners.resize(point_total)
	var dir_a := Vector3.FORWARD
	var dir_b := Vector3.FORWARD
	for i in range(point_count):
		if i > 0:
			dir_a = path.points[i] - path.points[i - 1]
			dir_a = dir_a.normalized()
		if i < point_count - 1:
			dir_b = (path.points[i + 1] - path.points[i]).normalized()
			dir_b = dir_b.normalized()
		if i == 0:
			dir_a = dir_b
		if i == point_count - 1:
			dir_b = dir_a
		var dir := ((dir_a + dir_b)).normalized()
		var up := path.get_up(i)
		var corner := path.get_corner(i)
		var p := path.points[i]
		var out := dir.cross(up)
		out *= lerp(ROOT_2, 1.0, dir_b.dot(dir_a))
		var a := p + out * width * 0.5
		var b := p - out * width * 0.5
		result.points.set(i, a)
		result.points.set(point_total - 1 - i, b)
		result.ups.set(i, up)
		result.ups.set(point_total - 1 - i, up)
		result.corners.set(i, corner)
		result.corners.set(point_total - 1 - i, corner)
	return result
	

static func round_path(path: GoshapePath, rounding_mode: PathOptions.RoundingMode, round_dist: float, interpolate: int = 0) -> GoshapePath:
	if interpolate < 1:
		interpolate = 1
	var iterations = interpolate
	var sub_dist = round_dist
	var result = path
	for i in range(iterations):
		result = round_path_it(result, rounding_mode, sub_dist)
		sub_dist /= PI
	return result
	
	
static func round_path_it(path: GoshapePath, rounding_mode: PathOptions.RoundingMode, round_dist: float) -> GoshapePath:
	var point_count = path.points.size()
	var points = PackedVector3Array()
	points.resize(point_count * 3)
	var ups = PackedVector3Array()
	ups.resize(point_count * 3)
	var corners = PackedInt32Array()
	corners.resize(point_count * 3)
	for i in range(point_count):
		var is_edge  := i == 0 or i == point_count-1
		var do_round := (rounding_mode == PathOptions.RoundingMode.Auto) or (rounding_mode == PathOptions.RoundingMode.Ignore_Edges and not is_edge)
		var rounding := round_dist * 0.5 if do_round else 0
		
		var p := path.points[i]
		var prev_i = i - 1 if i > 0 else point_count - 1
		var next_i = i + 1 if i < point_count - 1 else 0
		var prev := path.points[prev_i]
		var next := path.points[next_i]
		var a := move_point_towards(p, prev, rounding)
		var c := move_point_towards(p, next, rounding)
		var b = (a + c + p) / 3.0
		var ai = (point_count if i == 0 else i) * 3 - 1
		var bi = i * 3
		var ci = i * 3 + 1
		points.set(ai, a)
		points.set(bi, b)
		points.set(ci, c)
		ups.set(ai, path.get_up(prev_i))
		ups.set(bi, path.get_up(i))
		ups.set(ci, path.get_up(i))
		corners.set(ai, path.get_corner(prev_i))
		corners.set(bi, path.get_corner(i))
		corners.set(ci, path.get_corner(i))
	return GoshapePath.new(points, ups, corners)
	
	
static func move_point_towards(source: Vector3, dest: Vector3, distance: float) -> Vector3:
	var diff = dest - source
	diff *= 0.5
	if diff.length_squared() > distance * distance * 2.0:
		diff = diff.normalized() * distance
		return source + diff
	return source + diff * 0.66667
	
	
static func move_path(path: GoshapePath, offset: Vector3) -> GoshapePath:
	var point_count = path.points.size()
	var points = PackedVector3Array()
	points.resize(point_count)
	for i in range(point_count):
		var p = path.points[i]
		p += offset
		points[i] = p
	return GoshapePath.new(points, path.ups, path.corners)
	
	
static func get_closest_point_index(path: GoshapePath, v: Vector3) -> int:
	var closest = 0
	var closestsq = 100.0
	for i in range(path.point_count):
		var dsq = (path.get_point(i) - v).length_squared()
		if dsq > closestsq:
			continue
		closest = i
		closestsq = dsq
	return closest
	
	
static func get_closest_point(path: GoshapePath, v: Vector3) -> Vector3:
	var index = get_closest_point_index(path, v)
	return path.get_point(index)
	
	
static func move_path_down(path: GoshapePath, amount: float = 0.0) -> GoshapePath:
	return move_path_up(path, -amount)
	

static func move_path_up(path: GoshapePath, amount: float = 0.0) -> GoshapePath:
	var point_count = path.points.size()
	var up_count = path.ups.size()
	var result = PackedVector3Array()
	result.resize(point_count)
	for i in range(point_count):
		var up = Vector3.UP
		if i < up_count:
			up = path.ups[i]
		var p = path.points[i]
		p += up * amount
		result[i] = p
	return GoshapePath.new(result, path.ups)
	
	
static func cap_taper(a: Vector3, b: Vector3, width: float) -> Vector3:
	var right = (b - a).normalized()
	var out = right.cross(Vector3.UP)
	return a + out * width
	
	
static func invert(path: GoshapePath) -> GoshapePath:
	var result = path.duplicate()
	result.invert()
	return result
	
	
static func get_path_center(path: GoshapePath) -> Vector3:
	var point_count = path.points.size()
	var center = Vector3.ZERO
	for i in range(point_count):
		center += path.get_point(i)
	return center / float(point_count)
	
	
	
static func taper_path(path: GoshapePath, taper: float, clamp_opposite: bool = false) -> GoshapePath:
	var point_count = path.points.size()
	var result = PackedVector3Array()
	result.resize(point_count)
	for i in range(point_count):
		var a = path.points[i]
		var b = path.points[(i + 1) % point_count]
		var z = path.points[(i + point_count - 1) % point_count]
		var angleb = atan2(b.z - a.z, b.x - a.x);
		var anglea = atan2(a.z - z.z, a.x - z.x);
		var angledif = fmod(angleb - anglea + PI, PI * 2.0) - PI
		var taper_length = taper / cos(angledif * 0.5)
		var taper_angle = anglea + PI * 0.5 + angledif * 0.5
		var taper_vec = Vector3(
			cos(taper_angle) * taper_length, 
			0.0, 
			sin(taper_angle) * taper_length
		)
		result[i] = a + taper_vec
	return GoshapePath.new(result, path.ups)
	
	
static func bevel_path(path: GoshapePath, taper: float) -> PackedVector3Array:
	var point_count = path.points.size()
	var up_count = path.ups.size()
	var result = PackedVector3Array()
	result.resize(point_count * 2)
	for i in range(point_count):
		var a = path.points[i]
		var bp = path.points[(i + 1) % point_count]
		var right = (bp - a).normalized()
		var up = path.get_up(i)
		var forward = right.cross(up)
		result[i * 2] = a + forward * taper
		result[i * 2 + 1] = bp + forward * taper
	return result
	
	
static func split_path_by_corner(path: GoshapePath) -> Array[GoshapePath]:
	var corner_count := 0
	var prev_corner = -1
	var corner_sizes := PackedInt32Array()
	for corner in path.corners:
		if corner != prev_corner:
			corner_sizes.append(1)
			corner_count += 1
			prev_corner = corner
		else:
			corner_sizes.set(corner_count - 1, corner_sizes[corner_count - 1] + 1)
	var result: Array[GoshapePath] = []
	result.resize(corner_count)
	var corner_offset := 0
	for corner in range(corner_count):
		var point_count := corner_sizes[corner] + 1
		var cp := GoshapePath.new()
		cp.set_point_count(point_count)
		for i in range(point_count):
			var pi := (i + corner_offset) % path.point_count
			cp.points.set(i, path.get_point(pi))
			cp.ups.set(i, path.get_up(pi))
			cp.corners.set(i, 0)
		result[corner] = cp
		corner_offset += point_count - 1
	return result
	
	
static func duplicate_paths(paths: Array[GoshapePath]) -> Array[GoshapePath]:
	var result: Array[GoshapePath] = []
	result.resize(paths.size())
	for i in range(paths.size()):
		result[i] = paths[i].duplicate()
	return result
	
	
static func overlap_paths(paths: Array[GoshapePath], overlap: float) -> Array[GoshapePath]:
	var results := duplicate_paths(paths)
	for path in results:
		var a = path.get_point(0)
		var b = path.get_point(1)
		a += (a - b).normalized() * overlap
		path.points.set(0, a)
		a = path.get_point(path.point_count - 1)
		b = path.get_point(path.point_count - 2)
		a += (a - b).normalized() * overlap
		path.points.set(path.point_count - 1, a)
	return results
	
	
static func get_length(points: PackedVector3Array) -> float:
	var point_count = points.size()
	if point_count < 2:
		return 0.0
	var result = 0.0
	for i in range(1, point_count):
		var a = points[i - 1]
		var b = points[i]
		var dist = (a - b).length()
		result += dist
	return result
