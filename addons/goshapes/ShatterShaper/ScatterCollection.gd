@tool
class_name ScatterCollection
extends SceneSource
## Multiple scene item collections

## the scene objects (prefabs) to fetch
@export var prefabs: Array[PackedScene] = []:
	set(value):
		prefabs = value
		is_dirty = true
		emit_changed()
		

## the weights to bias which is selected
@export var weights: Array[int] = []:
	set(value):
		weights = value
		is_dirty = true
		emit_changed()
		
		
var is_dirty = false
var total_weight = 0


func get_resource(pick: int = -1) -> PackedScene:
	if is_dirty:
		total_weight = 0
		for i in range(prefabs.size()):
			total_weight += 1 if i >= weights.size() else weights[i]
	if pick < 0:
		pick = randi_range(0, total_weight)
	else:
		pick = pick % total_weight
	var w := 0
	for i in range(prefabs.size()):
		w += 1 if i >= weights.size() else weights[i]
		if w >= pick:
			return prefabs[i]
	return null


func has_resource() -> bool:
	return prefabs.size() > 0
