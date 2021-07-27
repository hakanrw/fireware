extends Node2D

func _ready():
	pass

remote func update_position(position: Vector2):
	if 1 == multiplayer.get_rpc_sender_id():
		self.position = position
