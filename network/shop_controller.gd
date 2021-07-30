extends Node

class Item:
	var id: int
	var name: String
	var price: int
	var type: int

	func _init(id: int, name: String, price: int, type: int):
		self.id = id
		self.name = name
		self.price = price
		self.type = type
		
var shop = [
	# rifle
	Item.new(0 , "7.62 guerilla", 2050, Utils.WeaponType.PRIMARY),
	Item.new(1 , "cv47", 2700, Utils.WeaponType.PRIMARY),
	Item.new(2 , "maverick m4a1", 3100, Utils.WeaponType.PRIMARY),
	# sidearm
	Item.new(5 , "7/24 sidearm", 200, Utils.WeaponType.SECONDARY),
	Item.new(6 , "wrestler", 500, Utils.WeaponType.SECONDARY),	
	# smg
	Item.new(10, "fastgun", 1050, Utils.WeaponType.PRIMARY),
	# heavy
	Item.new(15, "sawn off", 1100, Utils.WeaponType.PRIMARY),
	Item.new(16, ".51 blaster", 1700, Utils.WeaponType.PRIMARY),	
	# misc
	Item.new(20, "kevlar vest", 650, Utils.WeaponType.WEAR),
	Item.new(21, "x grenade", 300, Utils.WeaponType.MISC),
	Item.new(22, "shockbang", 200, Utils.WeaponType.MISC),
	Item.new(23, "smokebang", 300, Utils.WeaponType.MISC),

]

func _ready():
	pass

func get_weapon_with_id(id: int):
	for weapon in shop:
		if id == weapon.id: return weapon
	return null

func get_weapons_of_category(category: int) -> Array:
	var weapons = []
	for weapon in shop:
		if weapon.id >= category * 5 and weapon.id < category * 5 + 5:
			 weapons.append(weapon)
	return weapons

master func buy_weapon(weapon_id: int):
	var player = NetworkController.get_player_with_id(multiplayer.get_rpc_sender_id())
	var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
	if item.price > player.money: return
	
	player.get_node("NetworkedPlayer").rpc("equip_weapon", weapon_id)
	player.get_node("NetworkedPlayer").rpc_id(1, "set_money", player.money - item.price)
	player.get_node("NetworkedPlayer").rpc_id(int(player.name), "set_money", player.money - item.price)
