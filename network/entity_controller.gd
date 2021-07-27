extends Node

func _ready():
	pass

remotesync func create_entity(type: String, variant: int, position: Vector2, rotation: float):
	if 1 == multiplayer.get_rpc_sender_id():
		var scene: Node2D = null
		if ResourceLoader.exists("res://entity/" + type + ".tscn"):
			scene = load("res://entity/" + type + ".tscn").intance()
		else:
			scene = load("res://entity/entity.tscn").instance()
		
		var script: Resource = null
		if ResourceLoader.exists("res://entity/" + type + ".gd"):
			script = load("res://entity/" + type + ".gd")
		else:
			script = load("res://entity/entity.gd")
		
		if type == "weapon":
			scene.add_child(load("res://weapon/" + str(variant) + ".tscn").instance())
			
		scene.set_script(script)
		scene.global_position = position
		scene.global_rotation = rotation
		Utils.get_entities_node().add_child(scene)
