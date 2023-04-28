extends CharacterBody2D


var hp = 4
var speed = 150

var close_en_to_attack = false
var close_en_to_ulti = false

var b_drops = 10

var see_player = false

var player_adrenaline_gain = 20

@onready var anim = $AnimationPlayer
@onready var wall_detector_col = $WallDetector/CollisionShape2D
@onready var check_for_blocked_area_col = $CheckForBlockedArea/CollisionShape2D
@onready var chase_timer = $ChaseTimer
@onready var walking_timer = $WalkingTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var flashlight_timer = $FlashlightTimer
@onready var blood = $Blood
@onready var check_for_pit = $CheckForPit
@onready var bullet_pos = $BulletPos
@onready var turned_timer = $TurnedTimer
@onready var attack_cooldown = $AttackCooldown
@onready var ulti_cooldown = $UltiCooldown
@onready var enemy_hitbox_col = $EnemyHitbox/CollisionPolygon2D
@onready var blood_pos = $BloodPos
@onready var qmark = $Qmark
@onready var eyes = $Eyes



@onready var sprite_of_level_foreground = get_parent().get_node("Foreground")
@onready var sprite_of_level_background = get_parent().get_node("Background")

var bullet = preload("res://src/enemies/creeps/grounded/mk1_bullet.tscn")

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum {IDLE, RUN, BEFORE_ATTACK, ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, AIR, FRUIT_DEAD}

func const_to_str(index):
	match index:
		0:
			return "IDLE"
		1:
			return "RUN"
		2:
			return "BEFORE_ATTACK"
		3:
			return "ATTACK"
		4:
			return "BEFORE_ULTI"
		5:
			return "ULTI"
		6:
			return "AFTER_ULTI"
		7:
			return "DEAD"
		8:
			return "AIR"
		9:
			return "FRUIT_DEAD"

var state = AIR : set = set_state

func set_state(value):
	if state == DEAD or state == FRUIT_DEAD:
		return
	
	if not state == value: state_started = false
#	print("from " + const_to_str(state) + " into " + const_to_str(value))
	state = value

var dir = 1
var anim_dir = 1

var state_started = false

var can_attack = true
var can_ulti = true
var need_to_reset_ulti = false

var walking = 1 #1 is walking 0 is chilling

var chasing = false

var there_is_blocked_area = false

var is_on_wall

var turned = false

var flashing = 0
var knockback_dir = 0

var last_knockback_dir = 0

var player_is_inside = false

func _ready():
	blood.modulate.a = randf_range(0.6, 1.0)
	walking_timer_start()
	
	

func get_damage(value, k_dir = 0, dead_by_trap: bool = false):
	if state == DEAD or state == FRUIT_DEAD:
		return
	
	if state == ULTI:
		return
	
	hp -= value
	if k_dir: last_knockback_dir = k_dir
	if hp <= 0:
		chase_timer.stop()
		walking_timer.stop()
		state = DEAD
	elif not flashing:
		knockback_dir = k_dir
		flashing = 1
		animated_sprite.material.set_shader_parameter("flash_modifier", 1.0)
		flashlight_timer.start()
	if not dead_by_trap: global.camera.shake()
		
func set_anim(animation_name):
	animated_sprite.flip_h = anim_dir == 1
	blood.flip_h = !(last_knockback_dir == 1)
	blood.position.x = 30 * last_knockback_dir
	check_for_pit.position.x = 24.75 * anim_dir
	bullet_pos.position.x = 3 * anim_dir
	check_for_blocked_area_col.position.x = 31 * anim_dir
	wall_detector_col.position.x = 15 * anim_dir

	match animation_name:
		IDLE: 
			if chasing or see_player:
				anim.play("idle")
			else:
				anim.play("p_idle")
		RUN: 
			if chasing or see_player:
				anim.play("run")
			else:
				anim.play("p_run")
		BEFORE_ATTACK:
			anim.play("before_attack")
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
			
			
func set_dir():
	if player_is_inside: return
	if global_position.x < global.player.global_position.x:
		dir = 1
	else:
		dir = -1
	anim_dir = dir


func _physics_process(delta):
	if knockback_dir:
		velocity.x = knockback_dir * 100
	
	match state:
		IDLE: 
			idle()
		RUN: 
			run()
		AIR:
			air(delta)
		BEFORE_ATTACK:
			before_attack()
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
			
	move_and_slide()


