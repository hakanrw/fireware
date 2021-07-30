extends Node

const player_prefab = preload("res://player/player.tscn")

func is_server():
	return get_tree().is_network_server()
	
func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func close_connection():
	get_tree().network_peer.close_connection()
	get_tree().network_peer = null
	Utils.load_menu()
	
func connect_to_server(url, port):
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(url, port)
	if err != OK:
		return false
	
	get_tree().network_peer = peer
	return true
	
func _player_connected(id):
	if is_server():
		var round_controller = Utils.get_round_controller()
		rpc_id(id, "update_players_props", get_players_props())
		round_controller.rpc_id(id, "update_leaderboard", round_controller.leaderboard)
		round_controller.rpc_id(id, "update_timer", round_controller._max_round_time, round_controller.timer.time_left)
		round_controller.rpc_id(id, "load_level", Utils.get_level_name())
		rpc_id(id, "update_entities_props", get_entities_props())
		rpc("create_player", id)
		
	print("player joined with id: " + str(id))
	# Called on both clients and server when a peer connects.
	pass
	
func _player_disconnected(id):
	if is_server():
		rpc("remove_player", id)
	print("player disconnected with id: " + str(id))
	pass

func _connected_ok():
	Utils.load_game()
	# Utils.get_hud_node().show_team_select()
	pass # Only called on clients, not server. Will go unused; not useful here.

func _server_disconnected():
	Utils.show_error_page("You have been disconnected from the server")
	pass # Server kicked us; show error and abort.

func _connected_fail():
	Utils.show_error_page("Connection couldn't be established")
	pass # Could not even connect to server; abort.

remote func update_entities_props(entities_props: Array):
	if 1 == multiplayer.get_rpc_sender_id():
		for entity_props in entities_props:
			var entity = get_entity_with_id(entity_props["id"])
			if entity == null: entity = Utils.get_entity_controller().local_create_entity(entity_props.name, entity_props.type, entity_props.variant)
			entity.set_props(entities_props)

func get_entities_props():
	var entities_props = []
	for entity in get_entity_nodes():
		entities_props.append(entity.get_props())
	return entities_props

func get_entity_nodes() -> Array:
	return get_tree().get_nodes_in_group("entity")

func get_entity_with_id(id: String) -> Node2D:
	var entity = null
	for e in get_entity_nodes():
		if e.id == id:
			entity = e
			break
	return entity

remotesync func create_player(id):
	if 1 != get_tree().get_rpc_sender_id():
		return
	if not Utils.is_game_loaded():
		yield(get_tree(), "idle_frame")
	
	local_create_player(id)
	# print(Utils.get_game_node())
	# yield(Utils.get_game_node(), "ready")
	
remotesync func remove_player(id):
	if 1 != get_tree().get_rpc_sender_id():
		return
	Utils.get_players_node().get_node(str(id)).queue_free()
	Utils.get_round_controller().rpc("update_leaderboard", {id: "rm"})
	print("removing player: " + str(id))

remote func update_players_props(players_props: Array):
	if 1 == multiplayer.get_rpc_sender_id():
		for player_props in players_props:
			var player = get_player_with_id(player_props["id"])
			if player == null: player = local_create_player(player_props["id"])
			player.set_props(player_props)

func get_player_nodes() -> Array:
	return Utils.get_players_node().get_children()
	
func get_players_props() -> Array:
	var players = Utils.get_players_node().get_children()
	var players_props = Array()
	for player in players:
		players_props.append(player.get_props())
	return players_props
	
func get_player_with_id(id: int):
	if not Utils.get_players_node().has_node(str(id)): return null
	return Utils.get_players_node().get_node(str(id))

func get_self_player():
	return get_player_with_id(multiplayer.get_network_unique_id())
	
func local_create_player(id):
	if get_player_with_id(id): return
	Utils.get_round_controller().rpc("update_leaderboard", {id: 0})
	
	var player = player_prefab.instance()
	if id == multiplayer.get_network_unique_id():
		player.set_script(load("res://player/local_player.gd"))
	else:
		player.set_script(load("res://player/player.gd"))
	player.set_network_master(id)
	player.name = str(id)
	Utils.get_players_node().add_child(player)
	player.set_team(Utils.Team.SPECTATOR)
	print("initiating player: " + str(id))
	
	return player
