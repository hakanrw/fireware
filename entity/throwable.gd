extends "./entity.gd"

var throw_started = false
var throw_ended = false
#
#func _ready():
#	if NetworkController.is_server():
#		rpc("throw")

func _process(delta):
	pass
#	if NetworkController.is_server() and not throw_ended and throw_started and linear_velocity.length() < 10:
#		linear_velocity = Vector2(0, 0)
#		throw_ended = true
#		rpc("update_position", global_position)
#		rpc("update_rotation", global_rotation)

remotesync func throw_towards(direction: float):
	if multiplayer.get_rpc_sender_id() == 1:
		print(direction)
		print(Vector2(50, 0).rotated(direction))
		var tween = get_tree().create_tween()
		tween.bind_node(self)
		tween.tween_property(self, "global_position", global_position + Vector2(50, 0).rotated(direction), 1) \
			.set_trans(Tween.TRANS_SINE)
