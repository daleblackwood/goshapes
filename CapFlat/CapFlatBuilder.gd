@tool
extends CapBuilder

func build(style, path: PathData):
	var points = get_cap_points(style, path)
	var set = MeshUtils.make_cap(points)
	set.material = style.material
	return set
