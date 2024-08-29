@tool
class_name WallCurveShaper
extends WallShaper
## A Shaper that draws a simple wall around the path
		
## The height to make the wall
@export_range(0.0, 100.0, 0.2) var height = 1.0:
	set(value):
		if height != value:
			height = value
			emit_changed()

## Set the curve for the wall			
@export var curve: Curve = Curve.new():
	set(value):
		curve = value
		emit_changed()
		
## The taper to apply to the curve
@export_range(-50.0, 50.0, 0.2) var taper = 1.0:
	set(value):
		if taper != value:
			taper = value
			emit_changed()
			
## The material to draw on the wall edge
@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()
			

func get_builder() -> ShapeBuilder:
	return WallCurveBuilder.new(self)
			
			
class WallCurveBuilder extends WallBuilder:
	
	var style: WallCurveShaper
	func _init(_style: WallCurveShaper):
		super._init(_style)
		style = _style
	
	func build_sets(path: PathData) -> Array[MeshSet]:
		if not style.curve:
			style.curve = Curve.new()
			style.curve.min_value = 0
			style.curve.max_value = 1
			style.curve.bake_resolution = 10
			style.curve.point_count = 2
			style.curve.set_point_offset(0, 1.0)
			style.curve.set_point_value(0, 1.0)
		var meshset = make_walls(
			path, 
			style.curve,
			style.height
		)
		meshset.material = style.material
		return [meshset]
		
		
	static func make_walls(path: PathData, curve: Curve, height: float) -> MeshSet:
		var iterations = curve.bake_resolution
		var step_n = 1.0 / float(iterations)
		var step_y = height * step_n
			
		var paths: Array[PathData] = []
		paths.resize(iterations)
		for i in range(iterations):
			paths[i] = PathUtils.move_path_down(path, step_y * i)	
			
		for i in range(iterations):
			var out = curve.sample(clampf(float(i) / float(iterations - 1), 0.0, 1.0))
			paths[i] = PathUtils.taper_path(paths[i], out * height)	
		
		var combined = MeshUtils.fill_concentric_paths(paths)
		# set the first-ring normals to up
		for i in range(path.point_count * 4):
			combined.normals.set(i, Vector3.UP)
		return combined
