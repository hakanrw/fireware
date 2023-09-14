extends CanvasLayer

onready var chat_box = $Control/ChatBox
onready var write = $Control/Write
onready var line_edit = $Control/Write/LineEdit

var message_template = preload("./message.tscn")

var focus = false

func _ready():
	line_edit.connect("text_entered", self, "_on_text_submit")
	line_edit.connect("focus_exited", self, "unfocus")

func _process(delta):
	if Input.is_action_just_pressed("chat") and Utils.get_chat_controller().focus == false:
		Utils.get_chat_controller().focus()

remotesync func send_message(message: String, markdown: bool = false):
	var sender = multiplayer.get_rpc_sender_id()
	var sender_name = ""
	if sender == 1:
		sender_name = "server"
	else:
		sender_name = NetworkController.get_player_with_id(sender).name_tag
	
	if sender == 1 and markdown:
		insert_message(message.strip_edges(true, true).substr(0, 50))
	else:
		insert_message(sender_name + ": " + message.strip_edges(true, true).substr(0, 50))
	
func insert_message(message_text: String):
	var message = message_template.instance()
	message.get_node("Label").text = message_text
	chat_box.add_child(message)

	if chat_box.get_children().size() > 5:
		chat_box.get_children()[0].queue_free()

	yield(get_tree().create_timer(10), "timeout")
	var tween = get_tree().create_tween()
	tween.tween_property(message, "modulate:a", 0, 0.5)
	tween.bind_node(message)

func focus():
	write.visible = true
	chat_box.margin_bottom = -140
	line_edit.grab_focus()
	
	focus = true
		
func unfocus():
	if focus == false: return
	
	write.visible = false
	chat_box.margin_bottom = -100
	line_edit.release_focus()
		
	focus = false
	
func _on_text_submit(text):
	if text == "": 
		unfocus()
		return
	
	line_edit.text = ""
	
	if text.begins_with("/"):
		Utils.get_command_controller().rpc_id(1, "execute_command_message", text.substr(1))
	else:
		rpc("send_message", text)
	unfocus()
