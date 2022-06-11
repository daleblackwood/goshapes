@tool
extends WallShaper
class_name WallBevelShaper

@export_range(0.0, 100.0, 0.2) var height = 1.0:
	set(value):
		if height != value:
			height = value
			emit_changed()
	
@export_range(0, 10.0, 0.2) var bevel = 0.0:
	set(value):
		if bevel != value:
			bevel = value
			emit_changed()
	
@export_range(0.0, 100.0, 0.2) var taper = 0.0:
	set(value):
		if taper != value:
			taper = value
			emit_changed()
			
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
	
	func build_sets(path: PathData) -> Array:
		var height = style.height
		var taper = style.taper
		var bevel = style.bevel
		var material = style.material
		var meshset = MeshUtils.make_walls(
			path, 
			height, 
			taper, 
			bevel
		)
		meshset.material = material
		
		return [meshset]

