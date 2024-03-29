extends "./player.gd"

onready var last_direction = direction
onready var last_rotation = head.global_rotation

const FLOAT_EPSILON = 0.00001

var misc_idx = 0

static func compare_floats(a, b, epsilon = FLOAT_EPSILON):
	return abs(a - b) <= epsilon

func _ready():
	connect("player_died", self, "_on_death")
	connect("player_resurrected", self, "_on_resurrect")
	connect("player_health_changed", self, "_on_health_change")
	connect("player_armor_changed", self, "_on_armor_change")
	connect("player_money_changed", self, "_on_money_change")
	connect("player_weapon_changed", self, "_on_weapon_change")
	connect("player_ammo_changed", self, "_on_ammo_change")
	
	Utils.get_hud_node().uname.text = name_tag
	
var spectating = 0

func _process(delta):
	# handle look
	if _is_spectating():
		listener.current = false
		camera.current = false
		_set_spectating()
	else:
		listener.current = true
		camera.current = true
		camera.limit_right = Utils.level_bounds.x
		camera.limit_bottom = Utils.level_bounds.y
		camera.position = ( get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2 ) / 1.5
	
	if _is_interactable():
		var mouse_pos = get_global_mouse_position()
		full_look_at(mouse_pos)
		
		if Input.is_action_just_released("ui_page_up") or Input.is_action_just_released("ui_page_down"):
			_select_next_weapon(Input.is_action_just_released("ui_page_down"))
		
		if Input.is_action_pressed("select_primary"): _select_primary_weapon()
		if Input.is_action_pressed("select_secondary"): _select_secondary_weapon()
		if Input.is_action_pressed("select_tertiary"): _select_tertiary_weapon()
			
		if Input.is_action_pressed("shoot"):
			_shoot()
			
		if Input.is_action_just_released("interact"):
			network_player.rpc_id(1, "interact")
			
		if Input.is_action_just_pressed("reload"):
			_reload()
		
	else:
		last_shoot = Time.get_ticks_msec()
	
	if Utils.get_chat_controller().focus == false and not _is_on_over_menu():
		if Input.is_action_just_pressed("ui_shop"): 
			if _current_hud_menu() == "shop":
				Utils.get_hud_node().clear_page()
			else:
				_request_shop()
		
		if Input.is_action_just_pressed("ui_team_select"): 
			if _current_hud_menu() == "team_select":
				Utils.get_hud_node().clear_page()
			else:
				_request_team_select()
		
		if Input.is_action_just_pressed("throw_weapon"):
			_throw_current_weapon()
	
	if Input.is_action_just_pressed("ui_menu"):
		Utils.get_chat_controller().unfocus()
		var over_menu = Utils.get_over_menu_node()
		over_menu.visible = not over_menu.visible
			
	
func _physics_process(delta):
	# handle walk
	direction.x = 0
	direction.y = 0
	
	if _is_interactable():
		if Input.is_action_pressed("ui_up"   ): direction.y -= 1
		if Input.is_action_pressed("ui_down" ): direction.y += 1
		if Input.is_action_pressed("ui_right"): direction.x += 1
		if Input.is_action_pressed("ui_left" ): direction.x -= 1
			 
		if not compare_floats(last_rotation, head.global_rotation):
			network_player.rpc_unreliable("set_rotation", head.global_rotation)
		if last_direction != direction:
			network_player.rpc("set_direction", direction)
			network_player.rpc("quick_correct_position", global_position)
			
	last_rotation = head.global_rotation
	last_direction = direction
	# ._physics_process(delta)

func _on_death():
	Utils.get_hud_node().hbd.visible = false
	
func _on_resurrect():
	Utils.get_hud_node().hbd.visible = true
	
func _on_weapon_change(weapon_id: int):
	Utils.get_hud_node().set_ammo_info(weapon_info.get(weapon_id))

func _on_ammo_change():
	Utils.get_hud_node().set_ammo_info(weapon_info.get(current_weapon))

func _on_health_change(health: int):
	Utils.get_hud_node().set_health(health)
	
func _on_armor_change(armor: int):
	Utils.get_hud_node().set_armor(armor)

func _on_money_change(money: int):
	Utils.get_hud_node().set_money(money)

func _request_shop():
	if player_can_shop():
		Utils.get_hud_node().show_shop()
		
