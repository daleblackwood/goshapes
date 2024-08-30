@tool
class_name WallMeshShaper
extends WallShaper
## A Shaper that wraps repeating mesh geometry around the path

## The mesh to repeat around the path (repeats along the x-axis)
@export var mesh: Mesh: 
	set(value):
		if mesh != value:
			mesh = value
			emit_changed()
	
## The scale to apply to each mesh segment	
@export_range(0.1, 10.0, 0.1) var scale = 1.0:
	set(value):
		if scale != value:
			scale = value
			emit_changed()
		
## Causes the path to close between the first and last point
@export var closed = true:
	set(value):
		if closed != value:
			closed = value
			emit_changed()
			

## The material to apply to the generated mesh
@export var material: Material:
	set(value):
		if material != value:
			material = value
			emit_changed()
			

func get_builder() -> ShapeBuilder:
	return WallMeshBuilder.new(self)
	
			
class WallMeshBuilder extends WallBuilder:
	
	var style: WallMeshShaper
	func _init(_style: WallMeshShaper):
		super._init(_style)
		style = _style

	func build_sets(path: PathData) -> Array[MeshSet]:
		var ref_mesh = style.mesh as Mesh
		if not ref_mesh:
			return []
			
		var surface_count = ref_mesh.get_surface_count()
		var materials = []
		if style.material != null:
			materials = [style.material]
		elif surface_count > 0 and ref_mesh.surface_get_material(0):
			materials.resize(surface_count)
			for i in range(surface_count):
				materials[i] = ref_mesh.surface_get_material(i)
		var scale = style.scale
		var closed = style.closed
		
		var material_count = materials.size()
			
		var point_count = path.points.size()
		if point_count < 2:
			return []
			
		var meshsets = MeshUtils.mesh_to_sets(ref_mesh)
		var meshset_count = meshsets.size()
		for i in range(meshset_count):
			var meshset = meshsets[i]
			meshset = MeshUtils.scale_mesh(meshset, scale)
			meshset = MeshUtils.wrap_mesh_to_path(meshset, path, closed)
			meshset = MeshUtils.taper_mesh(meshset, path, path.taper)
			if material_count > 0:
				meshset.material = materials[i % material_count]
			meshsets[i] = meshset
		return meshsets
