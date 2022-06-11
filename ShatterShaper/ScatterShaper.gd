@tool
extends Shaper
class_name ScatterShaper

@export var object: PackedScene = null:
	set(value):
		if object != value:
			object = value
			emit_changed()
			
			
@export_range(0.0, 1.0) var density: float = 3.0:
	set(value):
		if density != value:
			density = value
			emit_changed()
			
			
@export_range(0.2, 10.0, 0.2) var spread: float = 3.0:
	set(value):
		if spread != value:
			spread = value
			emit_changed()
			
			
@export var seed: int = 0:
	set(value):
		if seed != value:
			seed = value
			emit_changed()
			
			
@export var place_on_ground: bool = true:
	set(value):
		if place_on_ground != value:
			place_on_ground = value
			emit_changed()
			
			
@export var random_angle: bool = true:
	set(value):
		if random_angle != value:
			random_angle = value
			emit_changed()
			
			
@export_range(0.0, 10.0) var scale_variance: float = 0.0:
	set(value):
		if scale_variance != value:
			scale_variance = value
			emit_changed()
			
			
@export_range(0.1, 5.0) var scale_multiplier: float = 1.0:
	set(value):
		if scale_multiplier != value:
			scale_multiplier = value
			emit_changed()
			
			
@export_range(0.0, 1.0) var evenness: float = 0.0:
	set(value):
		if evenness != value:
			evenness = value
			emit_changed()
			

func get_builder() -> ShapeBuilder:
	return ShatterBuilder.new(self)
	
			
class ShatterBuilder extends ShapeBuilder:
	
	var style: ScatterShaper
	func _init(_style: ScatterShaper):
		style = _style
		
		
	func build(host: Node3D, path: PathData) -> void:
		var rng = RandomNumberGenerator.new()
		rng.seed = style.seed
		var curve = path.curve
		var min_x = INF
		var max_x = -INF
		var min_z = INF
		var max_z = -INF
		for p in path.points:
			min_x = minf(min_x, p.x)
			max_x = maxf(max_x, p.x)
			min_z = minf(min_z, p.z)
			max_z = maxf(max_z, p.z)
		var inc = style.spread
		var density = style.density
		var object = style.object
		var place_on_ground = style.place_on_ground
		var random_angle = style.random_angle
		var scale_variance = style.scale_variance
		var scale_multiplier = style.scale_multiplier
		var evenness = style.evenness
		var polygon = PackedVector2Array()
		polygon.resize(path.point_count)
		for i in range(path.point_count):
			polygon.set(i, Vector2(path.points[i].x, path.points[i].z))
		print("inc ", inc, " density", density)
		var x = min_x
		while x < max_x:
			x += inc
			var z = min_z
			while z < max_z:
				z += inc
				var rand1 = rng.randf()
				var rand2 = rng.randf()
				var rand3 = rng.randf()
				if rand1 > density:
					continue
				var pos = Vector3(x, 0, z)
				pos.x += (1.0 - evenness) * (inc * rand2 - inc * 0.5)
				pos.z += (1.0 - evenness) * (inc * rand3 - inc * 0.5)
				if not Geometry2D.is_point_in_polygon(Vector2(pos.x, pos.z), polygon):
					continue
				if place_on_ground:
					var space = host.get_world_3d().direct_space_state
					var ray = PhysicsRayQueryParameters3D.new()
					ray.from = host.global_transform * Vector3(x, 1000, z)
					ray.to = host.global_transform * Vector3(x, -1000, z)
					var hit = space.intersect_ray(ray)
					if hit.has("position"):
						pos = host.global_transform.inverse() * hit.position
				else:
					pos.y = curve.get_closest_point(pos).y
				var inst = object.instantiate()
				inst.transform.origin = pos
				var basis = Basis()
				var angle = PI * 2.0 * rand2
				if random_angle:
					basis = basis.rotated(Vector3.UP, angle)
				var scale = scale_multiplier + rand3 * scale_variance * 2.0 - scale_variance
				basis = basis.scaled(Vector3.ONE * scale)
				inst.transform.basis = basis
				SceneUtils.add_child(host, inst)
		
