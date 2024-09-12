@tool
class_name GoshapeBuildData

var parent: Node3D
var path: GoshapePath
var index := 0

func clone() -> GoshapeBuildData:
	var result = GoshapeBuildData.new()
	result.parent = parent
	result.path = path
	result.index = index
	return result
