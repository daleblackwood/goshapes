@tool
class_name PathData
## The object used to manipulate path points

var points := PackedVector3Array()
var ups := PackedVector3Array()
var point_count: int: get = get_point_count
var taper := 0.0
var curve: Curve3D
var placement_mask = 0


func _init(points = PackedVector3Array(), ups = PackedVector3Array()) -> void:
	self.points = points
	self.ups = ups
	
	
func get_point(index: int) -> Vector3:
	if index < 0:
		return points[0]
	var imax = points.size() - 1
	if index > imax:
		return points[imax]
	return points[index]
	
	
func get_point_count() -> int:
	return points.size()
	
	
func get_up(index: int) -> Vector3:
	var imax = ups.size() - 1
	if imax < 0:
		return Vector3.UP
	if index < 0:
		return ups[0]
	if index > imax:
		return ups[imax]
	return ups[index]
	
	
func get_distances(scale: float = 1.0, offset: float = 0.0) -> PackedFloat32Array:
	var length = 0.0
	var count = points.size()
	var lengths: Array[float] = []
	lengths.resize(count)
	for i in range(1, count):
		var a = points[i - 1]
		var b = points[i]
		var l = (a - b).length()
		length += l
		lengths[i] = l
	var scaled_length = roundf(length * scale)
	var applied_scale = length / scaled_length;
	var result = PackedFloat32Array()
	result.resize(count)
	var distance = offset
	for i in range(1, count):
		distance += lengths[i % count] * applied_scale
		result[i] = distance
	return result
	
	
func duplicate():
	return get_script().new(points, ups)
