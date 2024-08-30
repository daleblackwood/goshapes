@tool
class_name WallBevelShaper
extends WallShaper
## A Shaper that draws a simple wall around the path
		
## The height to make the wall
@export_range(0.0, 100.0, 0.1) var height = 1.0:
	set(value):
		if height != value:
			height = value
			emit_changed()

## Create a bevel around the wall edge	
@export_range(0, 10.0, 0.1) var bevel = 0.0:
	set(value):
		if bevel != value:
			bevel = value
			emit_changed()

## Creates a tapered edge
@export_range(0.0, 100.0, 0.1) var taper = 0.0:
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
	return WallBevelBuilder.new(self)
			
			
class WallBevelBuilder extends WallBuilder:
	
	var style: WallBevelShaper
	func _init(_style: WallBevelShaper):
		super._init(_style)
		style = _style
	
	func build_sets(path: PathData) -> Array[MeshSet]:
		var height = style.height
		var taper = style.taper
		var bevel = style.bevel
		var material = style.material
		var meshset = make_walls(path, height, taper, bevel)
		meshset.material = material
		return [meshset]

	
	static func make_walls(path: PathData, height: float, taper: float, bevel: float) -> MeshSet:
		var meshsets: Array[MeshSet] = []
		var paths: Array[PathData] = [path]
		var top_path = path;
		if bevel > 0.0:
			var bevel_path = PathUtils.taper_path(top_path, bevel)
			bevel_path = PathUtils.move_path_down(bevel_path, bevel)
			paths.append(bevel_path)
			top_path = bevel_path
		var bottom_path = PathUtils.move_path_down(top_path, height - bevel)
		if taper != 0.0:
			bottom_path = PathUtils.taper_path(bottom_path, taper)
		paths.append(bottom_path)
		
		var combined = MeshUtils.fill_concentric_paths(paths)
		# set the first-ring normals to up
		for i in range(path.point_count * 4):
			combined.normals.set(i, Vector3.UP)
		return combined
