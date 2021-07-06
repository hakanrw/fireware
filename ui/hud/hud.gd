extends Control

const team_select = preload("res://ui/hud/team_select.tscn")

onready var htd = $VBoxContainer/HTD
onready var hmd = $VBoxContainer/MarginContainer/HMD
onready var hbd = $VBoxContainer/HBD

onready var health_label = $VBoxContainer/HBD/HBoxContainer/HealthPanel/Health
onready var ammo_panel = $VBoxContainer/HBD/HBoxContainer/AmmoPanel/Ammo
onready var mag_manel = $VBoxContainer/HBD/HBoxContainer/AmmoPanel/Magazine

func _ready():
	if Utils.is_server():
		visible = false
	pass

func show_team_select():
	for n in hmd.get_children():
		hmd.remove_child(n)
		
	hmd.add_child(team_select.instance())
