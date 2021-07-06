extends Node

var _game_running_last = false

func _ready():
	pass

func _process(delta):
	if not Utils.is_server():
		return
	
	if _game_running_last != game_running():
		start_new_round()
	
	_game_running_last = game_running()

func start_new_round():
	print("starts new round")
	for player in NetworkController.get_player_nodes():
		place_player(player)
		
	NetworkController.rpc("update_players_props", NetworkController.get_players_props())

func players_in_both_teams() -> bool:
	var players = get_players_props_by_teams()
	return players[0].size() > 0 and players[1].size() > 0

func game_running() -> bool:
	return players_in_both_teams()

func get_players_props_by_teams() -> Dictionary:
	var players_dict = {
		Utils.Team.SECURITY : [],
		Utils.Team.INSURGENT: [],
		Utils.Team.SPECTATOR: []
	}
	
	for player_props in NetworkController.get_players_props():
		players_dict[player_props["team"]].append(player_props)
		
	return players_dict
	
func place_player(player: Node2D):
	player.health = 100
	player.team = player.next_team
	player.global_position = Vector2(50, 50) # implement this part

	if not game_running():
		var props = NetworkController.get_players_props()
		var op = null
		for prop in props:
			if int(player.name) == prop["id"]:
				op = prop
		NetworkController.rpc("update_players_props", [op])
	# add code to initiate player in round start
	pass
