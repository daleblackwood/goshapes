@tool
class_name MeshSet
## A data class that stores mesh information


var verts = PackedVector3Array()
var uvs = PackedVector2Array()
var normals = PackedVector3Array()
var tris = PackedInt32Array()
var material: Material = null
var vert_count: int: get = get_vert_count
var tri_count: int: get = get_tri_count


func set_counts(vert_count: int, tri_count: int) -> void:
	set_vert_count(vert_count)
	set_tri_count(tri_count)
	
	
func set_vert_count(count: int) -> void:
	verts.resize(count)
	uvs.resize(count)
	normals.resize(count)
	
	
func get_vert_count() -> int:
	return verts.size()
	
	
func set_vert(i: int, v: Vector3) -> void:
	verts.set(i, v)
	
	
func set_uv(i: int, v: Vector2) -> void:
	uvs.set(i, v)
	
	
func set_normal(i: int, v: Vector3) -> void:
	normals.set(i, v)
	
	
func set_tri(i: int, vert_i: int) -> void:
	tris.set(i, vert_i)
	
	
func set_tri_count(count: int) -> void:
	tris.resize(count)
	
	
func get_tri_count() -> int:
	return tris.size()
	

func clone() -> MeshSet:
	var result = MeshSet.new()
	result.copy(self)
	return result
	
	
func copy(other: MeshSet) -> void:
	verts = PackedVector3Array(other.verts)
	uvs = PackedVector2Array(other.uvs)
	normals = PackedVector3Array(other.normals)
	tris = PackedInt32Array(other.tris)
	material = other.material
	
	
func recalculate_normals() -> void:
	var new_normals = PackedVector3Array()
	new_normals.resize(verts.size())
	for i in range(new_normals.size()):
		new_normals.set(i, Vector3.ZERO)
		
	var tris = self.tris
	for i in range(0, tris.size(), 3):
		var i0 = tris[i]
		var i1 = tris[i + 1]
		var i2 = tris[i + 2]        
		var v0 = verts[i0]
		var v1 = verts[i1]
		var v2 = verts[i2]
		var triangle_normal = calculate_triangle_normal(v0, v1, v2)
		new_normals.set(i0, new_normals[i0] + triangle_normal)
		new_normals.set(i1, new_normals[i1] + triangle_normal)
		new_normals.set(i2, new_normals[i2] + triangle_normal)
		
	for i in range(new_normals.size()):
		if new_normals[i].length() > 0:
			new_normals.set(i, (-new_normals[i]).normalized())
	normals = new_normals
	

func calculate_triangle_normal(v0: Vector3, v1: Vector3, v2: Vector3) -> Vector3:
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	return edge1.cross(edge2).normalized()
