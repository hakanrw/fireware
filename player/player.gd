extends KinematicBody2D

signal player_died
signal player_resurrected

onready var head = $Head
onready var hand = $Head/Hand

var current_weapon = -1 setget set_weapon
var weapons = {
	Utils.WeaponType.PRIMARY: -1,
	Utils.WeaponType.SECONDARY: -1,
	Utils.WeaponType.MISC: [],
}

var speed = Utils.player_speed
var direction = Vector2(0, 0)
var health = Utils.max_health setget set_health
var money = 0

var name_tag = "Player" setget set_name_tag

var team = Utils.Team.SPECTATOR setget set_team
var next_team = Utils.Team.SPECTATOR

func set_team(_team: int):
	team = _team
	if _team == Utils.Team.SPECTATOR:
		set_health(0)

func set_weapon(weapon: int):
	for n in hand.get_children():
		hand.remove_child(n)
	current_weapon = weapon
	
	if weapon == -1: return
	
	# optimize this
	hand.add_child(load("res://weapons/" + str(weapon) + ".tscn").instance())
	
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
	var round_controller = Utils.get_round_controller()
	if health > 0 and round_controller.move_enabled:
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
		"weapon": current_weapon,
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
	if "weapon" in props   :         set_weapon(props["weapon"])

func player_can_shop():
	return player_in_shop_area() and Utils.get_round_controller().is_shop_enabled()

func player_in_shop_area():
	return true	
