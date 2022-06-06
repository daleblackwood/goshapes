@tool
extends CapBuilder

func build(style, path: PathData):
	if not style is CapStyle:
		push_error("style must be CapStyle")
		return null
		
	var points = get_cap_points(style, path)
	var set = MeshUtils.make_cap(points)
	set.material = style.material
	return set
