tool
extends Resource
class_name BlockStyle

export(CapStyles.Type) var cap_type = CapStyles.Type.Flat_Cap setget set_cap_type
export(Resource) var cap_style = null setget set_cap_style
export(WallStyles.Type) var wall_type = WallStyles.Type.Bevel_Wall setget set_wall_type
export(Resource) var wall_style = null setget set_wall_style
export(float, 0.0, 20.0, 0.5) var base_depth = 0.0 setget set_base_depth
export(CapStyles.Type) var base_type = CapStyles.Type.None setget set_base_type
export(Resource) var base_style = null setget set_base_style

var is_dirty = false

func _init() -> void:
	if not cap_style:
		set_cap_style(CapStyles.create_style(cap_type))
	if not wall_style:
		set_wall_style(WallStyles.create_style(wall_type))


func set_cap_type(value):
	cap_type = value
	set_cap_style(CapStyles.create_style(cap_type))


func set_cap_style(value):
	ResourceUtils.switch_signal(self, "set_dirty", cap_style, value)
	cap_style = value
	set_dirty()
	
	
func set_wall_type(value):
	wall_type = value
	set_wall_style(WallStyles.create_style(wall_type))
	
	
func set_wall_style(value):
	ResourceUtils.switch_signal(self, "set_dirty", wall_style, value)
	wall_style = value
	set_dirty()
	
func set_base_depth(value):
	base_depth = value
	set_dirty()
	
	
func set_base_type(value):
	base_type = value
	set_base_style(CapStyles.create_style(base_type))


func set_base_style(value):
	SceneUtils.switch_signal(self, "changed", "set_dirty", base_style, value)
	base_style = value
	set_dirty()

	
func set_dirty():
	if is_dirty:
		return
	is_dirty = true
	call_deferred("_update")
	
	
func _update():
	is_dirty = false
	emit_changed()
