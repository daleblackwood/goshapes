@tool
class_name CapMoundShaper
extends CapShaper
## A Shaper that draws the cap (or top) of a path's geometry	

## The height of the mound
@export_range(0.1, 10.0, 0.1) var height: float = 1.0:
	set(value):
		if height != value:
			height = value
			emit_changed()
			
@export_range(1, 16, 1) var iterations: int = 3:
	set(value):
		if iterations != value:
			iterations = value
			emit_changed()
			
			
func get_builder() -> ShapeBuilder:
	return CapMoundBuilder.new(self)
			
			
class CapMoundBuilder extends CapBuilder:
	
	var style: CapMoundShaper
	func _init(_style: CapMoundShaper):
		super._init(_style)
		style = _style
		
	func build_sets(path: PathData) -> Array[MeshSet]:
		return build_sets_2(path)

	func build_sets_1(path: PathData) -> Array[MeshSet]:
		var sets: Array[MeshSet] = []
		var top_path = path;
		var center = PathUtils.get_path_center(path)
		center.y += style.height
		var center_points = PackedVector3Array()
		for i in range(top_path.point_count):
			center_points.append(center)
		sets = MeshUtils.build_extruded_sets(center_points, top_path.points, sets)
		for set in sets:
			set.material = style.material
		return sets
		
	func build_sets_2(path: PathData) -> Array[MeshSet]:
		var sets: Array[MeshSet] = []
		var center = PathUtils.get_path_center(path)
		var paths: Array[PathData] = []
		var iterations = 1 if not style else style.iterations
		for i in range(iterations + 1):
			var subpath = path.duplicate()
			var pc = 1.0 - (float(i) / float(iterations))
			for j in range(subpath.point_count):
				var p = subpath.get_point(j).lerp(center, pc)
				p.y = pc * style.height
				subpath.set_point(j, p)
			paths.append(subpath)
		for i in range(1, paths.size(), 1):
			var pa = paths[i - 1]
			var pb = paths[i]
			sets = MeshUtils.build_extruded_sets(pb.points, pa.points, sets)
		for set in sets:
			set.material = style.material
		return sets
