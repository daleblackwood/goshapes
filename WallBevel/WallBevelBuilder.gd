tool
extends WallBuilder

func build(style, path: PathData):
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
	return meshset
