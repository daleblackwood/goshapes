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
