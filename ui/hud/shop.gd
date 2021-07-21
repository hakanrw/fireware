extends Panel

const card = preload("res://ui/general/card.tscn")

onready var categories = $MarginContainer/VBoxContainer/HBoxContainer/Categories
onready var weapons_view = $MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/WeaponsView

func _ready():
	var category_children = categories.get_children()
	var i = 0
	for child in category_children:
		child.connect("mouse_clicked", self, "change_page", [i])
		i += 1

func change_page(page: int):
	clear_page()
	
	var shop_controller = Utils.get_shop_controller()
	var weapons = shop_controller.get_weapons_of_category(page)
	
	for weapon in weapons:
		var card_instance = card.instance()
		card_instance.set_text(weapon.name)
		card_instance.connect("mouse_clicked", self, "try_buy", [weapon.id])
		weapons_view.add_child(card_instance)

func clear_page():
	for n in weapons_view.get_children():
		weapons_view.remove_child(n)

func try_buy(weapon_id: int):
	print("try buy " + str(weapon_id))
