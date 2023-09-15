extends Panel

const card = preload("res://ui/general/shop_card.tscn")

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
		var texture = load("res://weapons/sprites/" + str(weapon.id) + ".png")
		var card_instance = card.instance()
		card_instance.set_text(weapon.name)
		card_instance.set_texture(texture)
		card_instance.set_price(weapon.price)
		card_instance.connect("mouse_clicked", self, "try_buy", [weapon.id])
		weapons_view.add_child(card_instance)

func clear_page():
	for n in weapons_view.get_children():
		weapons_view.remove_child(n)

func try_buy(weapon_id: int):
	var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
	 
	print("try buy " + str(weapon_id))
	Utils.get_shop_controller().rpc_id(1, "buy_weapon", weapon_id)
	Utils.get_hud_node().clear_page()
