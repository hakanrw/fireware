extends Node


func _ready():
	if Utils.is_server():
		Utils.call_deferred("load_game")
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(1337, 16)
		get_tree().network_peer = peer
	pass
