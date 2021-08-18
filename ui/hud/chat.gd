extends CanvasLayer

onready var chat_box = $Control/ChatBox

var message_template = preload("./message.tscn")

remotesync func send_message(message: String):
	var sender = multiplayer.get_rpc_sender_id()
	insert_message(str(sender) + ": " + message.strip_edges(true, true).substr(0, 50))
	
func insert_message(message_text: String):
	var message = message_template.instance()
	message.get_node("Label").text = message_text
	chat_box.add_child(message)
