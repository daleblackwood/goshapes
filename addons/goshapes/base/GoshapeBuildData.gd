@tool
class_name GoshapeBuildData

var parent: Node3D
var path: GoshapePath
var rebuild := false
var index := 0

func duplicate() -> GoshapeBuildData:
	var result = GoshapeBuildData.new()
	result.parent = parent
	result.path = path
	result.rebuild = rebuild
	result.index = index
	return result
