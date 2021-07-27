extends "./entity.gd"

var throw_started = false
var throw_ended = false

func _ready():
	if NetworkController.is_server():
		rpc("throw")

func _process(delta):
	if NetworkController.is_server() and not throw_ended and throw_started and linear_velocity.length() < 10:
		linear_velocity = Vector2(0, 0)
		throw_ended = true
		rpc("update_position", global_position)
		rpc("update_rotation", global_rotation)

remotesync func throw():
	apply_impulse(Vector2(0, 0), Vector2(50, 0))
	yield(get_tree().create_timer(1), "timeout")
	throw_started = true