func _request_team_select():
	Utils.get_hud_node().show_team_select()

func _current_hud_menu():
	return Utils.get_hud_node().current_page
	
func _is_on_menu():
	return _current_hud_menu() != ""
	
func _is_on_over_menu():
	return Utils.get_over_menu_node().visible

func _is_interactable():
	return not _is_on_menu() and not _is_on_over_menu() and health > 0 and Utils.get_chat_controller().focus == false
	
func _is_spectating():
	return health <= 0 or team == Utils.Team.SPECTATOR

func _select_primary_weapon():
	var primary = weapons[Utils.WeaponType.PRIMARY]
	if primary != -1: 
		set_weapon(primary)
		network_player.rpc_id(1, "equip_weapon", primary)
		
func _select_secondary_weapon():
	var secondary = weapons[Utils.WeaponType.SECONDARY]
	if secondary != -1: 
		set_weapon(secondary)
		network_player.rpc_id(1, "equip_weapon", secondary)

func _select_tertiary_weapon():
	var knife = 30
	set_weapon(knife)
	network_player.rpc_id(1, "equip_weapon", knife)
	
func _select_next_weapon(reverse: bool = false):
	var item = Utils.get_shop_controller().get_weapon_with_id(current_weapon)
	if item == null and current_weapon != 30: return
	
	var idx = item.type if item else 3
	# 0 primary 1 secondary 2 misc 3 knife
	
	while true:
		if idx == 2: # we are in misc
			if misc_idx + 1 < weapons[Utils.WeaponType.MISC].size():
				misc_idx += 1
				print(misc_idx)
				break
				
		if reverse: 
			idx -= 1 
		else: 
			idx += 1
			
		if idx == -1: idx = 3
		idx = idx % 4 # 0 primary 1 secondary 2 misc 3 knife
		
		if idx == 2:
			misc_idx = 0
			if weapons[Utils.WeaponType.MISC].size() > 0: break
		elif idx == 3 or weapons[idx] != -1: break
	
	var to_equip
	
	if idx < 2: 
		to_equip = weapons[idx] 
	if idx == 2:
		to_equip = weapons[Utils.WeaponType.MISC][misc_idx]
	if idx == 3:
		to_equip = 30

	set_weapon(to_equip)
	network_player.rpc_id(1, "equip_weapon", to_equip)
	
func _shoot():
	var current_time = Time.get_ticks_msec()
	var elapsed_time =  current_time - last_shoot
	
	var item = Utils.get_shop_controller().get_weapon_with_id(current_weapon)
	
	if health == 0 or not Utils.get_round_controller().move_enabled:
		return
		
	var hit_player = -1
	
	if item == null:
		if current_weapon == 30: 
			if elapsed_time > 900:
				if knife_ray.is_colliding() and knife_ray.get_collider().name == "Head":
					hit_player = int(ray.get_collider().get_parent().name)
			else: return
		else: return
		
	elif elapsed_time < item.props["cooldown"]:
		return
		
	elif item.type == Utils.WeaponType.MISC:
		pass
		
	elif current_weapon in weapon_info and weapon_info[current_weapon].ammo <= 0: 
		return
	
	elif ray.is_colliding() and ray.get_collider().name == "Head":
		hit_player = int(ray.get_collider().get_parent().name)
	
	shoot()
	network_player.rpc_id(1, "shoot", hit_player, get_global_mouse_position())
	
func _reload():
	if current_weapon == 30 or current_weapon == -1: return
	if weapon_info[current_weapon].mag <= 0: return
	
	reload()
	network_player.rpc_id(1, "reload")

func _throw_current_weapon():
	network_player.rpc_id(1, "throw_weapon", current_weapon)
	
func _set_spectating():
	if spectating == 0:
		var found = _set_spectating_next()
		if not found: return
	
	var specting_node = NetworkController.get_player_with_id(spectating)
	if specting_node == null or specting_node.health <= 0:
		spectating = 0
		return
	specting_node.listener.current = true
	specting_node.camera.current = true
	specting_node.camera.limit_right = Utils.level_bounds.x
	specting_node.camera.limit_bottom = Utils.level_bounds.y
	specting_node.camera.position = ( get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2 ) / 1.5
	

func _set_spectating_next():
	for player in NetworkController.get_player_nodes():
		if player.health > 0:
			spectating = int(player.name)
			return true
	return false
