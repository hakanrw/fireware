tool
extends Panel
signal mouse_clicked

onready var original_color = self_modulate
export var text = "Button"

func set_text(__text):
	if has_node("Label"):
		$Label.text = __text
	else:
		$CenterContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$CenterContainer/Label.text = __text
	text = __text
	
func _ready():
	set_text(text)
	if Engine.is_editor_hint():
		return
	connect("mouse_entered", self, "_mouse_hover", [false])
	connect("mouse_exited", self, "_mouse_hover", [true])
		
func _mouse_hover(out: bool):
	if out: 
		self_modulate = original_color
	else: 
		self_modulate = Color(0.5, 0.5, 0.5)
	
func _mouse_clicked():
	emit_signal("mouse_clicked")
	pass
	
func _input(event):
	# Mouse in viewport coordinates.
	var ms = get_global_mouse_position()
	var nd = rect_global_position
	var size = rect_size
	if ms.x >= nd.x and ms.y >= nd.y and ms.x <= nd.x + size.x and ms.y <= nd.y + size.y:
		if event is InputEventMouseButton and event.is_pressed():
			_mouse_clicked()
