extends "./launchable.gd"

var exploded = false

onready var audio_player = $AudioStreamPlayer2D
onready var smoke = $Smoke
onready var explode_area = $ExplodeArea
onready var ray = $RayCast2D

func _ready():
	smoke.texture = load("res://entity/grenade/" + str(variant) + ".png")
	audio_player.stream = load("res://entity/grenade/" + str(variant) + ".wav")
	ray.enabled = true
	add_child(load("res://weapons/" + str(variant) + ".tscn").instance())

func _process(delta):
	
	if launch_time != null and Time.get_ticks_msec() - launch_time > 5000 and not exploded:
		explode()

func explode():
	$Hitbox.disabled = true
	
	linear_velocity = Vector2(0, 0)
	angular_velocity = 0
	exploded = true
	
	$Grenade.visible = false
	audio_player.play()
	smoke.visible = true
	
	if variant == 21:
		
		var tween = get_tree().create_tween()
		tween.set_parallel()
		tween.tween_property(smoke, "modulate:a", 0, 3)
		tween.tween_property(smoke, "rotation", PI / 4, 3)
		tween.bind_node(smoke)
		
		if NetworkController.is_server():
			ray.global_rotation = 0
			var affected_players = explode_area.get_overlapping_bodies()
			for player in affected_players:
				print("bomb blasts " + player.name)
				
				var distance = player.global_position - ray.global_position
				
				ray.cast_to = distance
				ray.force_raycast_update()
				print(distance)
				print(ray.global_position)
				print(player.global_position)
				
				var collider = ray.get_collider()
				var damage = max(200 * (1 - distance.length() / 300), 0) # so that it doesn't heal player
				
				if (collider == null and distance.length() < 35) or collider == player:
					print("with damage: " + str(damage))
					player.network_player.take_damage(damage)
				else:
					print(collider.name)
					print("player behind another")
					
	elif variant == 23:
		yield(get_tree().create_timer(10), "timeout")
		
		var tween = get_tree().create_tween()
		tween.set_parallel()
		tween.tween_property(smoke, "modulate:a", 0, 5)
		tween.tween_property(smoke, "rotation", PI / 4, 5)
		tween.bind_node(smoke)
				
