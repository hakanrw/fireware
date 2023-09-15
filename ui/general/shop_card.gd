extends "res://ui/general/button.gd"

func set_texture(texture: Texture):
	$ColorRect/Control/Texture.texture = texture
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$ColorRect/Control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$ColorRect/Control/Texture.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_price(price: int):
	$CenterContainer2/Label.text = str(price) + "$"
	$CenterContainer2/Label.mouse_filter = Control.MOUSE_FILTER_IGNORE
