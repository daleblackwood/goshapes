@tool
extends WallStyle
class_name WallMeshStyle

@export var mesh: Mesh: 
	set(value):
		if mesh != value:
			mesh = value
			emit_changed()
		
@export_range(0.1, 10.0, 0.1) var scale = 1.0:
	set(value):
		if scale != value:
			scale = value
			emit_changed()
		
@export var closed = true:
	set(value):
		if closed != value:
			closed = value
			emit_changed()
			
	
@export var materials: Array[Material] = []:
	set(value):
		if materials != value:
			materials = value
			emit_changed()
