extends CanvasLayer

const pages = {
	"team_select": preload("res://ui/hud/team_select.tscn"),
	"alert": preload("res://ui/hud/alert.tscn"),
	"shop": preload("res://ui/hud/shop.tscn"),
}

onready var htd = $Control/VBoxContainer/HTD
onready var hmd = $Control/VBoxContainer/MarginContainer/HMD
onready var hbd = $Control/VBoxContainer/HBD

onready var health_label = $Control/VBoxContainer/HBD/HBoxContainer/HealthPanel/Health
onready var ammo_panel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Ammo
onready var mag_manel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Magazine

onready var chat_pane = get_node("../Chat")

var current_page = ""

func _ready():
	if Utils.is_server():
		$Control.visible = false
	pass

func show_team_select():
	show_page("team_select")
	
func show_shop():
	show_page("shop")
	
func clear_page():
	show_page("")
	
func show_page(page: String):
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
	show_page("alert")
	hmd.get_node("Alert/CenterContainer/Label").text = message
	
func show_disappearing_alert(message: String):
	clear_page()
	var alert_node = pages["alert"].instance()
	alert_node.modulate.a = 0.75
	hmd.add_child(alert_node)
	hmd.get_node("Alert/CenterContainer/Label").text = message
	
	yield(get_tree().create_timer(2), "timeout")
	var tween = get_tree().create_tween()
	tween.tween_property(alert_node, "modulate:a", 0, 0.5)
	tween.tween_callback(alert_node, "queue_free")
	tween.bind_node(alert_node)

