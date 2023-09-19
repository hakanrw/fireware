extends Node


func _ready():
	if Utils.is_server_enabled():
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
		if Utils.is_auto_join_enabled():
			NetworkController.call_deferred("setup_server", 1337, 16, "", "fw_forest")
		else:
			Utils.call_deferred("load_server_menu")
		
	elif Utils.is_auto_join_enabled():
		NetworkController.connect_to_server("localhost", 1337)
