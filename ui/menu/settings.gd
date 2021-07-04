extends Panel

onready var save_button = $VBoxContainer/SaveButton
onready var inputs = {
	"name": $VBoxContainer/NameInput.line_edit,
}

func _ready():
	save_button.connect("mouse_clicked", self, "_save")
	_refresh()
	pass

func _save():
	Globals.player_name = inputs["name"].text
	pass

func _refresh():
	inputs["name"].text = Globals.player_name
	pass
