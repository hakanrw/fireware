extends KinematicBody2D

signal player_died
signal player_resurrected
signal player_weapon_changed(weapon)
signal player_health_changed(health)
signal player_ammo_changed
signal player_money_changed(money)

onready var network_player = $NetworkedPlayer
onready var head = $Head
# onready var hand = $Head/Hand
onready var sprite: Sprite = $Head/Sprite
onready var collision = $Head/Collision
onready var ray = $Head/Ray
onready var line = $Head/Line
onready var camera = $Camera
onready var listener = $Listener
onready var shoot_player = $ShootPlayer
onready var reload_player = $ReloadPlayer

var current_weapon = -1 setget set_weapon
var weapons = {
	Utils.WeaponType.PRIMARY: -1,
	Utils.WeaponType.SECONDARY: -1,
	Utils.WeaponType.MISC: [],
}

var weapon_info = {
	
}

var speed = Utils.player_speed
var direction = Vector2(0, 0)
var health = Utils.max_health setget set_health
var money = 0 setget set_money

var name_tag = "Player" setget set_name_tag

var team = Utils.Team.SPECTATOR setget set_team
var next_team = Utils.Team.SPECTATOR

var last_shoot = 0

func _ready():
	set_name_tag(name_tag)
	
func _physics_process(delta):
	move(direction, delta)
	
func _process(delta):
	$Nametag.margin_top = collision.global_position.y - head.global_position.y + 50
	if Time.get_ticks_msec() > last_shoot + 100:
		line.visible = false

func set_team(_team: int):
	team = _team
	if _team == Utils.Team.SPECTATOR:
		set_health(0)
	set_weapon(current_weapon) # to update texture

func set_weapon(weapon: int):
#	for n in hand.get_children():
#		n.queue_free()
	current_weapon = weapon
	
	if weapon == -1: 
		var texture = load("res://icon.png")
		sprite.texture = texture
		sprite.position.y = 0
		return
	# optimize this	
	# hand.add_child(load_weapon_instance(weapon))
	
	var texture = load("res://player/tds/" + ("insurgent" if team == Utils.Team.INSURGENT else "security") + "_" + str(weapon) + ".png")
	sprite.texture = texture
	
	if weapon == 5:
		sprite.position.y = -22
	else:
		sprite.position.y = -20
		
	shoot_player.stream = load("res://weapons/audio/shoot/" + str(weapon) + ".wav")
	reload_player.stream = load("res://weapons/audio/reload/" + str(weapon) + ".wav")
		
	emit_signal("player_weapon_changed", weapon)

func set_money(m: int):
	money = m
	emit_signal("player_money_changed", money)

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
	emit_signal("player_health_changed", hp)


func set_name_tag(tag):
	$Nametag.text = tag
	name_tag = tag

func full_look_at(vec2d): 
	if health > 0:
		head.look_at(vec2d)
#		if vec2d.distance_to(hand.global_position) > 40:
#			hand.look_at(vec2d)
		
func move(direction, delta):
	var round_controller = Utils.get_round_controller()
	if health > 0 and round_controller.move_enabled:
		move_and_collide(speed * delta * direction.normalized())
		position.x = clamp(position.x, 20, Utils.level_bounds.x - 20)
		position.y = clamp(position.y, 20, Utils.level_bounds.y - 20)

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
	return health > 0 and player_in_shop_area() and Utils.get_round_controller().is_shop_enabled()

func player_in_shop_area():
	return true

func load_weapon_instance(weapon: int) -> Node2D:
	return load("res://weapons/" + str(weapon) + ".tscn").instance()
