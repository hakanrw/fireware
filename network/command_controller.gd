extends Node

var ops = []

remotesync func execute_command_message(command_message: String):
	var sender = multiplayer.get_rpc_sender_id()
	
	if not NetworkController.is_server():
		return
	
	if not (sender in ops) and sender != 1:
		Utils.get_chat_controller().rpc_id(sender, "send_message", "no permission to execute command", true)
		return

	var command_args = Array(command_message.split(" "))
	
	var resp = funcref(self, command_args[0]).call_funcv(command_args.slice(1, 16))
	if resp is String:
		Utils.get_chat_controller().rpc("send_message", resp, true)

func lvchange(level_name: String):
	Utils.get_round_controller().change_level(level_name)
	return "changing level to " + level_name

func op(player_name: String):
	var player = NetworkController.get_player_with_name(player_name)
	if player == null:
		return
	
	if not ops.has(int(player.name)):
		ops.append(int(player.name))
		
	return "player " + player_name + " made op"

func deop(player_name: String):
	var player = NetworkController.get_player_with_name(player_name)
	if player == null:
		return

	ops.erase(int(player.name))
	
	return "player " + player_name + " removed from ops"
	
