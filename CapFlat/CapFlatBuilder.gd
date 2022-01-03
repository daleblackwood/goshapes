tool
extends CapBuilder

func build(style, path: PathData):
	var set = MeshUtils.make_cap(path.points)
	set.material = style.material
	return set
