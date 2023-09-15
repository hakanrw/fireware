extends CanvasLayer

const pages = {
	"team_select": preload("res://ui/hud/team_select.tscn"),
	"alert": preload("res://ui/hud/alert.tscn"),
	"shop": preload("res://ui/hud/shop.tscn"),
	"winner": preload("res://ui/hud/winner.tscn"),
}

const images = {
	"security" : preload("res://ui/icons/special_units.png"),
	"insurgent": preload("res://ui/icons/insurgent.png"),
	"spectator": preload("res://ui/icons/spectator.png"),
}

onready var htd = $Control/VBoxContainer/HTD
onready var hmd = $Control/VBoxContainer/MarginContainer/HMD
onready var hbd = $Control/VBoxContainer/HBD
onready var uname = $Control/VBoxContainer/HTD/HBoxContainer/Panel/Name
onready var level = $Control/VBoxContainer/HTD/HBoxContainer/Panel3/Level

onready var health_label = $Control/VBoxContainer/HBD/HBoxContainer/HealthPanel/Health
onready var money_label = $Control/VBoxContainer/HBD/HBoxContainer/VBoxContainer/MoneyPanel/Money
onready var time_label = $Control/VBoxContainer/HBD/HBoxContainer/VBoxContainer/TimePanel/Time
onready var ammo_panel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Ammo
onready var mag_manel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Magazine

onready var chat_pane = get_node("../Chat")

var current_page = ""

var t_delta = 0

func _ready():
	if Utils.is_server():
		hbd.hide()
		uname.text = "server"
	Utils.connect("level_changed", self, "_on_level_change")
	
func _process(delta):
	t_delta += delta

	if t_delta > 0.2:
		set_time(Utils.get_round_controller().timer.time_left)
		t_delta = 0
	
func _on_level_change(level_name):
	level.text = level_name

func show_team_select():
	show_page("team_select")
	
func show_shop():
	show_page("shop")
	
func clear_page():
	show_page("")
	
func show_page(page: String):
	if Utils.is_server(): return
	
	if current_page == page: return
	current_page = page
	_clear_hud()
	if page == "": 
		chat_pane.get_node("Control").visible = true
		return
	else:
		if not Utils.is_server():
			chat_pane.get_node("Control").visible = false
		
	hmd.add_child(pages[page].instance())
	
func _clear_hud():
	for n in hmd.get_children():
		n.queue_free()
	
func alert(message: String):
	if Utils.is_server(): return
	show_page("alert")
	hmd.get_node("Alert/CenterContainer/Label").text = message

func show_disappearing_alert(message: String):
	clear_page()
	var alert_node = pages["alert"].instance()
	alert_node.modulate.a = 0.8
	hmd.add_child(alert_node)
	hmd.get_node("Alert/CenterContainer/Label").text = message
	
	yield(get_tree().create_timer(2), "timeout")
	var tween = get_tree().create_tween()
	tween.tween_property(alert_node, "modulate:a", 0, 0.5)
	tween.tween_callback(alert_node, "queue_free")
	tween.bind_node(alert_node)

func show_disappearing_winner(winner: int):
	clear_page()
	var winner_node = pages["winner"].instance()
	winner_node.modulate.a = 0.8
	
	var text = "Draw"
	var image = images["spectator"]
	if winner == Utils.Team.SECURITY:
		text = "Security wins"
		image = images["security"]
	if winner == Utils.Team.INSURGENT:
		text = "Insurgents win"
		image = images["insurgent"]
		
	winner_node.get_node("WinnerPanel/CenterContainer/HBoxContainer/LabelContainer/Label").text = text
	winner_node.get_node("WinnerPanel/CenterContainer/HBoxContainer/WinnerImage/TextureRect").texture = image
	winner_node.get_node("ScoresPanel/CenterContainer/HBoxContainer/SecurityScoreContainer/Label").text \
		= str(Utils.get_round_controller().leaderboard[Utils.Team.SECURITY])
	winner_node.get_node("ScoresPanel/CenterContainer/HBoxContainer/InsurgentScoreContainer/Label").text \
		= str(Utils.get_round_controller().leaderboard[Utils.Team.INSURGENT])
	
	Utils.get_chat_controller().insert_message(text.to_lower())
	
	
	hmd.add_child(winner_node)
	
	yield(get_tree().create_timer(3), "timeout")
	var tween = get_tree().create_tween()
	tween.tween_property(winner_node, "modulate:a", 0, 0.5)
	tween.tween_callback(winner_node, "queue_free")
	tween.bind_node(winner_node)

func set_health(health: int):
	health_label.text = str(health)
	
func set_money(money: int):
	money_label.text = str(money)
	
func set_ammo_info(weapon_info):
	if weapon_info == null:
		ammo_panel.visible = false
		mag_manel.visible = false
	else:
		ammo_panel.visible = true
		mag_manel.visible = true
		ammo_panel.text = str(weapon_info["ammo"])
		mag_manel.text = str(weapon_info["mag"])

func set_time(seconds_remaining: int):
	time_label.text = str(int(seconds_remaining) / 60) + ":" + str(int(seconds_remaining) % 60)
