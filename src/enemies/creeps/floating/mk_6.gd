extends CharacterBody2D


var close_en_to_attack = false


var need_to_slow_player = false
var need_player_to_fly = false


var hp = 3
var speed = 150
var default_speed
var ulti_speed
var y_pos_before_ulti

var b_drops = 10

var see_player = false
var player_adrenaline_gain = 20

@onready var anim = $AnimationPlayer
@onready var chase_timer = $ChaseTimer
@onready var walking_timer = $WalkingTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var flashlight_timer = $FlashlightTimer
@onready var blood = $Blood
@onready var attack_cooldown = $AttackCooldown
@onready var ulti_cooldown = $UltiCooldown
@onready var blood_pos = $BloodPos
@onready var attack_hitbox = $AttackHitbox/AttackCollision
@onready var ulti_slow_hitbox = $UltiSlowHitbox/UltiSlow
@onready var rocks_dropdown_hitbox = $RocksDropdownHitbox/Col
@onready var ulti_dropdown_hitbox = $UltiDropdownHitbox/Col
@onready var dead_zone = $AnimatedSprite2D/DeadZone
var need_to_check_if_see_player = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum {IDLE, RUN, ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, FRUIT_DEAD}

func const_to_str(index):
	match index:
		0:
			return "IDLE"
		1:
			return "RUN"
		2:
			return "ATTACK"
		3:
			return "BEFORE_ULTI"
		4:
			return "ULTI"
		5:
			return "AFTER_ULTI"
		6:
			return "DEAD"
		7:
			return "FRUIT_DEAD"

var state = IDLE : set = set_state

func set_state(value):
	if state == DEAD or state == FRUIT_DEAD:
		return
	
	if not state == value: state_started = false
#	print("from " + const_to_str(state) + " into " + const_to_str(value))
	state = value

var anim_dir = 1

var state_started = false

var can_attack = true
var can_ulti = true

var walking = 1 #1 is walking 0 is chilling

var chasing = false
var chasing_dir

var is_on_wall

var turned = false

var flashing = 0

var last_knockback_dir = 0

var player_is_inside = false

var destination
@onready var nav_agent = $NavigationAgent2D

@onready var physics_ticks_per_second = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")


func refresh_desired_distance():
	nav_agent.path_desired_distance = ceil(speed / physics_ticks_per_second)
	nav_agent.target_desired_distance = ceil(speed / physics_ticks_per_second)


func _ready():
	animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)
	
	y_pos_before_ulti = global_position.y
	
	default_speed = speed
	ulti_speed = speed * 2
	
	refresh_desired_distance()
	
	blood.modulate.a = randf_range(0.6, 1.0)
	
	
func _on_walking_timer_ready():
	$WalkingTimer.wait_time = randi_range(1,5)
	$WalkingTimer.start()
	

func get_damage(value, k_dir = 0, damager = null):
	if state == DEAD or state == FRUIT_DEAD:
		return
	
	hp -= value
	if k_dir: 
		last_knockback_dir = k_dir
	if hp <= 0:
		chase_timer.stop()
		walking_timer.stop()
		if damager != null:
			if damager.name == "TrapHitbox":
				damager.turn_into_bloody_version()
		else:
			global.player.adrenaline += player_adrenaline_gain
		state = DEAD
	elif not flashing:
		flashing = 1
		animated_sprite.material.set_shader_parameter("flash_modifier", 1.0)
		flashlight_timer.start()
	global.camera.shake()
		
		
func set_anim(animation_name):
	animated_sprite.flip_h = anim_dir == 1
	animated_sprite.position.x = 3 * anim_dir
	blood.flip_h = !(last_knockback_dir == 1)
	blood.position.x = 30 * last_knockback_dir

	match animation_name:
		IDLE: 
			if chasing or see_player:
				anim.play("idle_run")
			else:
				anim.play("p_idle_run")
		RUN: 
			if chasing or see_player:
				anim.play("idle_run")
			else:
				anim.play("p_idle_run")
		ATTACK:
			anim.play("attack")
		BEFORE_ULTI:
			anim.play("before_ulti")
		ULTI:
			anim.play("ulti")
		AFTER_ULTI:
			anim.play("after_ulti")
		DEAD:
			anim.play("dead")
		FRUIT_DEAD:
			anim.play("fruit_ninja_dead")
	
	
func set_destination(new_destination: Vector2):
	destination = new_destination
	nav_agent.set_target_position(destination)
	
	
