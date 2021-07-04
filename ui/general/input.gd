tool
extends HBoxContainer

export var text = "Text"
onready var line_edit = $LineEdit

func _ready():
	$Panel/CenterContainer/Label.text = text
	pass
