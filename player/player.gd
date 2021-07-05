extends KinematicBody2D

onready var head = $Head
onready var hand = $Head/Hand

var speed = 200
var direction = Vector2(0, 0)

func _ready():
	set_name_tag(name_tag)
	
func _physics_process(delta):
	move(direction, delta)

var name_tag = "Player" setget set_name_tag

func set_name_tag(tag):
	$Nametag.text = tag
	name_tag = tag

func full_look_at(vec2d): 
	head.look_at(vec2d)
	if vec2d.distance_to(hand.global_position) > 40:
		hand.look_at(vec2d)
	
func move(direction, delta):
	move_and_collide(speed * delta * direction.normalized())

func get_props():
	return {
		"direction": direction,
		"rotation": head.global_rotation,
		"position": global_position,
		"speed": speed,
		"name_tag": name_tag,
		"id": int(name),
	}

func set_props(props):
	if "direction" in props: direction =      props["direction"]
	if "rotation" in props : head.global_rotation = props["rotation"]
	if "position" in props : position =        props["position"]
	if "speed" in props    : speed =              props["speed"]
	if "name_tag" in props : name_tag =        props["name_tag"]
