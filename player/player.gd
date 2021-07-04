extends KinematicBody2D

onready var head = $Head
onready var hand = $Head/Hand

var speed = 200

func _ready():
	set_name_tag("Test Subject")
	pass
	
var _name_tag = "Player"
var name_tag setget set_name_tag, get_name_tag

func set_name_tag(tag):
	$Nametag.text = tag
	_name_tag = tag
	
func get_name_tag():
	return _name_tag

func full_look_at(vec2d): 
	head.look_at(vec2d)
	if vec2d.distance_to(hand.global_position) > 40:
		hand.look_at(vec2d)
	
func move(direction, delta):
	move_and_collide(speed * delta * direction.normalized())
