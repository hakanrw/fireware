extends CanvasLayer

onready var quit_button = $VBoxContainer/QuitButton
onready var settings_button = $VBoxContainer/SettingsButton

func _ready():
	quit_button.connect("mouse_clicked", self, "_quit_game")
	
func _quit_game():
	NetworkController.close_connection()
