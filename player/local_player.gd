extends "./player.gd"

func _ready():
	set_name_tag("hbk")
	
func _process(delta):
	# handle look
	var mouse_pos = get_global_mouse_position()
	full_look_at(mouse_pos)
	
func _physics_process(delta):
	# handle walk
	var direction = Vector2(0, 0)
	if Input.is_action_pressed("ui_up"   ): direction.y -= 1
	if Input.is_action_pressed("ui_down" ): direction.y += 1
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left" ): direction.x -= 1
	
	move(direction, delta)
