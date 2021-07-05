tool 
extends HBoxContainer

signal mouse_clicked

export var button_text = "Button"
export var label_text = "Text"
export var duration = 2.0
onready var button = $Button
 
func _ready():
	button.set_text(button_text)
	if Engine.is_editor_hint():
		return
	button.connect("mouse_clicked", self, "_button_clicked")
	if duration != 0.0:
		$Timer.wait_time = duration

func _button_clicked():
	$Label.text = label_text
	emit_signal("mouse_clicked")
	if duration == 0.0:
		return
	$Timer.start()
	yield($Timer, "timeout")
	$Label.text = ""
