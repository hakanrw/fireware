extends Node

signal new_round_started
signal timer_updated

onready var timer = $Timer
var _max_round_time = 120
var _game_running_last = false
var _last_player_count = 0
var _reset_flag = false
var _hold_flag = false

var move_enabled = true setget , is_move_enabled

var leaderboard = {
	Utils.Team.INSURGENT: 0,
	Utils.Team.SECURITY: 0,
}

func _ready():
	pass

func _process(delta):
	if not Utils.is_server() or _hold_flag:
		return
	
	var player_count = NetworkController.get_player_nodes().size()
	
	if timer.time_left < 0.1:
		end_round(2)
		
	if _game_running_last != game_running():
		_reset_flag = true
		rpc("update_timer", _max_round_time, 4)
		reset_game()
		
	_game_running_last = game_running()
	_last_player_count = player_count

func reset_game():
	var new_leaderboard = {}
	for key in leaderboard.keys():
		new_leaderboard[key] = "rm"
	rpc("update_leaderboard", new_leaderboard)

func end_round(winner: int):
	rpc("round_ended", winner)
	# update leaderboard
	
	_hold_flag = true
	yield(get_tree().create_timer(4), "timeout")
	start_new_round()
	_hold_flag = false
	pass
	
func start_new_round():
	rpc_id(1, "update_timer", _max_round_time, _max_round_time)
	print(timer.time_left)
	print("starts new round")
	for player in NetworkController.get_player_nodes():
		place_player(player)
		
	NetworkController.rpc("update_players_props", NetworkController.get_players_props())

func players_in_both_teams() -> bool:
	var players = get_players_props_by_teams()
	return players[0].size() > 0 and players[1].size() > 0

func is_move_enabled():
	return not _max_round_time - timer.time_left <= 5
	
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
	
func place_player(player: Node2D, placed_later = false):
	player.health = 100
	player.team = player.next_team
	player.global_position = Vector2(50, 50) # implement this part

	if placed_later:
		var props = NetworkController.get_players_props()
		var op = null
		for prop in props:
			if int(player.name) == prop["id"]:
				op = prop
		NetworkController.rpc("update_players_props", [op])
		
	rpc_id(int(player.name), "new_round_started", _max_round_time, timer.time_left)
	
remote func new_round_started(max_time, remaining_time):
	# this code is called on players
	if 1 == multiplayer.get_rpc_sender_id():
		update_timer(max_time, remaining_time)
		emit_signal("new_round_started")

remote func round_ended(winner: int):
	# this code is called on players
	if 1 == multiplayer.get_rpc_sender_id():
		print("team " + str(winner) + " won the round")
	
remotesync func update_timer(max_time, remaining_time):
	if 1 == multiplayer.get_rpc_sender_id() or multiplayer.get_network_unique_id() == multiplayer.get_rpc_sender_id():
		_max_round_time = max_time
		timer.wait_time = remaining_time
		timer.start()
		emit_signal("timer_updated")

remotesync func update_leaderboard(dict: Dictionary):
	if 1 == multiplayer.get_rpc_sender_id():
		var key_arr = dict.keys()
		var val_arr = dict.values()
		for i in dict.size():
			var key = key_arr[i]
			var value = val_arr[i]
			if str(value) == "rm":
				if key != Utils.Team.INSURGENT and key != Utils.Team.SECURITY:
					leaderboard.erase(key)
			else:
				leaderboard[key] = value
