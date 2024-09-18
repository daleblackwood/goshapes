@tool
class_name GoshapeMenus

class GSMenuItem:
	var label: String
	var id: int
	
	func _init(label: String) -> void:
		self.label = label
		self.id = get_instance_id()
		
	func populate(parent: PopupMenu) -> void:
		pass
		
	func select() -> void:
		pass
		
		
class GSButton extends GSMenuItem:
	var callable: Callable
	var arg: Variant
	
	func _init(label: String, callable: Callable, arg: Variant = null) -> void:
		super(label)
		self.callable = callable
		self.arg = arg
		
	func populate(parent: PopupMenu) -> void:
		parent.add_item(label, id)
		
	func select() -> void:
		print_debug("> ", label)
		if arg == null:
			callable.call()
		else:
			callable.call(arg)
			
		
class GSToggle extends GSButton:
	var value := false
	var host: Object
	var property: String
	var parent: PopupMenu
	
	func _init(label: String, host: Object, property: String) -> void:
		super._init(label, callable)
		self.host = host
		self.property = property
		
	func populate(parent: PopupMenu) -> void:
		self.parent = parent
		parent.add_check_item(label, id)
		update_value()
		
	func update_value() -> void:
		var value = host.get(property) as bool
		parent.set_item_checked(parent.get_item_index(id), value)
		
	func select() -> void:
		var value = host.get(property) as bool
		print_debug("> ", label, " set to ", "true" if not value else "false")
		host.set(property, not value)
		update_value()


class GSMenu:
	var items: Array[GSMenuItem] = []
	var parent: PopupMenu
	var is_populating := false
	
	func add_item(item: GSMenuItem, index := -1) -> GSMenu:
		if index > 0:
			items.insert(index, item)
		else:
			items.append(item)
		return self
		
	func add_items(items: Array[GSMenuItem]) -> GSMenu:
		for item in items:
			add_item(item)
		return self
		
	func populate(parent: PopupMenu) -> void:
		if is_populating:
			return
		is_populating = true
		self.parent = parent
		parent.clear()
		for item in items:
			item.populate(parent)
		if not parent.index_pressed.is_connected(_on_press):
			parent.index_pressed.connect(_on_press)
		is_populating = false
		
	func _on_press(index: int) -> void:
		items[index].select()
		populate.call_deferred(parent)
		

class GMPopup extends GSMenuItem:
	var menu: GSMenu
	var popup: PopupMenu
	
	func _init(label: String, menu: GSMenu) -> void:
		super._init(label)
		self.menu = menu
		popup = PopupMenu.new()
		
	func populate(parent: PopupMenu) -> void:
		menu.populate(popup)
		parent.add_submenu_node_item(label, popup, id)
		
	
