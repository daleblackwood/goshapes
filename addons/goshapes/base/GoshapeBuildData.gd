@tool
class_name GoshapeBuildData

var parent: Node3D
var path: GoshapePath
var rebuild := false
var index := 0
var owner: Object


func duplicate() -> GoshapeBuildData:
	var result = GoshapeBuildData.new()
	result.parent = parent
	result.path = path
	result.rebuild = rebuild
	result.index = index
	result.owner = owner
	return result
	
	
func get_owner_id() -> int:
	var result = parent.get_instance_id()
	if owner != null:
		result += owner.get_instance_id()
	return result
