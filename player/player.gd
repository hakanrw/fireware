extends KinematicBody2D

signal player_died
signal player_resurrected

onready var head = $Head
onready var hand = $Head/Hand

var speed = 200
var direction = Vector2(0, 0)
var health = 100 setget set_health

var name_tag = "Player" setget set_name_tag

var team = Utils.Team.SPECTATOR setget set_team
var next_team = Utils.Team.SPECTATOR

func set_team(_team: int):
	team = _team
	if _team == Utils.Team.SPECTATOR:
		set_health(0)
	
func set_health(hp: int):
	hp = max(hp, 0)
	if hp == 0 and health > 0:
		visible = false
		global_position = Vector2(0, 0)
		emit_signal("player_died")
	if hp > 0 and health == 0:
		visible = true
		emit_signal("player_resurrected")
		
	health = hp
	
func _ready():
	set_name_tag(name_tag)
	
func _physics_process(delta):
	move(direction, delta)


func set_name_tag(tag):
	$Nametag.text = tag
	name_tag = tag

func full_look_at(vec2d): 
	if health > 0:
		head.look_at(vec2d)
		if vec2d.distance_to(hand.global_position) > 40:
			hand.look_at(vec2d)
		
func move(direction, delta):
	if health > 0:
		move_and_collide(speed * delta * direction.normalized())

func get_props():
	return {
		"direction": direction,
		"rotation": head.global_rotation,
		"position": global_position,
		"speed": speed,
		"name_tag": name_tag,
		"team": team,
		"health": health,
		"id": int(name),
	}

func set_props(props):
	if "direction" in props: direction =      props["direction"]
	if "rotation" in props : head.global_rotation = props["rotation"]
	if "position" in props : global_position = props["position"]
	if "speed" in props    : speed =              props["speed"]
	if "name_tag" in props :     set_name_tag(props["name_tag"])
	if "team" in props     :             set_team(props["team"])
	if "health" in props   :         set_health(props["health"])
	
