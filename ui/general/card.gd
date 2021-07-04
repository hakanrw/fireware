tool
extends "res://ui/general/button.gd"

export var texture: Texture

func _ready():
	if texture: 
		$TextureRect.texture = texture
