extends Node
	
class Item:
	var id: int
	var name: String
	var price: int
	var type: int
	var props: Dictionary

	func _init(id: int, name: String, price: int, type: int, props: Dictionary = {}):
		self.id = id
		self.name = name
		self.price = price
		self.type = type
		self.props = props
		
	func clone():
		return Item.new(id, name, price, type, clone_dict(props))
		
	func clone_dict(source):
		var target = {}
		for key in source:
			target[key] = source[key]
		return target


var shop = [
	# rifle
	## Item.new(0 , "7.62 guerilla", 205, Utils.WeaponType.PRIMARY),
	Item.new(1 , "cv47", 2700, Utils.WeaponType.PRIMARY, {"cooldown": 200, "damage": 20, "ammo": 15, "mag": 45}),
	## Item.new(2 , "maverick m4a1", 3100, Utils.WeaponType.PRIMARY),
	# sidearm
	Item.new(5 , "7/24 sidearm", 400, Utils.WeaponType.SECONDARY, {"cooldown": 500, "damage": 25, "ammo": 8, "mag": 24}),
	Item.new(6 , "wrestler", 1000, Utils.WeaponType.SECONDARY, {"cooldown": 750, "damage": 35, "ammo": 5, "mag": 15}),
	# smg
	Item.new(10, "fastgun", 1100, Utils.WeaponType.PRIMARY, {"cooldown": 200, "damage": 10, "ammo": 16, "mag": 48}),
	# heavy
	##Item.new(15, "sawn off", 1100, Utils.WeaponType.PRIMARY),
	Item.new(16, ".51 blaster", 3000, Utils.WeaponType.PRIMARY, {"cooldown": 750, "damage": 50, "ammo": 2, "mag": 6}),	
	# misc
	# Item.new(20, "kevlar vest", 650, Utils.WeaponType.WEAR),
	Item.new(21, "x grenade", 300, Utils.WeaponType.MISC, {"cooldown": 500}),
	# Item.new(22, "shockbang", 200, Utils.WeaponType.MISC),
	Item.new(23, "smokebang", 300, Utils.WeaponType.MISC, {"cooldown": 500}),

]

func _ready():
	pass

func get_weapon_with_id(id: int):
	for weapon in shop:
		if id == weapon.id: return weapon.clone()
	return null

func get_weapons_of_category(category: int) -> Array:
	var weapons = []
	for weapon in shop:
		if weapon.id >= category * 5 and weapon.id < category * 5 + 5:
			 weapons.append(weapon.clone())
	return weapons

master func buy_weapon(weapon_id: int):
	var player = NetworkController.get_player_with_id(multiplayer.get_rpc_sender_id())
	var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
	
	if not player.player_can_shop():
		NetworkController.rpc_id(multiplayer.get_rpc_sender_id(), "alert", "you cannot shop now")
		return
	
	if item.price > player.money: 
		NetworkController.rpc_id(multiplayer.get_rpc_sender_id(), "alert", "not enough money")
		return
		
	if item.type == Utils.WeaponType.MISC and player.weapons[Utils.WeaponType.MISC].size() >= 4:
		NetworkController.rpc_id(multiplayer.get_rpc_sender_id(), "alert", "you cannot carry more throwables")
		return
	
	if (item.type == Utils.WeaponType.PRIMARY or item.type == Utils.WeaponType.SECONDARY) and player.weapons[item.type] != -1: 
		player.network_player.rpc("throw_weapon", player.weapons[item.type], true)
		
		
	var new_money = player.money - item.price
	
	player.get_node("NetworkedPlayer").rpc_id(1, "set_money", new_money)
	player.get_node("NetworkedPlayer").rpc_id(int(player.name), "set_money", new_money)

	if item.type == Utils.WeaponType.PRIMARY or item.type == Utils.WeaponType.SECONDARY or item.type == Utils.WeaponType.MISC:
		player.get_node("NetworkedPlayer").rpc("equip_weapon", weapon_id, true)
	else:
		pass
