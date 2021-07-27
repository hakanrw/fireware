extends RigidBody2D
signal property_updated(property)

var type = "entity"
var variant = 0

var properties = {
	
}

func _ready():
	add_to_group("entity")
	
remote func update_position(position: Vector2):
	if 1 == multiplayer.get_rpc_sender_id():
		self.global_position = position
		emit_signal("property_updated", "position")

remote func update_rotation(rotation: float):
	if 1 == multiplayer.get_rpc_sender_id():
		self.rotation = global_rotation
		emit_signal("property_updated", "rotation")

remotesync func update_property(property, value):
	if 1 == multiplayer.get_rpc_sender_id():
		properties[property] = value
		emit_signal("property_updated", property)

func interact():
	pass

func get_props():
	var arr = {
		"id": get_id(),
		"position": global_position,
		"rotation": global_rotation,
		"name": name,
		"type": type,
		"variant": variant,
	}
	
	for key in properties.keys():
		arr[key] = properties[key]
	
	return arr
	
func set_props(props):
	if "position" in props: global_position = props["position"]
	if "rotation" in props: global_position = props["rotation"]
	
	for prop in props.keys():
		if prop != "position" and prop != "rotation":
			properties[prop] = props[prop]
		emit_signal("property_updated", prop)

func get_id():
	return str(get_path()).md5_text()
