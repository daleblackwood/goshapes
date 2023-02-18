@tool
class_name PathData
## The object used to manipulate path points

var points := PackedVector3Array(): set = set_points
var ups := PackedVector3Array(): set = set_ups
var point_count: int: get = get_point_count
var taper := 0.0
var curve: Curve3D
var placement_mask = 0


func _init(points = PackedVector3Array(), ups = PackedVector3Array()) -> void:
	self.points = points
	self.ups = ups
	
	
func set_points(value: PackedVector3Array):
	points = value
	
	
func set_ups(value: PackedVector3Array):
	ups = value
	
	
func get_point(index: int) -> Vector3:
	if index < 0:
		return points[0]
	var imax = points.size() - 1
	if index > imax:
		return points[imax]
	return points[index]
	
	
func set_point(index: int, v: Vector3) -> void:
	if index < 0 or index >= points.size():
		return
	points.set(index, v)
	
	
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
	
	
func duplicate():
	return get_script().new(points, ups)
