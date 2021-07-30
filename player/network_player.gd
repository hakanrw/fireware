extends Node

onready var player = get_node("..")

puppet func set_direction(direction: Vector2):
	player.direction = direction.normalized()

puppet func set_rotation(rotation: float):
	player.head.global_rotation = rotation

remotesync func set_name_tag(name_tag: String):
	if 1 == multiplayer.get_rpc_sender_id():
		player.name_tag = name_tag
		return
		
	if NetworkController.is_server():
		name_tag = name_tag.strip_edges(true, true)
		name_tag = name_tag.substr(0, 15)
		
		var player_nodes: Array = Utils.get_players_node().children
		var names = Array()
		for player_node in player_nodes:
			names.append(player_node.name_tag)
		
		var idx = 0
		var name_tag_after = name_tag
		while name_tag_after in names:
			idx += 1
			name_tag_after = name_tag + str(idx)
			
		name_tag = name_tag_after 
		rpc("set_name_tag", name_tag)
		
remotesync func set_health(hp):
	if 1 == multiplayer.get_rpc_sender_id():
		player.health = hp

remote func set_props(props):
	if 1 == multiplayer.get_rpc_sender_id():
		player.set_props(props)

remotesync func set_team(team: int):
	if 1 == multiplayer.get_rpc_sender_id():
		player.team = team
		player.next_team = team
		return
		
	if NetworkController.is_server():
		if team < 0 or team > 2: return
		if player.team == team: return
		
		player.next_team = team
		rpc("set_health", 0)
		
		reset_player()
		
		var round_controller = Utils.get_round_controller()
		if not round_controller.game_running():
			if NetworkController.get_player_nodes().size() == 1 and round_controller._hold_flag == false:
				round_controller.start_new_round()
			else: 
				round_controller.place_player(player, true)

remotesync func set_money(money: int):
	if 1 == multiplayer.get_rpc_sender_id():
		player.money = money

remotesync func reset_weaponry():
	if 1 == multiplayer.get_rpc_sender_id():
		player.weapons = {
			Utils.WeaponType.PRIMARY: -1,
			Utils.WeaponType.SECONDARY: -1,
			Utils.WeaponType.MISC: [],
		}

remotesync func throw_weapon(weapon_id: int, safe = false):
	if 1 == multiplayer.get_rpc_sender_id() and safe:
		var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
		player.weapons[item.type] = -1
		player.current_weapon = -1
		
		var wp = Utils.get_entity_controller().server_create_entity("weapon")
		wp.global_position = player.global_position
		wp.global_rotation = player.hand.global_rotation
		return
	
	if NetworkController.is_server():
		if weapon_id == -1 or weapon_id == 30:
			return
		if player.weapons[Utils.WeaponType.PRIMARY] != weapon_id \
			and player.weapons[Utils.WeaponType.SECONDARY] != weapon_id:
			return
			
		var equipped = 30
		if player.weapons[Utils.WeaponType.PRIMARY] != -1:
			equipped = player.weapons[Utils.WeaponType.PRIMARY]
		if player.weapons[Utils.WeaponType.SECONDARY] != -1:
			equipped = player.weapons[Utils.WeaponType.SECONDARY]
		
		rpc("throw_weapon", weapon_id, true)
		rpc("equip_weapon", equipped)

remotesync func equip_weapon(weapon_id):
	var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
	if item == null and weapon_id != -1 and weapon_id != 30: return
		
	if 1 == multiplayer.get_rpc_sender_id():
		if item: player.weapons[item.type] = weapon_id
		player.current_weapon = weapon_id
		return
		
	if NetworkController.is_server():
		var grant = false
		if weapon_id == 30:
			grant = true
		if player.weapons[Utils.WeaponType.PRIMARY] == weapon_id \
			or player.weapons[Utils.WeaponType.SECONDARY] == weapon_id:
			grant = true
		if weapon_id in player.weapons[Utils.WeaponType.MISC]:
			grant = true
		if grant == false: return
		
		if item and player.weapons[item.type] != -1: 
			rpc("throw_weapon", player.weapons[item.type], true)

func reset_player():
	# note: this code will be called only on server
	rpc_id(1, "set_money", Utils.start_money)
	rpc_id(int(player.name), "set_money", Utils.start_money)
	rpc_id(1, "reset_weaponry")
	rpc_id(int(player.name), "reset_weaponry")
	
	player.current_weapon = 30 # this is updated on all clients on round start

