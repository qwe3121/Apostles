extends CharacterBody2D


@export var speed = 100
var default_speed
var ulti_speed
var position_before_ulti: Vector2

@export var b_drops = 10

var see_player = false

@onready var anim = $AnimationPlayer
@onready var chase_timer = $ChaseTimer
@onready var walking_timer = $WalkingTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var flashlight_timer = $FlashlightTimer
@onready var blood = $Blood
@onready var attack_cooldown = $AttackCooldown
@onready var ulti_cooldown = $UltiCooldown
@onready var enemy_hitbox = $EnemyHitbox
@onready var blood_pos = $BloodPos
@onready var qmark = $Qmark
@onready var ulti_hitbox = $EnemyHitbox/Ulti
@onready var attack_hitbox = $EnemyHitbox/Attack
@onready var eyes = $Eyes


@onready var sprite_of_parent_level = get_parent().get_node("Sprite2D")

var blood_drop = preload("res://src/blood_drop.tscn")

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum {IDLE, RUN, ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, FRUIT_DEAD}
var state = IDLE : set = set_state

func set_state(value):
	if not state == value: state_started = false
	state = value

var anim_dir = 1

var state_started = false

var can_attack = true
var can_ulti = true
var need_to_reset_ulti = false

var walking = 1 #1 is walking 0 is chilling

var chasing = false
var chasing_dir

var there_is_blocked_area = false

var is_on_wall

var hp = 400

var turned = false

var flashing = 0
var knockback_dir = 0

var last_knockback_dir = 0

var player_is_inside = false

var fruit_ninja_anim_index = 1

var destination
var pre_destination
@onready var nav_agent = $NavigationAgent2D

var close_en_to_attack = false

@onready var physics_ticks_per_second = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")


func refresh_desired_distance():
	nav_agent.path_desired_distance = ceil(speed / physics_ticks_per_second)
	nav_agent.target_desired_distance = ceil(speed / physics_ticks_per_second)


func _ready():
	default_speed = speed
	ulti_speed = speed * 2
	
	refresh_desired_distance()
	
	blood.modulate.a = randf_range(0.6, 1.0)
	walking_timer_start()
	

func get_damage(value, k_dir = 0, dead_by_trap: bool = false):
	hp -= value
	if k_dir: 
		last_knockback_dir = k_dir
	if hp <= 0:
		chase_timer.stop()
		walking_timer.stop()
		state = DEAD
	elif not flashing:
		knockback_dir = k_dir
		pre_destination = destination
		set_destination(global_position + Vector2(100 * knockback_dir, 0))
		flashing = 1
		animated_sprite.material.set_shader_parameter("flash_modifier", 1.0)
		flashlight_timer.start()
	if not dead_by_trap: global.camera.shake()
		
		
func set_anim(animation_name):
	animated_sprite.flip_h = anim_dir == 1
	animated_sprite.position.x = 3 * anim_dir
	blood.flip_h = !(last_knockback_dir == 1)
	blood.position.x = 24 * last_knockback_dir

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
		if not knockback_dir:
			return
	
	if nav_agent.is_target_reached() or nav_agent.distance_to_target() < 2.0:
		return
	if nav_agent.is_target_reachable():
		var target = nav_agent.get_next_path_position()
		var nav_velocity = global_position.direction_to(target).normalized() * speed
#		nav_agent.set_velocity(nav_velocity) # FOR RVO AVOIDANCE
		velocity = nav_velocity
		move_and_slide()


# FOR RVO AVOIDANCE

#func _on_navigation_agent_2d_velocity_computed(safe_velocity):
#	velocity = safe_velocity
#	move_and_slide()


func set_anim_dir():
	if not knockback_dir:
		if velocity.x < 0:
			anim_dir = -1
		elif velocity.x > 0:
			anim_dir = 1
		

func _physics_process(delta):
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
				position_before_ulti = global_position
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
			if not knockback_dir: set_destination(global_position + Vector2(randi_range(50, 200) * rand_minus_or_plus(), 0))
			set_anim(IDLE)
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
				position_before_ulti = global_position
				state = BEFORE_ULTI
				return
			if can_attack:
				state = ATTACK
				return
		elif close_en_to_attack:
			state = IDLE
			return
			
		if not knockback_dir: set_destination(Vector2(global.player.global_position.x, global_position.y))
	
	elif chasing:
		if not knockback_dir: set_destination(Vector2(global_position.x + 150 * chasing_dir, global_position.y))
	
	set_anim_dir()
	set_anim(RUN)
	
	
