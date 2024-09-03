@tool
class_name ScatterCollection
extends ScatterSource
## Multiple scene item collections

## the scene objects (prefabs) to fetch
@export var sources: Array[ScatterSource] = []:
	set(value):
		sources = value
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


func instantiate(pick: int = -1) -> Node3D:
	if is_dirty:
		total_weight = 0
		for i in range(sources.size()):
			total_weight += 1 if i >= weights.size() else weights[i]
	if pick < 0:
		pick = randi_range(0, total_weight)
	else:
		pick = pick % total_weight
	var w := 0
	for i in range(sources.size()):
		w += 1 if i >= weights.size() else weights[i]
		if w >= pick:
			return sources[i].instantiate()
	return null


func has_resource() -> bool:
	return sources.size() > 0
