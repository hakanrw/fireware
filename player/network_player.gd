extends Node

onready var player = get_node("..")

puppet func quick_correct_position(position: Vector2):
	if Utils.get_round_controller().move_enabled:
		player.global_position = position

puppet func set_direction(direction: Vector2):
	player.direction = direction.normalized()

puppet func set_rotation(rotation: float):
	player.head.global_rotation = rotation

remotesync func set_name_tag(name_tag: String):
	if 1 == multiplayer.get_rpc_sender_id():
		player.name_tag = name_tag
		return
		
	if NetworkController.is_server():
		name_tag = NetworkController.prepare_name_tag(name_tag)
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
			# if NetworkController.get_player_nodes().size() == 1 and round_controller._hold_flag == false:
			# 	round_controller.start_new_round()
			# else: 
			#	round_controller.place_player(player, true)
			round_controller.place_player(player, true)

remotesync func set_money(money: int):
	if 1 == multiplayer.get_rpc_sender_id():
		player.money = money

remotesync func set_weapon_info(weapon_id, info):
	if 1 == multiplayer.get_rpc_sender_id():
		player.weapon_info[weapon_id] = info
		player.emit_signal("player_ammo_changed")

remotesync func reset_weaponry():
	if 1 == multiplayer.get_rpc_sender_id():
		player.weapons = {
			Utils.WeaponType.PRIMARY: -1,
			Utils.WeaponType.SECONDARY: 5, # player has sidearm by default
			Utils.WeaponType.MISC: [],
		}
		
		player.weapon_info = {}
		player.weapon_info[5] = Utils.get_shop_controller().get_weapon_with_id(5).props
		
		player.current_weapon = 5 # this is updated on all clients on round start

remotesync func throw_weapon(weapon_id: int, safe = false):
	if 1 == multiplayer.get_rpc_sender_id() and safe:
		var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
		player.current_weapon = -1
		player.weapons[item.type] = -1
		
		if NetworkController.is_server():
			var weapon_props = player.weapon_info[weapon_id]
			var wp = Utils.get_entity_controller().server_create_entity("weapon", weapon_id)
			wp.global_position = player.global_position
			wp.global_rotation = player.head.global_rotation
			wp.rpc("update_position", wp.global_position)
			wp.rpc("update_property", "weapon_info", weapon_props)
			wp.rpc("update_rotation", wp.global_rotation)
			wp.rpc("throw_towards", player.head.global_rotation)
			
		player.weapon_info.erase(weapon_id)	
		return
	
	if NetworkController.is_server() and multiplayer.get_rpc_sender_id() == int(player.name):
		if weapon_id == -1 or weapon_id == 30:
			return
		if player.weapons[Utils.WeaponType.PRIMARY] != weapon_id \
			and player.weapons[Utils.WeaponType.SECONDARY] != weapon_id:
			return
			
		rpc("throw_weapon", weapon_id, true)
			
		var equipped = 30
		if player.weapons[Utils.WeaponType.PRIMARY] != -1:
			equipped = player.weapons[Utils.WeaponType.PRIMARY]
		if player.weapons[Utils.WeaponType.SECONDARY] != -1:
			equipped = player.weapons[Utils.WeaponType.SECONDARY]
		
		rpc("equip_weapon", equipped, true)
		

remotesync func equip_weapon(weapon_id: int, safe = false):
	var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
	if item == null and weapon_id != -1 and weapon_id != 30: return
		
	if 1 == multiplayer.get_rpc_sender_id() and safe:
#		if NetworkController.is_server() and item and player.weapons[item.type] != -1 and not equip_current: 
#			rpc("throw_weapon", player.weapons[item.type], true, false)
#		# check if ^ precedes v on client
		if item: 
			player.weapons[item.type] = weapon_id
			if NetworkController.is_server() or get_tree().get_network_unique_id() == int(player.name):
				if not player.weapon_info.has(weapon_id):
					# means player bought the weapon
					player.weapon_info[weapon_id] = item.props
					
		player.current_weapon = weapon_id
		player.last_shoot = Time.get_ticks_msec()
		return

	if NetworkController.is_server() and multiplayer.get_rpc_sender_id() == int(player.name):
		var grant = false
		if weapon_id == 30:
			grant = true
		if player.weapons[Utils.WeaponType.PRIMARY] == weapon_id \
			or player.weapons[Utils.WeaponType.SECONDARY] == weapon_id:
			grant = true
		if weapon_id in player.weapons[Utils.WeaponType.MISC]:
			grant = true
		if grant == false: return
		
		rpc("equip_weapon", weapon_id, true)
			

remotesync func shoot(hit_player: int):
	var item = Utils.get_shop_controller().get_weapon_with_id(player.current_weapon)
	if multiplayer.get_rpc_sender_id() == int(player.name):
		if player.health == 0 or !Utils.get_round_controller().move_enabled:
			return
		var line_vec = player.ray.cast_to
		
		if player.ray.is_colliding():
			line_vec = Vector2(player.ray.global_position.distance_to(player.ray.get_collision_point()), 0)
		
		player.line.visible = true
		player.line.set_point_position(1, line_vec)
		
		player.last_shoot = Time.get_ticks_msec()
		
		if NetworkController.is_server() or get_tree().get_network_unique_id() == int(player.name):
			player.weapon_info[player.current_weapon]["ammo"] -= 1
		
		if hit_player != -1:
			if NetworkController.is_server():
				if player.weapon_info[player.current_weapon]["ammo"] < 0: 
					print("no ammo + tried to cheat")
					return
				# maybe add logic that checks if shoot is legitimate?
				var hit_player_node = NetworkController.get_player_with_id(hit_player)
				hit_player_node.network_player.rpc("set_health", hit_player_node.health - item.props["damage"])
		
		player.emit_signal("player_ammo_changed")

remote func interact():
	if NetworkController.is_server() and multiplayer.get_rpc_sender_id() == int(player.name):
		var areas = player.head.get_overlapping_areas()
		if areas.size() == 0: return
		
		var interaction = areas[0].get_parent()
		if interaction.has_method("interact"):
			interaction.interact(player)
	

func reset_player():
	# note: this code will be called only on server
	rpc_id(1, "set_money", Utils.start_money)
	rpc_id(int(player.name), "set_money", Utils.start_money)
	rpc_id(1, "reset_weaponry")
	rpc_id(int(player.name), "reset_weaponry")

