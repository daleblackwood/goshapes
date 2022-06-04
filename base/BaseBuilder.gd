@tool
extends BlockBuilder
class_name BaseBuilder

var cap_builder: CapBuilder
var base_depth = 0.0

func _init(cap_builder: CapBuilder, base_depth: float) -> void:
	self.cap_builder = cap_builder
	self.base_depth = base_depth
	
	
func build(style, path: PathData):
	var base_path = PathUtils.move_path_down(path, base_depth)
	var meshset = cap_builder.build(style, base_path)
	var vert_count = meshset.vert_count
	for i in vert_count:
		var n = meshset.normals[i]
		n.y = -n.y
		meshset.set_normal(i, n)
		
	var tri_count = meshset.tri_count / 3
	for i in tri_count:
		var a = meshset.tris[i * 3]
		var c = meshset.tris[i * 3 + 2]
		meshset.set_tri(i * 3, c)
		meshset.set_tri(i * 3 + 2, a)
	return meshset
	
