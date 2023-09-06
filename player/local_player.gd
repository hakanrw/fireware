extends "./player.gd"

onready var last_direction = direction
onready var last_rotation = head.global_rotation

const FLOAT_EPSILON = 0.00001

static func compare_floats(a, b, epsilon = FLOAT_EPSILON):
	return abs(a - b) <= epsilon

func _ready():
	connect("player_died", self, "_on_death")
	connect("player_resurrected", self, "_on_resurrect")

func _process(delta):
	# handle look
	if _is_interactable():
		var mouse_pos = get_global_mouse_position()
		full_look_at(mouse_pos)
		
		if Input.is_action_just_released("ui_page_up") or Input.is_action_just_released("ui_page_down"):
			_select_next_weapon(Input.is_action_just_pressed("ui_page_down"))
			
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
	return not _is_on_menu() and health > 0

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

	network_player.rpc_id(1, "equip_weapon", weapons[idx] if idx != 2 else 30)

func _throw_current_weapon():
	network_player.rpc_id(1, "throw_weapon", current_weapon)
