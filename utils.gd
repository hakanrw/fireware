extends Node

const menu = preload("res://ui/menu/menu.tscn")
const game = preload("res://main.tscn")

enum Team {SECURITY, INSURGENT, SPECTATOR}

func load_menu():
	if get_node("/root").has_node("Menu"):
		return
	if get_node("/root").has_node("Game"):
		get_node("/root/Game").queue_free()
	get_node("/root").add_child(menu.instance())
	
func load_game():
	if get_node("/root").has_node("Game"):
		return
	if get_node("/root").has_node("Menu"):
		get_node("/root/Menu").queue_free()
	get_node("/root").add_child(game.instance())

func is_game_loaded():
	return get_node("/root").has_node("Game") 
	
func show_error_page(error):
	load_menu()
	var menu = get_node("/root/Menu")
	menu._change_pane_page("Error")
	menu.screen.get_node("ErrorMenu/ErrorLabel").text = error
	pass

func get_game_node():
	return get_node("/root/Game")
	
func get_world_node():
	return get_node("/root/Game/World")
	
func get_players_node():
	return get_node("/root/Game/Players")

func get_hud_node():
	return get_node("/root/Game/HUD")

func is_server():
	return "--server" in OS.get_cmdline_args()
	
func get_round_controller():
	return get_node("/root/Game/RoundController")
