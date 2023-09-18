extends "./entity.gd"

var insurgent_sprite = preload("res://entity/dead_player/dead_insurgent.png")
var security_sprite = preload("res://entity/dead_player/dead_security.png")

func _ready():
	if variant == Utils.Team.INSURGENT:
		$Sprite.texture = insurgent_sprite
		
	if variant == Utils.Team.SECURITY:
		$Sprite.texture = security_sprite
