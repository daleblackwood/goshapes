tool
extends WallBuilder

func build(style, path: PathData):
	if not style:
		return null

	var ref_mesh = style.mesh as Mesh
	var surface_count = ref_mesh.get_surface_count()
	var materials = []
	if style.materials:
		materials = style.materials.duplicate()
	elif surface_count > 0 and ref_mesh.surface_get_material(0):
		materials.resize(surface_count)
		for i in surface_count:
			materials[i] = ref_mesh.surface_get_material(i)
	var scale = style.scale
	var closed = style.closed
	
	if not ref_mesh:
		return null
	
	var material_count = materials.size()
		
	var point_count = path.points.size()
	if point_count < 2:
		return null
		
	var meshsets = MeshUtils.mesh_to_sets(ref_mesh)
	var meshset_count = meshsets.size()
	for i in meshset_count:
		var meshset = meshsets[i]
		meshset = MeshUtils.scale_mesh(meshset, scale)
		meshset = MeshUtils.wrap_mesh_to_path(meshset, path, closed)
		meshset = MeshUtils.taper_mesh(meshset, path, path.taper)
		if material_count > 0:
			meshset.material = materials[i % material_count]
		meshsets[i] = meshset
	return meshsets
