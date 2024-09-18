@tool
class_name GoshapeMenus

class GSMenuItem:
	var label: String
	var id: int
	
	func _init(label: String) -> void:
		self.label = label
		self.id = get_instance_id()
		
	func populate(popup: PopupMenu) -> void:
		popup.add_item(label, id)
		
	func select() -> void:
		pass
		
		
class GSButton extends GSMenuItem:
	var callable: Callable
	var arg: Variant
	func _init(label: String, callable: Callable, arg: Variant = null) -> void:
		super(label)
		self.callable = callable
		self.arg = arg
		
	func select() -> void:
		if arg == null:
			callable.call()
		else:
			callable.call(arg)
		
class GSToggle extends GSButton:
	var value := false
	
	func _init(label: String, value: bool, callable: Callable) -> void:
		super._init(label, callable)
		self.value = value
		
	func populate(popup: PopupMenu) -> void:
		popup.add_check_item(label, id)
		popup.set_item_checked(popup.get_item_index(id), value)
		
	func select() -> void:
		callable.call(not value)


class GSMenu:
	var items: Array[GSMenuItem] = []
	var popup: PopupMenu
	
	func _init(popup: PopupMenu) -> void:
		self.popup = popup
	
	func add_item(item: GSMenuItem) -> GSMenu:
		items.append(item)
		return self
		
	func add_items(items: Array[GSMenuItem]) -> GSMenu:
		for item in items:
			add_item(item)
		return self
		
	func populate() -> void:
		popup.clear()
		if popup.index_pressed.is_connected(_on_selected):
			popup.index_pressed.disconnect(_on_selected)
		for item in items:
			item.populate(popup)
		popup.index_pressed.connect(_on_selected)
		
	func _on_selected(index: int) -> void:
		print("selected ", index)
		items[index].select()
		populate.call_deferred()
		

class GMPopup extends GSMenuItem:
	var menu: GSMenu
	
	func _init(label: String, menu: GSMenu) -> void:
		super._init(label)
		self.menu = menu
		
