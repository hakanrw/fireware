extends RigidBody2D
signal property_updated(property)

var type = "entity"

var properties = {
	
}

func _ready():
	add_to_group("entity")
	
remote func update_position(position: Vector2):
	if 1 == multiplayer.get_rpc_sender_id():
		self.position = position

remote func update_rotation(rotation: float):
	if 1 == multiplayer.get_rpc_sender_id():
		self.rotation = rotation

remotesync func update_property(property, value):
	if 1 == multiplayer.get_rpc_sender_id():
		properties[property] = value

func interact():
	pass
