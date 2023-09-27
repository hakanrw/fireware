extends Node

onready var player = get_node("..")

func _ready():
	if NetworkController.is_server():
		player.connect("player_died", self, "_server_player_died")
	
func _server_player_died():
	
	if Utils.get_round_controller().starting_round:
		return
		
	# create dead body
	print("create dead body")
	
	var dead_body = Utils.get_entity_controller().server_create_entity("dead_player", player.team)
	dead_body.global_position = player.global_position
	dead_body.global_rotation = player.head.global_rotation
	dead_body.rpc("update_position", dead_body.global_position)
	dead_body.rpc("update_rotation", dead_body.global_rotation)
	print(dead_body.global_position)
	
	var primary_weapon = player.weapons[Utils.WeaponType.PRIMARY]
	var secondary_weapon = player.weapons[Utils.WeaponType.SECONDARY]
	if primary_weapon != -1:
		player.head.global_rotation += PI / 4      # so that primary and secondary weapon 
		rpc("throw_weapon", primary_weapon, true)  # are not spawned at the same position
		player.head.global_rotation -= PI / 4      # 
	if secondary_weapon != -1:
		rpc("throw_weapon", secondary_weapon, true)

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

func take_damage(damage):
	# call only on server
	
	var health = player.health
	var armor = player.armor
	
	health -= damage
	if armor > 0:
		health += int(floor( min(damage, armor) / 3 ))
		armor -= damage
		rpc("set_armor", armor)
		
	rpc("set_health", health)
	

remotesync func set_health(hp):
	if 1 == multiplayer.get_rpc_sender_id():
		player.health = hp
		
remotesync func set_armor(armor):
	if 1 == multiplayer.get_rpc_sender_id():
		player.armor = armor

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
		
remotesync func refill_ammo():
	if 1 == multiplayer.get_rpc_sender_id():
		var primary_weapon = player.weapons[Utils.WeaponType.PRIMARY]
		var secondary_weapon = player.weapons[Utils.WeaponType.SECONDARY]
		if primary_weapon != -1:
			player.weapon_info[primary_weapon] = Utils.get_shop_controller().get_weapon_with_id(primary_weapon).props
		if secondary_weapon != -1:
			player.weapon_info[secondary_weapon] = Utils.get_shop_controller().get_weapon_with_id(secondary_weapon).props

remotesync func throw_weapon(weapon_id: int, safe = false):
	if 1 == multiplayer.get_rpc_sender_id() and safe:
		var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
		# player.current_weapon = 30
		player.weapons[item.type] = -1
		player.throw_player.play()
		
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
		
		rpc("equip_weapon", equipped, true, true)
		

remotesync func equip_weapon(weapon_id: int, safe = false, from_inventory = false):
	var item = Utils.get_shop_controller().get_weapon_with_id(weapon_id)
	if item == null and weapon_id != -1 and weapon_id != 30: return
		
	if 1 == multiplayer.get_rpc_sender_id() and safe:
#		if NetworkController.is_server() and item and player.weapons[item.type] != -1 and not equip_current: 
#			rpc("throw_weapon", player.weapons[item.type], true, false)
#		# check if ^ precedes v on client
		if item: 
			if item.type == Utils.WeaponType.PRIMARY or item.type == Utils.WeaponType.SECONDARY:
				player.weapons[item.type] = weapon_id
					
				if NetworkController.is_server() or get_tree().get_network_unique_id() == int(player.name):
					if not from_inventory:
						# means player bought the weapon
						player.weapon_info[weapon_id] = item.props
						
			elif item.type == Utils.WeaponType.MISC:
				if not from_inventory:
					player.weapons[item.type].append(weapon_id)
		
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
		
		rpc("equip_weapon", weapon_id, true, true)
			

remotesync func shoot(hit_player: int, mouse_global_pos: Vector2):
	var item = Utils.get_shop_controller().get_weapon_with_id(player.current_weapon)
	
	if multiplayer.get_rpc_sender_id() == 1:
		
		if NetworkController.is_server():
			if item and item.type == Utils.WeaponType.MISC:
				var launchee = Utils.get_entity_controller().server_create_entity("grenade", player.current_weapon)
				launchee.global_position = player.global_position
				launchee.global_rotation = player.head.global_rotation
				launchee.rpc("update_position", launchee.global_position)
				launchee.rpc("update_rotation", launchee.global_rotation)
				launchee.rpc("launch_towards", mouse_global_pos)
			if hit_player != -1:
				# maybe add logic that checks if shoot is legitimate?
				var hit_player_node = NetworkController.get_player_with_id(hit_player)
				var damage = item.props["damage"] if item else 50 if player.current_weapon == 30 else 0
				
				hit_player_node.network_player.take_damage(damage)
			
		if not get_tree().get_network_unique_id() == int(player.name):
			player.shoot() # so that player doesn't shoot twice
			
		
	if NetworkController.is_server() and multiplayer.get_rpc_sender_id() == int(player.name):
		# print("got shoot request")
		var error_flag = false
		
		var current_time = Time.get_ticks_msec()
		var elapsed_time =  current_time - player.last_shoot
			
		if player.health == 0 or not Utils.get_round_controller().move_enabled:
			error_flag = true
			print("shoot request error: player is not permitted to shoot")
		
		elif item == null:
			if player.current_weapon != 30:
				error_flag = true
				print("shoot request error: no such weapon")
			elif elapsed_time < 750:
				error_flag = true
				print("shoot request error: client too fast")
		
		elif elapsed_time < item.props["cooldown"] * 0.8:
			error_flag = true
			print("shoot request error: client too fast")
		
		elif item.type != Utils.WeaponType.MISC and player.weapon_info[player.current_weapon]["ammo"] <= 0:
			error_flag = true
			print("shoot request error: client has no ammo")
		
		if error_flag:
			# correct client data
			rpc_id(int(player.name), "set_weapon_info", player.current_weapon, player.weapon_info[player.current_weapon])
			return
			
			
		rpc("shoot", hit_player, mouse_global_pos)
		

remotesync func reload():
	var item = Utils.get_shop_controller().get_weapon_with_id(player.current_weapon)
	
	var current_time = Time.get_ticks_msec()
	
	if multiplayer.get_rpc_sender_id() == 1:
		if not get_tree().get_network_unique_id() == int(player.name):
			player.reload() # so that player doesn't reload twice
	
	if NetworkController.is_server() and multiplayer.get_rpc_sender_id() == int(player.name):
		# print("got reload request")
		var error_flag = false
		
		if item == null or item.type == Utils.WeaponType.MISC:
			return
			
		if player.last_shoot > current_time:
			error_flag = true
			print("reload request error: client reloading already")
			
		elif player.weapon_info[player.current_weapon].mag <= 0: 
			error_flag = true
			print("reload request error: client has no ammo")
		
		if error_flag:
			# correct client data			
			rpc_id(int(player.name), "set_weapon_info", player.current_weapon, player.weapon_info[player.current_weapon])
			return
		
		rpc("reload")
		

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
	player.armor = 0

