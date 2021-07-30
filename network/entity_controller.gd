extends Node

var counter = 0

remote func create_entity(name: String, type: String, variant: int):
	if 1 == multiplayer.get_rpc_sender_id():
		local_create_entity(name, type, variant)

func local_create_entity(name: String, type: String, variant: int):
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
		
	scene.name = name
	scene.type = type
	scene.variant = variant
	scene.set_script(script)
	Utils.get_entities_node().add_child(scene)
	return scene

func server_create_entity(type: String, variant: int):
	# this needs to be called on servers
	rpc("create_entity", str(counter), type, variant)
	counter += 1
	return create_entity(str(counter - 1), type, variant)
