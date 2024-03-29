extends KinematicBody2D

signal player_died
signal player_resurrected
signal player_health_changed(health)
signal player_armor_changed(health)
signal player_money_changed(money)
signal player_weapon_changed(weapon)
signal player_ammo_changed

onready var network_player = $NetworkedPlayer
onready var head = $Head
# onready var hand = $Head/Hand
onready var sprite: Sprite = $Head/Sprite
onready var collision = $Head/Collision
onready var ray = $Head/Ray
onready var knife_ray = $Head/KnifeRay
onready var line = $Head/Line
onready var camera = $Camera
onready var listener = $Listener
onready var shoot_player = $ShootPlayer
onready var reload_player = $ReloadPlayer
onready var throw_player = $ThrowPlayer

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
var health = 0 setget set_health
var armor = 0 setget set_armor
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
	
	if weapon == 5 or weapon == 6:
		sprite.position.y = -22
	else:
		sprite.position.y = -20
	
	if ResourceLoader.exists("res://weapons/audio/shoot/" + str(weapon) + ".wav"):
		shoot_player.stream = load("res://weapons/audio/shoot/" + str(weapon) + ".wav")
	else:
		shoot_player.stream = null
		
	if ResourceLoader.exists("res://weapons/audio/reload/" + str(weapon) + ".wav"):
		reload_player.stream = load("res://weapons/audio/reload/" + str(weapon) + ".wav")
	else:
		reload_player.stream = null
		
	emit_signal("player_weapon_changed", weapon)

func set_money(m: int):
	money = m
	emit_signal("player_money_changed", money)

func set_health(hp: int):
	hp = max(hp, 0)
	if hp == 0 and health > 0:
		visible = false
		set_armor(0)
		emit_signal("player_died")
		global_position = Vector2(0, 0)
	if hp > 0 and health == 0:
		visible = true
		emit_signal("player_resurrected")
		
	health = hp
	emit_signal("player_health_changed", hp)

func set_armor(a: int):
	a = max(a, 0)
	armor = a
	emit_signal("player_armor_changed", a)

func set_name_tag(tag):
	$Nametag.text = tag
	name_tag = tag
	
func shoot():
	shoot_player.play()

	var item = Utils.get_shop_controller().get_weapon_with_id(current_weapon)
	if item == null:
		pass
		
	elif item.type == Utils.WeaponType.MISC: 
		if NetworkController.is_server() or get_tree().get_network_unique_id() == int(name):
			weapons[Utils.WeaponType.MISC].erase(item.id)
		shoot_player.stop()
		throw_player.play()
		set_weapon(30) # set weapon as knife
		
	elif item.type == Utils.WeaponType.PRIMARY or item.type == Utils.WeaponType.SECONDARY:
		var line_vec = ray.cast_to
		
		if ray.is_colliding():
			line_vec = Vector2(ray.global_position.distance_to(ray.get_collision_point()), 0)
		
		line.visible = true
		line.set_point_position(1, line_vec)
		
		if current_weapon in weapon_info: 
			weapon_info[current_weapon]["ammo"] -= 1
	
	last_shoot = Time.get_ticks_msec()
		
	emit_signal("player_ammo_changed")
		
func reload():
	var item = Utils.get_shop_controller().get_weapon_with_id(current_weapon)
	if item == null or item.type == Utils.WeaponType.MISC: return
	
	reload_player.play()
	
	last_shoot = Time.get_ticks_msec() + 1000
	
	if current_weapon in weapon_info:
		var mag = weapon_info[current_weapon]["mag"]
		var current_ammo = weapon_info[current_weapon]["ammo"]
		var to_load = min(item.props["ammo"] - current_ammo, mag)
		weapon_info[current_weapon]["ammo"] = current_ammo + to_load
		weapon_info[current_weapon]["mag"] -= to_load
	
	emit_signal("player_ammo_changed")
	

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
		"armor": armor,
		"weapon": current_weapon,
		"id": int(name),
	}

func set_props(props):
	if "direction" in props:           direction = props["direction"]
	if "rotation" in props : head.global_rotation = props["rotation"]
	if "position" in props :      global_position = props["position"]
	if "speed" in props    :                   speed = props["speed"]
	if "name_tag" in props :          set_name_tag(props["name_tag"])
	if "team" in props     :                  set_team(props["team"])
	if "health" in props   :              set_health(props["health"])
	if "armor" in props    :                set_armor(props["armor"])
	if "weapon" in props   :              set_weapon(props["weapon"])

func player_can_shop():
	return health > 0 and player_in_shop_area() and Utils.get_round_controller().is_shop_enabled()

func player_in_shop_area():
	return true

func load_weapon_instance(weapon: int) -> Node2D:
	return load("res://weapons/" + str(weapon) + ".tscn").instance()
