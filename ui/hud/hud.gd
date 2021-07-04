extends Control

onready var htd = $VBoxContainer/HTD
onready var hmd = $VBoxContainer/MarginContainer/HMD
onready var hbd = $VBoxContainer/HBD

onready var health_label = $VBoxContainer/HBD/HBoxContainer/HealthPanel/Health
onready var ammo_panel = $VBoxContainer/HBD/HBoxContainer/AmmoPanel/Ammo
onready var mag_manel = $VBoxContainer/HBD/HBoxContainer/AmmoPanel/Magazine

func _ready():
	pass
