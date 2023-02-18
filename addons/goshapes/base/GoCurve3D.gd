@tool
extends Curve3D
class_name GoCurve3D

## An extension on Curve3D that skips certain updates and allows further manipulation

var edited_point: int = 0
var updating = false

func set_point_position(idx: int, position: Vector3):
	if not updating:
		edited_point = idx
	super.set_point_position(idx, position)
	

func emit_changed():
	if updating:
		return
	super.emit_changed()
	
