extends CanvasLayer

const team_select = preload("res://ui/hud/team_select.tscn")

onready var htd = $Control/VBoxContainer/HTD
onready var hmd = $Control/VBoxContainer/MarginContainer/HMD
onready var hbd = $Control/VBoxContainer/HBD

onready var health_label = $Control/VBoxContainer/HBD/HBoxContainer/HealthPanel/Health
onready var ammo_panel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Ammo
onready var mag_manel = $Control/VBoxContainer/HBD/HBoxContainer/AmmoPanel/Magazine

func _ready():
	if Utils.is_server():
		$Control.visible = false
	pass

func show_team_select():
	for n in hmd.get_children():
		hmd.remove_child(n)
		
	hmd.add_child(team_select.instance())
