extends CharacterBody2D


@export var speed = 150

@export var x_attack_dis_attack = 300
@export var x_attack_dis_ulti = 100
#@export var y_attack_dis = 50

@export var b_drops = 10

var see_player = false

@onready var anim = $AnimationPlayer

var blood_drop = preload("res://src/blood_drop.tscn")
var bullet = preload("res://src/enemies/creeps/grounded/mk1_bullet.tscn")

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum {IDLE, RUN, BEFORE_ATTACK, ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, AIR}
var state = AIR : set = set_state

func set_state(value):
	if not state == value: state_started = false
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

var hp = 4

var turned = false

var flashing = 0
var knockback_dir = 0

var last_knockback_dir = 0

var player_is_inside = false

func _ready():
	$Blood.modulate.a = randf_range(0.6, 1.0)
	walking_timer()
	
	

func get_damage(value, k_dir = 0):
	if state == ULTI:
		return
	
	hp -= value
	if k_dir: last_knockback_dir = k_dir
	if hp <= 0:
		$ChaseTimer.stop()
		$WalkingTimer.stop()
		state = DEAD
	elif not flashing:
		knockback_dir = k_dir
		flashing = 1
		$AnimatedSprite2D.material.set_shader_parameter("flash_modifier", 1.0)
		$FlashlightTimer.start()
	global.camera.shake()
		
func set_anim(animation_name):
	$AnimatedSprite2D.flip_h = anim_dir == 1
	$Blood.flip_h = !(last_knockback_dir == 1)
	$Blood.position.x = 30 * last_knockback_dir
	$CheckForPit.position.x = 24.75 * anim_dir
	$BulletPos.position.x = 3 * anim_dir
	$CheckForBlockedArea/CollisionShape2D.position.x = 31 * anim_dir
	$WallDetector/CollisionShape2D.position.x = -15 * anim_dir

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
#		DEAD:
#			anim.play("dead")
			
			
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
			
	move_and_slide()


func idle():
	if not is_on_floor():
		state = AIR
		return
	
	if see_player:
		set_dir()
		if close_enough_to_ulti() and can_ulti:
			state = BEFORE_ULTI
			return
		if close_enough_to_attack() and can_attack:
			state = BEFORE_ATTACK
			return
		elif not close_enough_to_attack():
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
		if close_enough_to_ulti() and can_ulti:
			state = BEFORE_ULTI
			return
		if close_enough_to_attack() and can_attack:
			state = BEFORE_ATTACK
			return
		elif close_enough_to_attack():
			state = IDLE
			return
			
	if (is_on_wall or not $CheckForPit.is_colliding() or there_is_blocked_area) and not turned and not see_player and not chasing:
		turned = true
		$TurnedTimer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not $CheckForPit.is_colliding() or there_is_blocked_area) and (see_player or chasing):
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
			$AttackCooldown.start()
#			can_ulti = true
			if not see_player:
				chasing = false
				walking = 0
				walking_timer()
			state = IDLE
			
			
func shoot():
	var bullet_instance = bullet.instantiate()
	get_parent().get_parent().add_child(bullet_instance)
	bullet_instance.global_position = $BulletPos.global_position
	bullet_instance.dir = anim_dir
			
			
func before_ulti():
	set_anim(BEFORE_ULTI)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		$AttackCooldown.stop()
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
			$UltiCooldown.start()
			$AttackCooldown.start()
			if not see_player:
				chasing = false
				walking = 0
				walking_timer()
			state = IDLE
	
	
func dead():
	set_anim(DEAD)
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		$EnemyHitbox/CollisionPolygon2D.disabled = true
		for c in range(b_drops):
			var blood_drop_instance = blood_drop.instantiate()
			get_parent().get_node("Sprite2D").add_child(blood_drop_instance)
			blood_drop_instance.x_vel = randi_range(-800, -500) if last_knockback_dir == -1 else randi_range(500, 800)
			blood_drop_instance.global_position = $BloodPos.global_position
#		await anim.animation_finished
		if state == DEAD:
			queue_free()
	
	
func close_enough_to_attack():
	return true if global_position.distance_to(global.player.global_position) <= x_attack_dis_attack else false


func close_enough_to_ulti():
	return true if global_position.distance_to(global.player.global_position) <= x_attack_dis_ulti else false


func _on_walking_timer_timeout():
	if walking:
		walking = 0
		state = IDLE
	else:
		walking = 1
	walking_timer()
	
	
func walking_timer():
	$WalkingTimer.wait_time = randi_range(1,5)
	$WalkingTimer.start()
	
	
func _on_attack_cooldown_timeout():
	can_attack = true
	
	
func _on_ulti_cooldown_timeout():
	if not need_to_reset_ulti:
		can_ulti = true


func _on_eyes_body_entered(body):
	if not chasing and can_attack:
		$Qmark.visible = true
		$Qmark.play("popup")
	$WalkingTimer.stop()
	$ChaseTimer.stop()
	see_player = true


func _on_eyes_body_exited(body):
	see_player = false
	if not state == BEFORE_ATTACK and not state == ATTACK and not state == BEFORE_ULTI and not state == ULTI and not state == AFTER_ULTI:
		chasing = true
		$ChaseTimer.start()


func _on_turned_timer_timeout():
	turned = false


func _on_chase_timer_timeout():
	chasing = false
	walking = 0
	walking_timer()
	state = IDLE


func _on_check_for_blocked_area_area_entered(area):
	there_is_blocked_area = true


func _on_check_for_blocked_area_area_exited(area):
	there_is_blocked_area = false


func _on_flashlight_timer_timeout():
	if flashing == 1:
		$AnimatedSprite2D.material.set_shader_parameter("flash_modifier", 0.5)
		flashing = 2
		$FlashlightTimer.start()
	elif flashing == 2:
		$AnimatedSprite2D.material.set_shader_parameter("flash_modifier", 0.0)
		flashing = 0
		knockback_dir = 0


func _on_wall_detector_body_entered(body):
	is_on_wall = true


func _on_wall_detector_body_exited(body):
	is_on_wall = false


func _on_check_if_player_inside_body_entered(body):
	player_is_inside = true


func _on_check_if_player_inside_body_exited(body):
	player_is_inside = false
