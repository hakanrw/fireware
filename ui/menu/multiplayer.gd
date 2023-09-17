extends Panel

onready var url_input = $VBoxContainer/URLInput.line_edit
onready var pass_input = $VBoxContainer/PasswordInput.line_edit
onready var connect_button = $VBoxContainer/ConnectButton

func _ready():
	connect_button.connect("mouse_clicked", self, "_connect_pressed")
	pass

func _connect_pressed():
	var con_label = connect_button.get_node("Label")
	var url = url_input.text.split(":")
	var password = pass_input.text
	if url.size() == 1: url.append("1337")
	if url.size() != 2:
		con_label.text = "Bad URL."
		return
	
	var res = NetworkController.connect_to_server(url[0], int(url[1]), password)
	if res == false:
		con_label.text = "Connection failed."