func idle():
	if not is_on_floor():
		state = AIR
		return
	
	if see_player:
		set_dir()
		if close_en_to_ulti and can_ulti:
			state = BEFORE_ULTI
			return
		if close_en_to_attack and can_attack:
			state = BEFORE_ATTACK
			return
		elif not close_en_to_ulti:
			state = RUN
			return
	else:
		if walking:
			dir = 1 if randi_range(0,1) else -1
			anim_dir = dir
			set_anim(IDLE)
			state = RUN
			return
			
	set_anim(IDLE)
	
	velocity.y = 0
	if not knockback_dir: velocity.x = 0
			
			
func run():
	if not is_on_floor():
		state = AIR
		return
		
	if see_player:
		set_dir()
		if close_en_to_ulti and can_ulti:
			state = BEFORE_ULTI
			return
		if close_en_to_attack and can_attack:
			state = BEFORE_ATTACK
			return
		elif close_en_to_ulti:
			state = IDLE
			return
			
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and not see_player and not chasing:
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and (see_player or chasing):
		dir = 0
		set_anim(IDLE)
	else:
		set_anim(RUN)
		
	velocity.y = 0
	if not knockback_dir: velocity.x = dir * speed
	
	
func air(delta):
	if is_on_floor():
		state = IDLE
		return
		
	set_anim(AIR)
	
	velocity.y += gravity * delta
	if not knockback_dir: velocity.x = 0
	
	
func before_attack():
	set_anim(BEFORE_ATTACK)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
#		can_ulti = false
#		need_to_reset_ulti = true
		can_attack = false
		await anim.animation_finished
		if state == BEFORE_ATTACK:
			state = ATTACK
	
	
func attack():
	set_anim(ATTACK)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ATTACK:
			attack_cooldown.start()
#			can_ulti = true
			if not see_player:
				chasing = false
				walking = 0
				walking_timer_start()
			state = IDLE
			
			
func shoot():
	var bullet_instance = bullet.instantiate()
	bullet_instance.global_position = bullet_pos.global_position
	bullet_instance.dir = anim_dir
	get_parent().get_parent().add_child(bullet_instance)
			
			
func before_ulti():
	set_anim(BEFORE_ULTI)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		attack_cooldown.stop()
		can_attack = false
		can_ulti = false
		await anim.animation_finished
		if state == BEFORE_ULTI:
			state = ULTI
	
	
func ulti():
	set_anim(ULTI)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ULTI:
			state = AFTER_ULTI
			
			
func after_ulti():
	set_anim(AFTER_ULTI)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == AFTER_ULTI:
			ulti_cooldown.start()
			attack_cooldown.start()
			if not see_player:
				chasing = false
				walking = 0
				walking_timer_start()
			set_anim(IDLE)
			state = IDLE
	
	
func dead():
	set_anim(DEAD)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		enemy_hitbox_col.disabled = true
		for c in range(b_drops):
			blood_manager.create_blood(sprite_of_level_background, sprite_of_level_foreground, last_knockback_dir, blood_pos)
		await anim.animation_finished
		if state == DEAD:
			global.player.adrenaline += player_adrenaline_gain
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
	
	
func _on_ulti_cooldown_timeout():
	if not need_to_reset_ulti:
		can_ulti = true


func _on_eyes_body_entered(body):
	if check_if_vision_is_blocked_by_wall():
		return
	if body.name == "Player":
		if not chasing and can_attack:
			qmark.visible = true
			qmark.play("popup")
		walking_timer.stop()
		chase_timer.stop()
		see_player = true


func _on_eyes_body_exited(body):
	if not see_player:
		return
	see_player = false
	if not state == BEFORE_ATTACK and not state == ATTACK and not state == BEFORE_ULTI and not state == ULTI and not state == AFTER_ULTI:
		chasing = true
		chase_timer.start()
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


func _on_turned_timer_timeout():
	turned = false


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
		
		#these two needs test
		velocity.y = 0
		velocity.x = 0
		####################


func _on_wall_detector_body_entered(body):
	is_on_wall = true


func _on_wall_detector_body_exited(body):
	is_on_wall = false


func _on_check_if_player_inside_body_entered(body):
	player_is_inside = true


func _on_check_if_player_inside_body_exited(body):
	player_is_inside = false
	
	
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
		enemy_hitbox_col.disabled = true
		last_knockback_dir = 1 if global_position > global.player.global_position else -1
		for c in range(b_drops):
			blood_manager.create_blood(sprite_of_level_background, sprite_of_level_foreground, last_knockback_dir, blood_pos)
		await anim.animation_finished
		if state == FRUIT_DEAD:
			events.emit_signal("fruit_kill")
			queue_free()
