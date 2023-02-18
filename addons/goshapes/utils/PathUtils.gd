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
	var point_count = curve.get_point_count()
	var center = Vector3.ZERO
	for i in range(point_count):
		var p = curve.get_point_position(i)
		p += offset
		curve.set_point_position(i, p)
	
	
static func curve_to_points(curve: Curve3D, interpolate: int, inverted: bool) -> PathData:
	var points = curve.tessellate(interpolate, 2)
	var path = PathData.new(points)
	if inverted:
		path = invert(path)
	return path
	
	
static func curve_to_path(curve: Curve3D, interpolate: int, inverted: bool, path_twists = PackedInt32Array()) -> PathData:
	curve = curve.duplicate()
	var use_twists = path_twists != null
	if use_twists:
		twist_curve(curve, path_twists)
	var curved_path = curve_to_points(curve, interpolate, inverted)
	var point_count = curved_path.point_count
	var points = PackedVector3Array()
	points.resize(point_count)
	var ups = PackedVector3Array()
	ups.resize(point_count)
	var length = 0.0
	for i in range(point_count):
		points[i] = curved_path.get_point(i)
		if not use_twists or i == 0:
			ups[i] = Vector3.UP
		else:
			var dif = points[i] - points[i - 1]
			length += dif.length()
			ups[i] = curve.interpolate_baked_up_vector(length, true)
	return PathData.new(points, ups)
	

static func path_to_outline(path: PathData, width: float) -> PathData:
	var point_count = path.points.size()
	var ups_count = path.ups.size()
	var point_total = point_count * 2
	var path_points = PackedVector3Array()
	path_points.resize(point_total)
	var path_ups = PackedVector3Array()
	path_ups.resize(point_total)
	var dir_a = Vector3.FORWARD
	var dir_b = Vector3.FORWARD
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
		var dir = ((dir_a + dir_b)).normalized()
		var up = path.get_up(i)
		var p = path.points[i]
		var out = dir.cross(up)
		#out *= max(1.0, ROOT_2 - dir_b.dot(dir_a))
		out *= lerp(ROOT_2, 1.0, dir_b.dot(dir_a))
		var a = p + out * width * 0.5
		var b = p - out * width * 0.5
		path_points[i] = a
		path_points[point_total - 1 - i] = b
		path_ups[i] = up
		path_ups[point_total - 1 - i] = up
	return PathData.new(path_points, path_ups)
	

static func round_path(path: PathData, round_dist: float, interpolate: int = 0) -> PathData:
	if interpolate < 1:
		interpolate = 1
	var iterations = interpolate + 1
	var sub_dist = round_dist
	var result = path
	for i in range(iterations):
		result = round_path_it(result, sub_dist)
		sub_dist /= PI
	return result
	
	
static func round_path_it(path: PathData, round_dist: float) -> PathData:
	var point_count = path.points.size()
	var points = PackedVector3Array()
	points.resize(point_count * 2)
	var ups = PackedVector3Array()
	ups.resize(point_count * 2)
	for i in range(point_count):
		var p = path.points[i]
		var prev = path.points[i - 1 if i > 0 else point_count - 1]
		var next = path.points[i + 1 if i < point_count - 1 else 0]
		var a = move_point_towards(p, prev, round_dist * 0.5)
		var b = move_point_towards(p, next, round_dist * 0.5)
		points.set(i * 2, a)
		points.set(i * 2 + 1, b)
		ups.set(i * 2, path.ups[i])
		ups.set(i * 2 + 1, path.ups[i])
	return PathData.new(points, ups)
	
	
static func move_point_towards(source: Vector3, dest: Vector3, distance: float) -> Vector3:
	var diff = dest - source
	diff *= 0.5
	if diff.length_squared() > distance * distance * 2.0:
		diff = diff.normalized() * distance
		return source + diff
	return source + diff * 0.5
	
	
static func move_path(path: PathData, offset: Vector3) -> PathData:
	var point_count = path.points.size()
	var result = PackedVector3Array()
	result.resize(point_count)
	for i in range(point_count):
		var p = path.points[i]
		p += offset
		result[i] = p
	return PathData.new(result, path.ups)
	
	
static func get_closest_point_index(path: PathData, v: Vector3) -> int:
	var closest = 0
	var closestsq = 100.0
	for i in range(path.point_count):
		var dsq = (path.get_point(i) - v).length_squared()
		if dsq > closestsq:
			continue
		closest = i
		closestsq = dsq
	return closest
	
	
static func get_closest_point(path: PathData, v: Vector3) -> Vector3:
	var index = get_closest_point_index(path, v)
	return path.get_point(index)
	
	
static func move_path_down(path: PathData, amount: float = 0.0) -> PathData:
	return move_path_up(path, -amount)
	

static func move_path_up(path: PathData, amount: float = 0.0) -> PathData:
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
	return PathData.new(result, path.ups)
	
	
static func cap_taper(a: Vector3, b: Vector3, width: float) -> Vector3:
	var right = (b - a).normalized()
	var out = right.cross(Vector3.UP)
	return a + out * width
	
	
static func invert(path: PathData) -> PathData:
	var point_count = path.points.size()
	var result_points = PackedVector3Array()
	result_points.resize(point_count)
	var result_ups = PackedVector3Array()
	result_ups.resize(point_count)
	for i in range(point_count):
		var index = point_count - 1 - i
		result_points[i] = path.get_point(index)
		result_ups[i] = path.get_up(index)
	return PathData.new(result_points, result_ups)
	
	
static func get_path_center(path: PathData) -> Vector3:
	var point_count = path.points.size()
	var center = Vector3.ZERO
	for i in range(point_count):
		center += path.get_point(i)
	return center / float(point_count)
	
	
	
static func taper_path(path: PathData, taper: float, clamp_opposite: bool = false) -> PathData:
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
	return PathData.new(result, path.ups)
	
	
static func bevel_path(path: PathData, taper: float) -> PackedVector3Array:
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
