extends Node

signal round_ended(winner)
signal new_round_started
signal timer_updated

onready var timer = $Timer
var _max_round_time = Utils.max_round_time
var _game_running_last = false
var _last_player_count = 0
var _reset_flag = false
var _hold_flag = false
var next_level = ""

var move_enabled = true setget , is_move_enabled

var leaderboard = {
	Utils.Team.INSURGENT: 0,
	Utils.Team.SECURITY: 0,
}

func _ready():
	if Utils.is_server():
		# change_level("de_enka")
		next_level = "fw_forest"
		start_new_round()
		
	connect("round_ended", Utils.get_hud_node(), "show_disappearing_winner")
		
func _process(delta):
	if not Utils.is_server() or _hold_flag:
		return
	
	var player_count = NetworkController.get_player_nodes().size()
	
	if timer.time_left < 0.1:
		end_round(2)
		
	if _game_running_last != game_running():
		_reset_flag = true
		rpc("update_timer", _max_round_time, 1)

	if game_running() and (which_team_died()[0] == true or which_team_died()[1] == true):
		if not _hold_flag: end_round(1 if which_team_died()[0] else 0)
		
	_game_running_last = game_running()
	_last_player_count = player_count

func reset_game():
	# called on server
	var new_leaderboard = {}
	for key in leaderboard.keys():
		new_leaderboard[key] = 0
	
	rpc("update_leaderboard", new_leaderboard)
	
	for player in NetworkController.get_player_nodes():
		if player.next_team != Utils.Team.SPECTATOR:
			player.get_node("NetworkedPlayer").reset_player()
			
	_reset_flag = false

func end_round(winner: int):
	# called on server
	rpc("round_ended", winner)
	# update leaderboard
	
	_hold_flag = true
	yield(get_tree().create_timer(4), "timeout")
	
	# update money
	for player in NetworkController.get_player_nodes():
		if player.next_team != Utils.Team.SPECTATOR:
			var money_total = player.money + 1400
			if player.team == winner:
				money_total += 1400
			var networked_player = player.get_node("NetworkedPlayer")
			networked_player.rpc("set_money", money_total)
			
	start_new_round()
	_hold_flag = false
	pass
	
func start_new_round():
	# called on server
	rpc_id(1, "new_round_started", _max_round_time, _max_round_time)
	print("starts new round")
	rpc("destroy_entities")
	
	if next_level != "":
		rpc("load_level", next_level)
		reset_game()
		for player in NetworkController.get_player_nodes():
			player.next_team = Utils.Team.SPECTATOR
		_game_running_last = false # this line is needed to prevent re-reset on level change
		next_level = ""
	
	if _reset_flag:
		reset_game()
	
	for player in NetworkController.get_player_nodes():
		place_player(player)
		
	NetworkController.rpc("update_players_props", NetworkController.get_players_props())

func players_in_both_teams() -> bool:
	var players = get_players_props_by_teams()
	return players[0].size() > 0 and players[1].size() > 0

func is_move_enabled() -> bool:
	return not _max_round_time - timer.time_left < 5
	
func is_shop_enabled() -> bool:
	return _max_round_time - timer.time_left < Utils.shopping_time
	
func game_running() -> bool:
	return players_in_both_teams()

func which_team_died() -> Array:
	var players = get_players_props_by_teams()
	var dead = [true, true]
	
	for i in [Utils.Team.SECURITY, Utils.Team.INSURGENT]:
		for j in players[i]:
			if j["health"] > 0: dead[i] = false
			
	return dead
	
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
	rpc_id(int(player.name), "new_round_started", _max_round_time, timer.time_left)
	player.team = player.next_team
	if player.team == Utils.Team.SPECTATOR:
		return
		
	if player.health == 0:
		player.network_player.rpc_id(1, "reset_weaponry")
		player.network_player.rpc_id(int(player.name), "reset_weaponry")
	
	player.health = Utils.max_health
	
	var spawn_locations = get_spawn_locations()
	
	# this is bad
	player.global_position = spawn_locations[player.team][int(player.name) % spawn_locations[player.team].size()].global_position

	if placed_later:
		var props = NetworkController.get_players_props()
		var op = null
		for prop in props:
			if int(player.name) == prop["id"]:
				op = prop
		NetworkController.rpc("update_players_props", [op])
		
func get_spawn_locations():
	var spawn_locations = {
		Utils.Team.SECURITY: Utils.get_level_node().get_node("Spawn").get_node("Security").get_children(),
		Utils.Team.INSURGENT: Utils.get_level_node().get_node("Spawn").get_node("Insurgent").get_children()
	}
	return spawn_locations
	
remotesync func new_round_started(max_time, remaining_time):
	# called on players
	if 1 == multiplayer.get_rpc_sender_id():
		rpc_id(multiplayer.get_network_unique_id(), "update_timer", max_time, remaining_time)
		emit_signal("new_round_started")
		Utils.get_chat_controller().insert_message("new round started")

remotesync func round_ended(winner: int):
	# called on players and server
	if 1 == multiplayer.get_rpc_sender_id():
		if winner != 2: leaderboard[winner] += 1
		print("team " + str(winner) + " won the round")
		emit_signal("round_ended", winner)
	
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

func change_level(level_name: String):
	if not ResourceLoader.exists("res://levels/" + level_name + ".tscn"):
		printerr("level " + level_name + " doesn't exist")
		return
	
	next_level = level_name
	if not _hold_flag: end_round(2)

remotesync func load_level(level_name: String):
	Utils.get_hud_node().alert("loading level")
	Utils.load_level(level_name)
	Utils.get_hud_node().show_team_select()

remotesync func destroy_entities():
	for entity in Utils.get_entities_node().get_children():
		entity.queue_free()
	
