@tool
extends CapShaper
class_name CapPlaneShaper

			
@export var grid_size: float = 1.0:
	set(value):
		if grid_size != value:
			grid_size = value
			emit_changed()
			

func get_builder() -> ShapeBuilder:
	return CapPlaneBuilder.new(self)
			
			
class CapPlaneBuilder extends CapBuilder:
	
	var style: CapPlaneShaper
	func _init(_style: CapPlaneShaper):
		super._init(_style)
		style = _style
		
	func build_sets(path: PathData) -> Array:
		var gs := 1.0
		if style != null and style.grid_size > 0.0:
			gs = style.grid_size
			
		var points = get_cap_points(style, path)
		var point_count = points.size()
			
		var path2d = PackedVector2Array()
		path2d.resize(point_count)
		for i in range(point_count):
			path2d
		
		var pmin = points[0]
		var pmax = points[0]
		for p in points:
			pmin.x = min(p.x, pmin.x)
			pmax.x = max(p.x, pmax.x)
			pmin.z = min(p.z, pmin.z)
			pmax.z = max(p.z, pmax.z)

		var coln = floor((pmax.x - pmin.x) / gs) + 2
		var rown = floor((pmax.z - pmin.z) / gs) + 2
			
		var meshes = []
		
		var cols = []
		for gx in range(coln):
			for gz in range(rown):
				var clipx = gx * gs + pmin.x
				var clipped = Geometry3D.clip_polygon(path.points, Plane(Vector3.LEFT, -clipx))
				if clipped.size() < 1:
					continue
				clipped = Geometry3D.clip_polygon(clipped, Plane(Vector3.RIGHT, clipx + gs))
				if clipped.size() < 1:
					continue
				var clipz = gz * gs + pmin.z
				clipped = Geometry3D.clip_polygon(clipped, Plane(Vector3.FORWARD, -clipz))
				if clipped.size() < 1:
					continue
				clipped = Geometry3D.clip_polygon(clipped, Plane(Vector3.BACK, clipz + gs))
				if clipped.size() < 1:
					continue
				meshes.append(MeshUtils.make_cap(clipped))
				
		var meshset = MeshUtils.combine_sets(meshes)
		meshset.material = style.material
		
		return [meshset]