func attack():
	set_anim(ATTACK)
	if !state_started:
		state_started = true
		can_ulti = false
		can_attack = false
		need_to_reset_ulti = true
		await anim.animation_finished
		if state == ATTACK:
			attack_cooldown.start()
			if not see_player:
				chasing = false
				walking = 0
				walking_timer_start()
			global.player.flying_cause_of_mk6 = false
			state = IDLE

			
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
	if !state_started:
		state_started = true
		set_destination(position_before_ulti)
#		await nav_agent.target_reached
	if global_position.distance_to(position_before_ulti) < 5.0:
		if state == AFTER_ULTI:
			ulti_cooldown.start()
			attack_cooldown.start()
			if not see_player:
				chasing = false
				walking = 0
				walking_timer_start()
			state = IDLE
	
	
func dead():
	set_anim(DEAD)
	if !state_started:
		state_started = true
		ulti_hitbox.disabled = true
		attack_hitbox.disabled = true
		for c in range(b_drops):
			var blood_drop_instance = blood_drop.instantiate()
			sprite_of_parent_level.add_child(blood_drop_instance)
			blood_drop_instance.x_vel = randi_range(-800, -500) if last_knockback_dir == -1 else randi_range(500, 800)
			blood_drop_instance.global_position = blood_pos.global_position
		await anim.animation_finished
		if state == DEAD:
			queue_free()


func _on_walking_timer_timeout():
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
	if need_to_reset_ulti:
		need_to_reset_ulti = false
		can_ulti = true
	
	
func _on_ulti_cooldown_timeout():
	if not need_to_reset_ulti:
		can_ulti = true


func _on_eyes_body_entered(body):
	if check_if_vision_is_blocked_by_wall():
		return
	if not chasing and can_attack:
		qmark.visible = true
		qmark.play("popup")
	set_destination(Vector2(global.player.global_position.x, global_position.y))
	walking_timer.stop()
	chase_timer.stop()
	see_player = true


func _on_eyes_body_exited(body):
	if not see_player:
		return
	see_player = false
	if not state == ATTACK and not state == BEFORE_ULTI and not state == ULTI and not state == AFTER_ULTI:
		if global_position.x > global.player.global_position.x:
			chasing_dir = -1
		else:
			chasing_dir = 1
		chasing = true
		chase_timer.start()
		state = RUN
		
		
func check_if_vision_is_blocked_by_wall():
	var space_state = get_world_2d().get_direct_space_state()
	var params = PhysicsRayQueryParameters2D.new()
	params.from = blood_pos.global_position
	params.to = global.player.blood_pos.global_position
	params.exclude = [self]
	var result = space_state.intersect_ray(params)
	if len(result) == 0: return true
	if result.collider.name == "Player":
		return false
	return true


func _on_chase_timer_timeout():
	chasing = false
	walking = 0
	walking_timer_start()
	state = IDLE


func _on_check_for_blocked_area_area_entered(area):
	there_is_blocked_area = true


func _on_check_for_blocked_area_area_exited(area):
	there_is_blocked_area = false


func _on_flashlight_timer_timeout():
	if flashing == 1:
		animated_sprite.material.set_shader_parameter("flash_modifier", 0.5)
		flashing = 2
		flashlight_timer.start()
	elif flashing == 2:
		animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)
		flashing = 0
		knockback_dir = 0
		
		set_destination(pre_destination)
		
		#these two needs test
		velocity.y = 0
		velocity.x = 0
		####################
		
		
func kill_with_fruit_ninja():
	fruit_ninja_anim_index = randi_range(1, 8)
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
		ulti_hitbox.disabled = true
		attack_hitbox.disabled = true
		last_knockback_dir = 1 if global_position > global.player.global_position else -1
		for c in range(b_drops):
			var blood_drop_instance = blood_drop.instantiate()
			sprite_of_parent_level.add_child(blood_drop_instance)
			blood_drop_instance.x_vel = randi_range(-800, -500) if last_knockback_dir == -1 else randi_range(500, 800)
			blood_drop_instance.global_position = blood_pos.global_position
		await anim.animation_finished
		if state == FRUIT_DEAD:
			events.emit_signal("fruit_kill")
			queue_free()


func _on_attack_hitbox_body_entered(body):
	global.player.flying_cause_of_mk6 = true


func _on_attack_hitbox_body_exited(body):
	global.player.flying_cause_of_mk6 = false
