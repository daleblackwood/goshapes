@tool
class_name BottomShaper
extends Shaper
## A Shaper that draws the bottom (or base) of a path's geometry

## The depth the base should be drawn at
@export_range(0.0, 100.0, 0.2) var base_depth := 1.0:
	set(value):
		if base_depth != value:
			base_depth = value
			emit_changed()

## The material applied to the base geometry
@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()
			
			
var cap_shaper: CapShaper = null


func create_builders() -> Array[ShapeBuilder]:
	var using_cap_shaper := cap_shaper
	if using_cap_shaper == null:
		using_cap_shaper = CapFlatShaper.new()
	return [BottomShaperBuilder.new(self, using_cap_shaper)]
	

func get_order_offset() -> int:
	return 50
			
			
class BottomShaperBuilder extends ShapeBuilder:
	
	var style: BottomShaper
	var cap_shaper: CapShaper
	func _init(_style: BottomShaper, _cap_shaper: CapShaper):
		style = _style
		cap_shaper = _cap_shaper
	
	func build_sets(path: GoshapePath) -> Array[MeshSet]:
		var base_path = PathUtils.move_path_down(path, style.base_depth)
		var base_shaper = cap_shaper.duplicate()
		var cap_builders = base_shaper.get_builders()
		if cap_builders.size() < 1:
			return []
			
		if style.material != null:
			base_shaper.material = style.material
		var meshset = cap_builders[0].build(base_path)
		var vert_count = meshset.vert_count
		for i in range(vert_count):
			var n = meshset.normals[i]
			n.y = -n.y
			meshset.set_normal(i, n)
			
		var tri_count = meshset.tri_count / 3
		for i in range(tri_count):
			var a = meshset.tris[i * 3]
			var c = meshset.tris[i * 3 + 2]
			meshset.set_tri(i * 3, c)
			meshset.set_tri(i * 3 + 2, a)
			
		return [meshset]
