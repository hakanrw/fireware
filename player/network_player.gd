extends Node

onready var player = get_node("..")

puppet func set_direction(direction: Vector2):
	player.direction = direction.normalized()

puppet func set_rotation(rotation: float):
	player.head.global_rotation = rotation

remotesync func set_name_tag(name_tag: String):
	if 1 == multiplayer.get_rpc_sender_id():
		player.name_tag = name_tag
		return
		
	if NetworkController.is_server():
		name_tag = name_tag.strip_edges(true, true)
		name_tag = name_tag.substr(0, 15)
		
		var player_nodes: Array = Utils.get_players_node().children
		var names = Array()
		for player_node in player_nodes:
			names.append(player_node.name_tag)
		
		var idx = 0
		var name_tag_after = name_tag
		while name_tag_after in names:
			idx += 1
			name_tag_after = name_tag + str(idx)
			
		name_tag = name_tag_after 
		rpc("set_name_tag", name_tag)
		
remote func set_health(hp):
	if 1 == multiplayer.get_rpc_sender_id():
		player.health = hp

remote func set_props(props):
	if 1 == multiplayer.get_rpc_sender_id():
		player.set_props(props)

remotesync func set_team(team: int):
	if 1 == multiplayer.get_rpc_sender_id():
		player.team = team
		return
		
	if NetworkController.is_server():
		if team < 0 or team > 2: return
		if player.team == team: return
		
		player.next_team = team
		player.health = 0
		
		if not Utils.get_round_controller().game_running():
			Utils.get_round_controller().place_player(player)
		else:
			rpc("set_health", 0)