func start_moving_behavior():
	if not state == RUN and not state == BEFORE_ULTI and not state == AFTER_ULTI:
		return
	
	if nav_agent.is_target_reached() or nav_agent.distance_to_target() < 2.0:
		return
	
	if nav_agent.is_target_reachable():
		var target = nav_agent.get_next_path_position()
		var nav_velocity = global_position.direction_to(target).normalized() * speed
#		nav_agent.set_velocity(nav_velocity) # FOR RVO AVOIDANCE (traps, for example, as I understand)
		velocity = nav_velocity
		move_and_slide()


# FOR RVO AVOIDANCE (traps, for example, as I understand)

#func _on_navigation_agent_2d_velocity_computed(safe_velocity):
#	velocity = safe_velocity
#	move_and_slide()


func set_anim_dir():
	if velocity.x < 5:
		anim_dir = -1
	elif velocity.x > 5:
		anim_dir = 1
		

func _physics_process(delta):
	if need_to_check_if_see_player:
		if not check_if_vision_is_blocked_by_wall() and visible_on_screen:
			on_see_player()
		else:
			on_unsee_player()
			
	if need_player_to_fly:
		global.player.flying_cause_of_mk6 = true
		
	if need_to_slow_player:
		global.player.slowed_cause_of_mk6 = true
	
	match state:
		IDLE: 
			idle()
		RUN: 
			run()
		ATTACK:
			attack()
		BEFORE_ULTI:
			before_ulti()
		ULTI:
			ulti()
		AFTER_ULTI:
			after_ulti()
		DEAD:
			dead()
		FRUIT_DEAD:
			fruit_dead()
			
	start_moving_behavior()


func idle():
	if see_player:
		if close_en_to_attack:
			if can_attack and can_ulti:
				speed = ulti_speed
				refresh_desired_distance()
				state = BEFORE_ULTI
				return
			if can_attack:
				state = ATTACK
				return
		elif not close_en_to_attack:
			state = RUN
			return
	else:
		if walking: 
			set_destination(global_position + Vector2(randi_range(50, 100) * rand_minus_or_plus(), 0))
			state = RUN
			return
			
	set_anim(IDLE)
	
	
func rand_minus_or_plus():
	return 1 if randi_range(0, 1) else -1
			
			
func run():
	if see_player:
		if close_en_to_attack:
			if can_attack and can_ulti:
				speed = ulti_speed
				refresh_desired_distance()
				state = BEFORE_ULTI
				return
			if can_attack:
				state = ATTACK
				return
		elif close_en_to_attack:
			state = IDLE
			return
			
		set_destination(Vector2(global.player.global_position.x, global_position.y))
	
	elif chasing:
		set_destination(Vector2(global_position.x + 10 * chasing_dir, global_position.y))
	
	set_anim_dir()
	set_anim(RUN)
	
	
func attack():
	set_anim(ATTACK)
	if !state_started:
		state_started = true
		can_attack = false
		await anim.animation_finished
		if state == ATTACK:
			attack_cooldown.start()
			if not chasing:
				walking = 0
				walking_timer_start()
				state = IDLE
			else:
				state = RUN

			
func before_ulti():
	set_anim(BEFORE_ULTI)
	set_destination(Vector2(global_position.x, global_position.y + 10))
	if !state_started:
		state_started = true
		attack_cooldown.stop()
		can_attack = false
		can_ulti = false
	if is_on_floor():
		if state == BEFORE_ULTI:
			state = ULTI
			
			
func ulti():
	set_anim(ULTI)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ULTI:
			speed = default_speed
			refresh_desired_distance()
			state = AFTER_ULTI
			
			
func after_ulti():
	set_anim(AFTER_ULTI)
	set_destination(Vector2(global_position.x, global_position.y - 10))
	if global_position.y - y_pos_before_ulti <= 1:
		if state == AFTER_ULTI:
			ulti_cooldown.start()
			attack_cooldown.start()
			global_position.y = y_pos_before_ulti
			if not chasing:
				walking = 0
				walking_timer_start()
				state = IDLE
			else:
				state = RUN
	
	
func dead():
	set_anim(DEAD)
	if !state_started:
		state_started = true
		attack_hitbox.disabled = true
		rocks_dropdown_hitbox.disabled = true
		ulti_dropdown_hitbox.disabled = true
		ulti_slow_hitbox.disabled = true
		dead_zone.visible = false
		for c in range(b_drops):
			blood_manager.create_blood_drops(last_knockback_dir, blood_pos)
		await anim.animation_finished
		if state == DEAD:
			queue_free()


