@tool
class_name CapMoundShaper
extends CapShaper
## A Shaper that draws the cap (or top) of a path's geometry	

## The height of the mound
@export_range(-50, 50.0, 0.1) var height: float = 1.0:
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
			
@export var height_map: Texture2D = null:
	set(value):
		if height_map != value:
			height_map = value
			emit_changed()
			
@export_range(0.01, 10.0) var height_map_frequency: float = 1.0:
	set(value):
		if height_map_frequency != value:
			height_map_frequency = value
			emit_changed()
			
@export_range(0.01, 10.0) var height_map_multiplier: float = 1.0:
	set(value):
		if height_map_multiplier != value:
			height_map_multiplier = value
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
		var mid = PathUtils.get_path_center(path)
		mid.y += style.height
		var iterations = clamp(style.iterations, 1, 16)
		var height_img = null if not style.height_map else style.height_map.get_image()
		var point_count = path.point_count
		var paths: Array[PathData] = []
		for j in range(iterations + 1):
			var points = PackedVector3Array();
			points.resize(point_count)
			for i in range(point_count):
				var p = lerp_mound_p(mid, path.get_point(i), j, iterations, style.mound_type, height_img, style.height_map_frequency, style.height_map_multiplier)
				points.set(i, p)
			paths.append(PathData.new(points))
		var ms = MeshUtils.fill_concentric_paths(paths, false)
		ms.material = style.material
		return [ms]
		
	func lerp_mound_p(mid: Vector3, b: Vector3, iteration: int, iterations: int, mound_type: MoundType, height_img: Image, height_freq: float, height_multi: float) -> Vector3:
		var step = 1.0 / iterations * iteration
		var p = lerp(mid, b, step)
		match mound_type:
			MoundType.HILL:
				p.y = lerp(mid.y, b.y, step * step)
			MoundType.STEEP:
				p.y = lerp(mid.y, b.y, step * step * step)
			MoundType.STEPS:
				if iteration < iterations - 1:
					step = 1.0 / iterations * floor(iteration / 2) * 2
				p.y = lerp(mid.y, b.y, step)
			MoundType.PEAK:
				p.y = lerp(mid.y, b.y, sin(PI * step * 0.5))
			MoundType.ROUGH:
				var t = sin(PI * step)
				p.y = lerp(mid.y, b.y, lerp(step, get_randomish(b.x + b.y, b.z + b.y), t * t * t))
		if height_img and iteration < iterations - 1:
			var pscale = height_img.get_size()
			var pix = height_img.get_size()
			pix.x = image_ord(p.x * height_freq, pix.x)
			pix.y = image_ord(p.z * height_freq, pix.y)
			var height_color = height_img.get_pixelv(pix)
			var height_value = height_color.r
			p.y += (height_value * 2.0 - 1.0) * (mid.y - b.y) * height_multi
		return p
		
	func get_randomish(x: float, y: float) -> float:
		var ix = int(x * 1000.0)
		var iy = int(y * 1000.0)
		var seed = ix * 0x1f1f1f1f + iy * 0x3f3f3f3f
		seed = (seed ^ (seed >> 15)) * 0x45d9f3b
		seed = (seed ^ (seed >> 15)) * 0x45d9f3b
		seed = (seed ^ (seed >> 15))
		return float(seed & 0x7FFFFFFF) / 0x7FFFFFFF
		
	static func image_ord(n: float, dim: int) -> int:
		var r = fmod(n, dim)
		if r < 0:
			r += dim
		return r
