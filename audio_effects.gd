extends Node

onready var button_click = $ButtonClick
onready var win = $Win

func play_button_click():
	button_click.play()

func play_win():
	win.play()