func _on_walking_timer_timeout():
	if not state == ATTACK and not state == BEFORE_ULTI and not state == ULTI and not state == AFTER_ULTI:
		if walking:
			walking = 0
			state = IDLE
		else:
			walking = 1
		walking_timer_start()
	
	
func walking_timer_start():
	walking_timer.wait_time = randi_range(1,5)
	walking_timer.start()
	
	
func _on_attack_cooldown_timeout():
	can_attack = true
	
	
func _on_ulti_cooldown_timeout():
	can_ulti = true


func _on_eyes_body_entered(body):
	need_to_check_if_see_player = true
	
	
func _on_eyes_body_exited(body):
	need_to_check_if_see_player = false
	on_unsee_player()
	
	
func on_see_player():
	if see_player:
		return
		
	walking_timer.stop()
	chase_timer.stop()
	see_player = true


func on_unsee_player():
	if not see_player:
		return
	
	if state == DEAD or state == FRUIT_DEAD:
		return
		
	see_player = false
	
	if global_position.x > global.player.global_position.x:
		chasing_dir = -1
	else:
		chasing_dir = 1
	chasing = true
	chase_timer.start()
	
	if not state == ATTACK and not state == BEFORE_ULTI and not state == ULTI and not state == AFTER_ULTI:
		state = RUN
		
		
func check_if_vision_is_blocked_by_wall():
	var space_state = get_world_2d().get_direct_space_state()
	var params = PhysicsRayQueryParameters2D.new()
	params.from = blood_pos.global_position
	params.to = global.player.blood_pos.global_position
	params.exclude = [self]
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.hit_from_inside = true
	params.collision_mask = 0b00000000000010000010
	var result = space_state.intersect_ray(params)
	if len(result) == 0: return true
	if result.collider.name == "Player":
		return false
	return true


func _on_chase_timer_timeout():
	chasing = false
	if not state == ATTACK and not state == BEFORE_ULTI and not state == ULTI and not state == AFTER_ULTI:
		walking = 0
		walking_timer_start()
		state = IDLE


func _on_flashlight_timer_timeout():
	if flashing == 1:
		animated_sprite.material.set_shader_parameter("flash_modifier", 0.5)
		flashing = 2
		flashlight_timer.start()
	elif flashing == 2:
		animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)
		flashing = 0
		
		if not is_on_floor():
			velocity.y = 0
			velocity.x= 0
		
		
func kill_with_fruit_ninja():
	chase_timer.stop()
	walking_timer.stop()
	state = FRUIT_DEAD
	global.camera.shake()
	
	
func fruit_dead():
	set_anim(FRUIT_DEAD)
	velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		attack_hitbox.disabled = true
		rocks_dropdown_hitbox.disabled = true
		ulti_dropdown_hitbox.disabled = true
		ulti_slow_hitbox.disabled = true
		dead_zone.visible = false
		last_knockback_dir = 1 if global_position > global.player.global_position else -1
		for c in range(b_drops):
			blood_manager.create_blood_drops(last_knockback_dir, blood_pos)
		await anim.animation_finished
		if state == FRUIT_DEAD:
			events.emit_signal("fruit_kill")
			queue_free()


func _on_attack_hitbox_body_entered(body):
	need_player_to_fly = true


func _on_attack_hitbox_body_exited(body):
	need_player_to_fly = false
	global.player.flying_cause_of_mk6 = false
	
	
func shake_camera():
	if dead_zone_visible_on_screen: global.camera.shake()


func _on_ulti_slow_hitbox_body_entered(body):
	need_to_slow_player = true


func _on_ulti_slow_hitbox_body_exited(body):
	need_to_slow_player = false
	global.player.slowed_cause_of_mk6 = false


func is_alive():
	if state != DEAD and state != FRUIT_DEAD:
		return true
	return false
	
	
var dead_zone_visible_on_screen = false


func _on_dead_zone_visible_on_screen_notifier_screen_entered():
	dead_zone_visible_on_screen = true


func _on_dead_zone_visible_on_screen_notifier_screen_exited():
	dead_zone_visible_on_screen = false


var visible_on_screen = false


func _on_visible_on_screen_notifier_2d_screen_entered():
	visible_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	visible_on_screen = false
