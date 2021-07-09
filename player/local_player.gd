extends "./player.gd"

onready var last_direction = direction
onready var last_rotation = head.global_rotation
onready var network_player = $NetworkedPlayer

const FLOAT_EPSILON = 0.00001

static func compare_floats(a, b, epsilon = FLOAT_EPSILON):
	return abs(a - b) <= epsilon

func _ready():
	connect("player_died", self, "_on_death")
	connect("player_resurrected", self, "_on_resurrect")
	
	
func _process(delta):
	# handle look
	var mouse_pos = get_global_mouse_position()
	full_look_at(mouse_pos)
	
func _physics_process(delta):
	# handle walk
	direction.x = 0
	direction.y = 0
	
	if Input.is_action_pressed("ui_up"   ): direction.y -= 1
	if Input.is_action_pressed("ui_down" ): direction.y += 1
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left" ): direction.x -= 1
	
	if not compare_floats(last_rotation, head.global_rotation):
		network_player.rpc("set_rotation", head.global_rotation)
	if last_direction != direction:
		network_player.rpc("set_direction", direction)
		
	last_rotation = head.global_rotation
	last_direction = direction
	# ._physics_process(delta)

func _on_death():
	Utils.get_hud_node().hbd.visible = false
func _on_resurrect():
	Utils.get_hud_node().hbd.visible = true
