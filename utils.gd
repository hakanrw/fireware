extends Node

signal level_changed(level)

const menu = preload("res://ui/menu/menu.tscn")
const game = preload("res://main.tscn")

enum Team {SECURITY, INSURGENT, SPECTATOR}
enum WeaponType {PRIMARY, SECONDARY, MISC, WEAR}

var level_bounds = Vector2(1024, 600)

func load_menu():
	if get_node("/root").has_node("Menu"):
		return
	if get_node("/root").has_node("Game"):
		get_node("/root/Game").queue_free()
		# NetworkController.close_connection()
	
	var menu_instance = menu.instance()
	menu_instance.get_node("Init").queue_free()
	menu_instance.remove_child(menu_instance.get_node("Init"))
	get_node("/root").add_child(menu_instance)
	
func load_game():
	if get_node("/root").has_node("Game"):
		return
	if get_node("/root").has_node("Menu"):
		get_node("/root/Menu").queue_free()
	get_node("/root").add_child(game.instance())

func load_level(level_name: String):
	if get_node("/root").has_node("Game"):
		for n in get_world_node().get_children():
			n.queue_free()
		var level = load("res://levels/" + level_name + ".tscn").instance()
		level.name = level_name
		get_world_node().add_child(level)
		var limit = level.get_node_or_null("Limit")
		if limit == null:
			level_bounds = Vector2(1024, 600) 
		else:
			level_bounds = limit.position
		emit_signal("level_changed", level_name)
		

func is_game_loaded():
	return get_node("/root").has_node("Game") 
	
func show_error_page(error):
	load_menu()
	var menu = get_node("/root/Menu")
	menu._change_pane_page("Error")
	menu.screen.get_node("ErrorMenu/ErrorLabel").text = error
	pass

func get_level_name():
	return get_level_node().name

func get_level_node():
	return get_node("/root/Game/World/").get_children()[0]
	
func get_level_bounds():
	return level_bounds
	
func get_game_node():
	return get_node("/root/Game")
	
func get_world_node():
	return get_node("/root/Game/World")
	
func get_players_node():
	return get_node("/root/Game/Players")

func get_hud_node():
	return get_node("/root/Game/HUD")
	
func get_entities_node():
	return get_node("/root/Game/Entities")

func is_server():
	return "--server" in OS.get_cmdline_args()

func is_auto_join_enabled():
	return "--auto-join" in OS.get_cmdline_args()
	
func get_password_argument():
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--password"):
			return Array(arg.split("="))[1]
			
	return ""

func get_round_controller():
	return get_node("/root/Game/RoundController")
	
func get_shop_controller():
	return get_node("/root/Game/ShopController")
	
func get_entity_controller():
	return get_node("/root/Game/EntityController")
	
func get_chat_controller():
	return get_node("/root/Game/Chat")

func get_command_controller():
	return get_node("/root/Game/CommandController")
	
var max_round_time = 120
var shopping_time = 15
var max_health = 100
var start_money = 1500
var default_team = Team.SPECTATOR
var player_speed = 200
