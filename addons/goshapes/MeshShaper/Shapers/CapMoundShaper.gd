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

enum MoundType { HILL, PEAK, STEPS, STRAIGHT, STEEP, ROUGH }
@export var mound_type: MoundType = MoundType.HILL:
	set(value):
		if mound_type != value:
			mound_type = value
			emit_changed()
			
			
func get_builder() -> ShapeBuilder:
	return CapMoundBuilder.new(self)
			
			
class CapMoundBuilder extends CapBuilder:
	
	var style: CapMoundShaper
	func _init(_style: CapMoundShaper):
		super._init(_style)
		style = _style
		
	func build_sets(path: PathData) -> Array[MeshSet]:
		var sets: Array[MeshSet] = []
		var center = PathUtils.get_path_center(path)
		center.y += style.height
		var iterations = clamp(style.iterations, 1, 16)
		for j in range(iterations):
			var path_a = PackedVector3Array();
			var path_b = PackedVector3Array()
			for i in range(path.point_count):
				var pa = lerp_mound_p(center, path.get_point(i), j, iterations, style.mound_type)
				var pb = lerp_mound_p(center, path.get_point(i), j + 1, iterations, style.mound_type)
				path_a.append(pa)
				path_b.append(pb)
			sets = MeshUtils.build_extruded_sets(path_a, path_b, sets)
		for set in sets:
			set.material = style.material
		return sets
		
	func lerp_mound_p(a: Vector3, b: Vector3, iteration: int, iterations: int, mound_type: MoundType) -> Vector3:
		var step = 1.0 / iterations * iteration
		var p = lerp(a, b, step)
		match mound_type:
			MoundType.HILL:
				p.y = lerp(a.y, b.y, step * step)
			MoundType.STEEP:
				p.y = lerp(a.y, b.y, step * step * step)
			MoundType.STEPS:
				if iteration < iterations - 1:
					step = 1.0 / iterations * floor(iteration / 2) * 2
				p.y = lerp(a.y, b.y, step)
			MoundType.PEAK:
				p.y = lerp(a.y, b.y, sin(PI * step * 0.5))
			MoundType.ROUGH:
				var t = sin(PI * step)
				p.y = lerp(a.y, b.y, lerp(step, get_randomish(b.x + b.y, b.z + b.y), t * t * t))
		return p
		
	func get_randomish(x: float, y: float) -> float:
		var ix = int(x * 1000.0)
		var iy = int(y * 1000.0)
		var seed = ix * 0x1f1f1f1f + iy * 0x3f3f3f3f
		seed = (seed ^ (seed >> 15)) * 0x45d9f3b
		seed = (seed ^ (seed >> 15)) * 0x45d9f3b
		seed = (seed ^ (seed >> 15))
		return float(seed & 0x7FFFFFFF) / 0x7FFFFFFF
