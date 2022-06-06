@tool
extends WallBuilder

func build(style, path: PathData):
	if not style is WallStyle:
		push_error("style must be WallStyle")
		return null
		
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
