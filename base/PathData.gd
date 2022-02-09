tool
class_name PathData

var points := PoolVector3Array() setget set_points
var ups := PoolVector3Array() setget set_ups
var point_count: int setget ,get_point_count
var taper := 0.0
var curve: Curve3D


func _init(points = PoolVector3Array(), ups = PoolVector3Array()) -> void:
	self.points = points
	self.ups = ups
	
	
func set_points(value: PoolVector3Array):
	points = value
	
	
func set_ups(value: PoolVector3Array):
	ups = value
	
	
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
	
	
func duplicate():
	return get_script().new(points, ups)
