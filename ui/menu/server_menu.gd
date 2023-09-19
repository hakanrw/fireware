extends Control

onready var level_chooser = $MarginContainer/CenterContainer/VBoxContainer/Settings/MarginContainer/VBoxContainer/LevelBox/OptionButton
onready var port_edit = $MarginContainer/CenterContainer/VBoxContainer/Settings/MarginContainer/VBoxContainer/PortBox/LineEdit
onready var password_edit = $MarginContainer/CenterContainer/VBoxContainer/Settings/MarginContainer/VBoxContainer/PassBox/LineEdit
onready var max_players_edit = $MarginContainer/CenterContainer/VBoxContainer/Settings/MarginContainer/VBoxContainer/MaxPlayersBox/LineEdit
onready var start_button = $MarginContainer/CenterContainer/VBoxContainer/Settings/MarginContainer/VBoxContainer/ButtonBox/Button
onready var status_label = $MarginContainer/CenterContainer/VBoxContainer/Settings/MarginContainer/VBoxContainer/CenterContainer/Label
var current_level = 0

func _ready():
	var levels = []
	
	var dir = Directory.new()
	if dir.open("res://levels") == OK:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while (filename != ""):
			if filename.ends_with(".tscn"):
				levels.append(filename.left(filename.length() - 5))
			filename = dir.get_next()
	
	for level in levels:
		level_chooser.add_item(level)
		
	level_chooser.connect("item_selected", self, "_on_level_set")
	start_button.connect("button_up", self, "_on_start_pressed")

func _on_level_set(id: int):
	current_level = id
	
func _on_start_pressed():
	status_label.text = ""
	
	var port = int(port_edit.text)
	var max_players = int(max_players_edit.text)
	var password = password_edit.text
	var level = level_chooser.get_item_text(current_level)
	
	print("starting server: ", port, " ", max_players, " ", password, " ", level)
	
	var success = NetworkController.setup_server(port, max_players, password, level)
	
	if not success:
		status_label.text = "error while creating server"
