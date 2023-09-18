extends "./player.gd"

onready var last_direction = direction
onready var last_rotation = head.global_rotation

const FLOAT_EPSILON = 0.00001

static func compare_floats(a, b, epsilon = FLOAT_EPSILON):
	return abs(a - b) <= epsilon

func _ready():
	connect("player_died", self, "_on_death")
	connect("player_resurrected", self, "_on_resurrect")
	connect("player_health_changed", self, "_on_health_change")
	connect("player_weapon_changed", self, "_on_weapon_change")
	connect("player_ammo_changed", self, "_on_ammo_change")
	connect("player_money_changed", self, "_on_money_change")
	
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
			_select_next_weapon(Input.is_action_just_pressed("ui_page_down"))
			
		if Input.is_action_pressed("shoot"):
			_shoot()
			
		if Input.is_action_just_released("interact"):
			network_player.rpc_id(1, "interact")
			
		if Input.is_action_just_pressed("reload"):
			_reload()
		
	else:
		last_shoot = Time.get_ticks_msec()
	
	if Utils.get_chat_controller().focus == false:
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
		
		if Input.is_action_just_pressed("ui_menu"):
			NetworkController.close_connection()
		
		if Input.is_action_just_pressed("throw_weapon"):
			_throw_current_weapon()
			
	
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

func _is_interactable():
	return not _is_on_menu() and health > 0 and Utils.get_chat_controller().focus == false
	
func _is_spectating():
	return health <= 0 or team == Utils.Team.SPECTATOR

func _select_next_weapon(reverse: bool = false):
	var item = Utils.get_shop_controller().get_weapon_with_id(current_weapon)
	if item == null and current_weapon != 30: return
	
	var idx = item.type if item else 2
	# 0 = primary 1 = secondary 2 = knife
	
	while true:
		if reverse: 
			idx -= 1 
		else: 
			idx += 1
		idx = idx % 3
		
		if idx == 2 or weapons[idx] != -1: break

	set_weapon(weapons[idx] if idx != 2 else 30)
	network_player.rpc_id(1, "equip_weapon", weapons[idx] if idx != 2 else 30)
	
func _shoot():
	var current_time = Time.get_ticks_msec()
	var elapsed_time =  current_time - last_shoot
	
	var item = Utils.get_shop_controller().get_weapon_with_id(current_weapon)
	
	if health == 0 or not Utils.get_round_controller().move_enabled:
		return
		
	if item == null:
		if current_weapon == 30: 
			pass # handle knife attack
		return
		
	if elapsed_time < item.props["cooldown"]:
		return
		
	if weapon_info[current_weapon].ammo <= 0: return
	
	var hit_player = -1
	
	if ray.is_colliding() and ray.get_collider().name == "Head":
		hit_player = int(ray.get_collider().get_parent().name)
	
	shoot()
	network_player.rpc_id(1, "shoot", hit_player)
	
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
