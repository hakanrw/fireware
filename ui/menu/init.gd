extends Node


func _ready():
	if Utils.is_server():
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
		Utils.call_deferred("load_game")
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(1337, 16)
		get_tree().network_peer = peer
		
	if Utils.is_auto_join_enabled():
		NetworkController.connect_to_server("localhost", 1337)
