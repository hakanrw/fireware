extends Node

var version: String = "v0.3"
var is_dev_build: bool = true
var player_name = "subject" setget set_player_name

func set_player_name(new_name):
	player_name = new_name

func get_full_ver_name():
	return version + " developemnt build" if is_dev_build else ""

