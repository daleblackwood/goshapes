@tool
class_name CapLineShaper
extends CapShaper
## A Shaper that draws the cap for a line for winding paths

func get_builder() -> ShapeBuilder:
	return CapLineBuilder.new(self)
			
			
class CapLineBuilder extends CapBuilder:
	
	var style: CapLineShaper
	func _init(_style: CapLineShaper):
		super._init(_style)
		style = _style
	
	
	func build_sets(path: PathData) -> Array[MeshSet]:
		var material = style.material
		var points = get_cap_points(style, path)
		var point_count = points.size()
		var sets: Array[MeshSet] = []
		if point_count < 2:
			return sets
			
		var width = (points[point_count - 1] - points[0]).length()

		var length = 0.0
		var line_points = point_count / 2
		for i in range(1, line_points):
			var a = points[i - 1]
			var b = points[i]
			var c = points[point_count - i]
			var d = points[point_count - i - 1]
			var dif = (b - a)
			var l = dif.length()
			var u_size = Vector2(length, length + l)
			var quad = MeshUtils.make_quad(b, a, d, c, u_size)
			quad.uvs = PackedVector2Array([
				Vector2(0, length + l),
				Vector2(0, length),
				Vector2(width, length + l),
				Vector2(width, length),
			])
			quad.normals = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
			
			var quads = split_quad(quad)
			for set in quads:
				sets.append(set)
			length += l
			
		var meshset = MeshUtils.weld_sets(sets)
		meshset.material = material
		
		return [meshset]
		
		
	func split_quad(quad: MeshSet) -> Array:
		return split_quad_four(quad)
		
		
	func split_quad_four(quad: MeshSet) -> Array:
		var sets: Array[MeshSet] = []
		var a = quad.clone()
		lerp_set(a, quad, 1, 0, 0.5)
		lerp_set(a, quad, 2, 0, 0.5)
		lerp_set(a, quad, 3, 1, 0.5)
		lerp_set(a, a, 3, 2, 0.5)
		sets.append(a)
		var b = quad.clone()
		lerp_set(b, quad, 0, 1, 0.5)
		lerp_set(b, quad, 3, 1, 0.5)
		lerp_set(b, quad, 2, 3, 0.5)
		lerp_set(b, b, 2, 0, 0.5)
		sets.append(b)
		var c = quad.clone()
		lerp_set(c, quad, 0, 2, 0.5)
		lerp_set(c, quad, 3, 2, 0.5)
		lerp_set(c, quad, 1, 0, 0.5)
		lerp_set(c, c, 1, 3, 0.5)
		sets.append(c)
		var d = quad.clone()
		lerp_set(d, quad, 1, 3, 0.5)
		lerp_set(d, quad, 2, 3, 0.5)
		lerp_set(d, quad, 0, 2, 0.5)
		lerp_set(d, d, 0, 1, 0.5)
		sets.append(d)
		return sets
		
		
	func split_quad_length(quad: MeshSet) -> Array[MeshSet]:
		var sets: Array[MeshSet] = []
		var a = quad.clone()
		lerp_set(a, quad, 2, 0, 0.5)
		lerp_set(a, quad, 3, 1, 0.5)
		sets.append(a)
		var b = quad.clone()
		lerp_set(b, quad, 0, 2, 0.5)
		lerp_set(b, quad, 1, 3, 0.5)
		sets.append(b)
		return sets
		
		
	func lerp_set(set: MeshSet, ref: MeshSet, a: int, b: int, amount: float) -> void:
		set.set_vert(a, ref.verts[a].lerp(ref.verts[b], amount))
		set.set_uv(a, ref.uvs[a].lerp(ref.uvs[b], amount))
		set.set_normal(a, ref.normals[a].lerp(ref.normals[b], amount))
