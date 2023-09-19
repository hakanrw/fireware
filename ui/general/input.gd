tool
extends HBoxContainer

export var text = "Text"
export var edit_placeholder = ""
export var edit_text = ""

onready var line_edit = $LineEdit

func _ready():
	$Panel/CenterContainer/Label.text = text
	if edit_placeholder:
		line_edit.placeholder_text = edit_placeholder
	if edit_text:
		line_edit.text = edit_text
	pass
