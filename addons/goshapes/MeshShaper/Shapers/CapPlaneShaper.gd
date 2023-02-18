@tool
class_name CapPlaneShaper
extends CapShaper
## A Shaper that draws a complex planed cap useful for sloping surfaces

## The size of the subdivision grid on the cap
@export_range(0.1, 10.0, 0.1) var grid_size: float = 1.0:
	set(value):
		if grid_size != value:
			grid_size = value
			emit_changed()
			
## An amount to raise in a mountainous fashion
@export_range(0.0, 100.0) var mound_rise: float = 0.0:
	set(value):
		if mound_rise != value:
			mound_rise = value
			emit_changed()
			
## Add prominanceness to the mound_rise
@export_range(0.0, 1.0) var mound_sharpness: float = 0.0:
	set(value):
		if mound_sharpness != value:
			mound_sharpness = value
			emit_changed()
			

func get_builder() -> ShapeBuilder:
	return CapPlaneBuilder.new(self)
			
			
class CapPlaneBuilder extends CapBuilder:
	
	var style: CapPlaneShaper
	func _init(_style: CapPlaneShaper):
		super._init(_style)
		style = _style
		
	func build_sets(path: PathData) -> Array[MeshSet]:
		var gs := 1.0 if not style.grid_size or style.grid_size == 0.0 else style.grid_size

		var points := get_cap_points(style, path)
		var point_count := points.size()
		
		var pmin := points[0]
		var pmax := points[0]
		for p in points:
			pmin.x = min(p.x, pmin.x)
			pmax.x = max(p.x, pmax.x)
			pmin.z = min(p.z, pmin.z)
			pmax.z = max(p.z, pmax.z)
		var coln: int = floor((pmax.x - pmin.x) / gs) + 2
		var rown: int = floor((pmax.z - pmin.z) / gs) + 2
		
		var sets: Array[MeshSet] = []
		
		var x_mins := float_array(rown)
		var x_maxs := float_array(rown)
		var z_mins := float_array(coln)
		var z_maxs := float_array(coln)
		for gx in range(coln):
			var clipx := gx * gs + pmin.x
			var col_clip = Geometry3D.clip_polygon(path.points, Plane(Vector3.LEFT, -clipx))
			if col_clip.size() < 1:
				continue
			col_clip = Geometry3D.clip_polygon(col_clip, Plane(Vector3.RIGHT, clipx + gs))
			if col_clip.size() < 1:
				continue
			var min_z := INF
			var max_z := -INF
			for p in col_clip:
				min_z = min(p.z, min_z)
				max_z = max(p.z, max_z)
			z_mins[gx] = min_z
			z_maxs[gx] = max_z
			var min_x := INF
			var max_x := -INF
			for gz in range(rown):
				var clipz := gz * gs + pmin.z
				var clipped := col_clip.duplicate()
				clipped = Geometry3D.clip_polygon(clipped, Plane(Vector3.FORWARD, -clipz))
				if clipped.size() < 1:
					continue
				clipped = Geometry3D.clip_polygon(clipped, Plane(Vector3.BACK, clipz + gs))
				if clipped.size() < 1:
					continue
				sets.append(MeshUtils.make_cap(clipped))
				for p in clipped:
					x_mins[gz] = min(p.x, x_mins[gz])
					x_maxs[gz] = max(p.x, x_maxs[gz])
				
		var meshset := MeshUtils.weld_sets(sets, gs * 0.5)
		meshset.material = style.material
		if style.mound_rise != 0.0:
			var v: Vector3;
			var fgx: float;
			var fgz: float;
			var gx: int;
			var gz: int;
			for i in range(meshset.vert_count):
				v = meshset.verts[i]
				fgx = (v.x - pmin.x) / gs
				gx = clamp(roundi(fgx), 0, coln - 1)
				if abs(fgx - gx) > 0.00001:
					continue
				fgz = (v.z - pmin.z) / gs
				gz = clamp(roundi(fgz), 0, rown - 1)
				if abs(fgz - gz) > 0.00001:
					continue
				v.y = get_point_y(v.x, x_mins[gz], x_maxs[gz], v.z, z_mins[gx], z_maxs[gx])
				meshset.set_vert(i, v)
		return [meshset]
		
	func flat_dist(a: Vector3, b: Vector3) -> float:
		var d = a - b
		return sqrt(d.x * d.x + d.z * d.z)
		
	func float_array(size: int) -> Array[float]:
		var result: Array[float] = []
		result.resize(size)
		result.fill(0.0)
		return result
		
	func get_point_y(x: float, min_x: float, max_x: float, z: float, min_z: float, max_z: float) -> float:
		return (interpolate_y(x, min_x, max_x) + interpolate_y(z, min_z, max_z)) * 0.5
		
	func interpolate_y(n: float, n_min: float, n_max: float) -> float:
		if n <= n_min:
			return 0.0
		if n >= n_max:
			return 0.0
		var pc = (n - n_min) / (n_max - n_min)
		var result = sin(pc * PI)
		if style.mound_sharpness > 0.0:
			var prom = pc * 2.0 if pc < 0.5 else (1.0 - pc) * 2.0
			prom = prom * prom * prom * prom
			result = lerp(result, prom, style.mound_sharpness)
		result *= style.mound_rise
		return 0.0 if is_nan(result) else result
