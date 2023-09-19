extends "./entity.gd"

var launch_time

remotesync func launch_towards(to_position: Vector2):
	var distance = to_position - global_position
	var direction = to_position.angle_to_point(global_position)
	launch_time = Time.get_ticks_msec()
	if multiplayer.get_rpc_sender_id() == 1:
		apply_impulse(Vector2(-1, 0).rotated(direction), Vector2(distance.length() / 2, 0).rotated(direction))
