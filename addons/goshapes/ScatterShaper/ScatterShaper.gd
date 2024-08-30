@tool
class_name ScatterShaper
extends Shaper
## Scatters objects throughout the shape

# An upper limit for instance counts for protection
const INSTANCE_CAP = 2000

var watcher_scene_source := ResourceWatcher.new(emit_changed)

## The object to scatter about
@export var scene_source: SceneSource = null:
	set(value):
		if scene_source != value:
			scene_source = value
			watcher_scene_source.watch(scene_source)
			emit_changed()
			

## How densely to populate the area with the objects
@export_range(0.0, 1.0) var density: float = 3.0:
	set(value):
		if density != value:
			density = value
			emit_changed()
			
			
## How far to spread the objects apart
@export_range(0.5, 10.0, 0.25) var spread: float = 3.0:
	set(value):
		if spread != value:
			spread = value
			emit_changed()
			
		
## A seed to feed the randomiser	
@export var seed: int = 0:
	set(value):
		if seed != value:
			seed = value
			emit_changed()
			
			
## Causes objects to be placed on underlying ground
@export var place_on_ground: bool = true:
	set(value):
		if place_on_ground != value:
			place_on_ground = value
			emit_changed()
			

## How much to conform the object to the ground angle		
@export_range(0.0, 1.0) var ground_angle_conformance: float = 0.0:
	set(value):
		if ground_angle_conformance != value:
			ground_angle_conformance = value
			emit_changed()


## Rotates the objects randomly around up		
@export var random_angle: bool = true:
	set(value):
		if random_angle != value:
			random_angle = value
			emit_changed()
			
	
var watcher_noise := ResourceWatcher.new(emit_changed)
		
## Allows a noise texture to be used instead of random seed
@export var noise: Noise:
	set(value):
		if noise != value:
			noise = value
			watcher_noise.watch(noise)
			emit_changed()
			

## Random differences in scale up to this theshhold	
@export_range(0.0, 10.0) var scale_variance: float = 0.0:
	set(value):
		if scale_variance != value:
			scale_variance = value
			emit_changed()
			
			
## Scales all generated objects
@export_range(0.1, 5.0) var scale_multiplier: float = 1.0:
	set(value):
		if scale_multiplier != value:
			scale_multiplier = value
			emit_changed()
			
		
## Higher values place objects more evenly	
@export_range(0.0, 1.0) var evenness: float = 0.0:
	set(value):
		if evenness != value:
			evenness = value
			emit_changed()


## Physics layers to ignore when placing objects			
@export_flags_3d_physics var collision_layer: int = 0:
	set(value):
		if collision_layer != value:
			collision_layer = value
			emit_changed()
			
			
func _init():
	if not scene_source:
		scene_source = ScatterItem.new()
	watcher_noise.watch(noise)
			

func get_builder() -> ShapeBuilder:
	return ShatterBuilder.new(self)
	
			
class ShatterBuilder extends ShapeBuilder:
	
	var style: ScatterShaper
	func _init(_style: ScatterShaper):
		style = _style


	func _conform_basis_y_to_normal(basis: Basis, normal: Vector3, conformance: float) -> Basis:
		conformance = clamp(conformance, 0.0, 1.0)
		if conformance == 0.0:
			return basis
			
		var current_y := basis.y.normalized()
		var  target_y :=  normal.normalized()

		var rotation_axis = current_y.cross(target_y)
		var   dot_product = current_y.dot(target_y)

		var rotation_angle : float

		# Handle parallel and opposite vectors
		if rotation_axis.length_squared() < 1e-6:
				if dot_product > 0.9999:
						# Vectors are nearly identical; no rotation needed
						return basis
				else:
						# Vectors are opposite; choose an arbitrary perpendicular axis
						rotation_axis = basis.x.normalized()
						rotation_angle = PI
		else:
				rotation_axis = rotation_axis.normalized()
				rotation_angle = acos(clamp(dot_product, -1.0, 1.0))

		var     rotation_quat := Quaternion(rotation_axis, rotation_angle)
		var interpolated_quat := Quaternion().slerp(rotation_quat, conformance)

		var rotated_basis := Basis(interpolated_quat) * basis

		return rotated_basis


	func build(host: Node3D, path: PathData) -> void:
		if not style.scene_source or not style.scene_source.has_resource():
			printerr("No scene(s) attached to ScatterShaper.")
			return
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
		var place_on_ground = style.place_on_ground
		var ground_angle_conformance := style.ground_angle_conformance
		var random_angle = style.random_angle
		var scale_variance = style.scale_variance
		var scale_multiplier = style.scale_multiplier
		var evenness = style.evenness
		var noise = style.noise
		var polygon = PackedVector2Array()
		polygon.resize(path.point_count)
		for i in range(path.point_count):
			polygon.set(i, Vector2(path.points[i].x, path.points[i].z))
		var x = min_x
		var instances = 0
		var collision_layer = style.collision_layer
		var placement_mask = path.placement_mask
		while x < max_x:
			x += inc
			var z = min_z
			while z < max_z:
				z += inc
				if instances > INSTANCE_CAP:
					printerr("Exceeded %d scatter instance cap" % INSTANCE_CAP)
					return
				var r_inst = rng.randi()
				var r_density = rng.randf()
				var r_x = rng.randf()
				var r_z = rng.randf()
				var r_angle = rng.randf()
				var r_scale = rng.randf()
				var pos = Vector3(x, 0, z)
				pos.x += (1.0 - evenness) * (inc * r_x - inc * 0.5)
				pos.z += (1.0 - evenness) * (inc * r_z - inc * 0.5)
				var normal := Vector3.UP
				if noise != null:
					r_density = clampf(1.0 + noise.get_noise_2d(pos.x, pos.y) * 0.5, 0.0, 1.0)
				if r_density > density:
					continue
				if not Geometry2D.is_point_in_polygon(Vector2(pos.x, pos.z), polygon):
					continue
				if place_on_ground:
					var space = host.get_world_3d().direct_space_state
					var ray = PhysicsRayQueryParameters3D.new()
					ray.from = host.global_transform * Vector3(pos.x, 1000, pos.z)
					ray.to = host.global_transform * Vector3(pos.x, -1000, pos.z)
					ray.collision_mask = 0xFF & (~collision_layer)
					var hit = space.intersect_ray(ray)
					if hit.has("collider"):
						normal = hit.normal
						if placement_mask > 0 and ((1 << placement_mask) & (1 << hit.collider.collision_layer)) == 0:
							continue
						pos = host.global_transform.inverse() * hit.position
					elif placement_mask > 0:
						continue
				else:
					pos.y = curve.get_closest_point(pos).y
				var object = style.scene_source.get_resource()
				var object_name = ResourceUtils.get_type(object)
				var inst = object.instantiate()
				instances += 1
				inst.name = "%s%d" % [object_name, instances]
				inst.transform.origin = pos
				if collision_layer > 0 and inst is CollisionObject3D:
					inst.collision_layer = collision_layer
				var basis = Basis()
				var angle = PI * 2.0 * r_angle
				if random_angle:
					basis = basis.rotated(Vector3.UP, angle)
				if place_on_ground:
					basis = _conform_basis_y_to_normal(basis, normal, ground_angle_conformance)
				var scale = scale_multiplier + r_scale * scale_variance * 2.0 - scale_variance
				basis = basis.scaled(Vector3.ONE * scale)
				inst.transform.basis = basis
				SceneUtils.add_child(host, inst)
		
