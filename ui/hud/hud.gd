extends CanvasLayer

const pages = {
	"team_select": preload("res://ui/hud/team_select.tscn"),
	"shop": preload("res://ui/hud/shop.tscn"),
}

onready var htd = $Control/VBoxContainer/HTD
onready var hmd = $Control/VBoxContainer/MarginContainer/HMD
onready var hbd = $Control/VBoxContainer/HBD

onready var health_label = $Control/VBoxContainer/HBD/HBoxContainer/HealthPanel/Health
onready var ammo_panel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Ammo
onready var mag_manel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Magazine

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
	if page == "": return

	hmd.add_child(pages[page].instance())

	
func _clear_hud():
	for n in hmd.get_children():
		n.queue_free()
	
