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

func connect_to_server(url, port):
	var peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(url, port)
	if err != OK:
		return false
	
	get_tree().network_peer = peer
	return true
	
func _player_connected(id):
	if is_server():
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
	pass # Only called on clients, not server. Will go unused; not useful here.

func _server_disconnected():
	Utils.show_error_page("You have been disconnected from the server")
	pass # Server kicked us; show error and abort.

func _connected_fail():
	Utils.show_error_page("Connection couldn't be established")
	pass # Could not even connect to server; abort.

remotesync func create_player(id):
	if 1 != get_tree().get_rpc_sender_id():
		return
	if not Utils.is_game_loaded():
		yield(get_tree(), "idle_frame")
	
	# print(Utils.get_game_node())
	# yield(Utils.get_game_node(), "ready")
	var player = player_prefab.instance()
	player.set_network_master(id)
	player.name = str(id)
	Utils.get_players_node().call_deferred("add_child", player)
	print("initiating player: " + str(id))
	
remotesync func remove_player(id):
	if 1 != get_tree().get_rpc_sender_id():
		return
	Utils.get_players_node().get_node(str(id)).queue_free()
	print("removing player: " + str(id))
