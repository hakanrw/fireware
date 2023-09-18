extends "./entity.gd"

var launch_time

remotesync func launch_towards(direction: float):
	launch_time = Time.get_ticks_msec()
	if multiplayer.get_rpc_sender_id() == 1:
		apply_impulse(Vector2(-1, 0).rotated(direction), Vector2(250, 0).rotated(direction))
