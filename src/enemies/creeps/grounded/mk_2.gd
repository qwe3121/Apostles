extends CharacterBody2D


@export var speed = 150

@export var x_attack_dis_attack = 70
@export var x_attack_dis_ulti = 140
#@export var y_attack_dis = 50

var see_player = false

@onready var anim = $AnimationPlayer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum {IDLE, RUN, BEFORE_ATTACK, ATTACK, AFTER_ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, AIR}
var state = AIR : set = set_state

func set_state(value):
	state_started = false
	state = value

var dir = 1
var anim_dir = 1

var state_started = false

var can_attack = true
var can_ulti = false

var walking = 1 #1 is walking 0 is chilling

var chasing = false

var there_is_blocked_area = false

var is_on_wall

var hp = 4

var turned = false

var flashing = 0
var knockback_dir = 0

var player_is_inside = false


func _ready():
	$AnimatedSprite2D.material.set_shader_parameter("flash_modifier", 0.0)
	$EnemyHitbox/AttackCollision.disabled = true
	$EnemyHitbox/UltiCollision.disabled = true
	walking_timer()
	


func get_damage(value, k_dir = 0):
	hp -= value
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
	if anim_dir == 1:
		$AnimatedSprite2D.flip_h = true
		$CheckForPit.position.x = 24.75
		$EnemyHitbox.scale.x = -1
		$CheckForBlockedArea/CollisionShape2D.position.x = 31
		$Eyes/CollisionShape2D.position.x = 37.25
		$WallDetector/CollisionShape2D.position.x = 18.25
	elif anim_dir == -1:
		$AnimatedSprite2D.flip_h = false
		$CheckForPit.position.x = -24.75
		$EnemyHitbox.scale.x = 1
		$CheckForBlockedArea/CollisionShape2D.position.x = -31
		$Eyes/CollisionShape2D.position.x = -37.25
		$WallDetector/CollisionShape2D.position.x = -18.25
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
		AFTER_ATTACK:
			anim.play("after_attack")
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
		AFTER_ATTACK:
			after_attack()
		BEFORE_ULTI:
			before_ulti()
		ULTI:
			ulti()
		AFTER_ULTI:
			after_ulti()
		DEAD:
			dead()
			
#	print("is_on_wall() " + str(is_on_wall()))
#	print("pit is here " + str(not $CheckForPit.is_colliding()))
#	print("there is trap " + str(there_is_trap))
#	print("see player " + str(see_player))
#	print("chasing " + str(chasing))
			
	move_and_slide()


func idle():
	velocity.y = 0
	if not knockback_dir: velocity.x = 0
	
	if not is_on_floor():
		state = AIR
		return
	
	if see_player:
		set_dir()
		if close_enough_to_attack() and can_attack:
			if can_ulti:
				state = BEFORE_ULTI
				return
			if can_attack:
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
			
			
func run():
	velocity.y = 0
	if not knockback_dir: velocity.x = dir * speed
	
	if not is_on_floor():
		state = AIR
		return
		
	if see_player:
		set_dir()
		if close_enough_to_attack() and can_attack:
			if can_ulti:
				state = BEFORE_ULTI
				return
			if can_attack:
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
	
	
func air(delta):
	velocity.y += gravity * delta
	if not knockback_dir: velocity.x = 0
	
	if is_on_floor():
		state = IDLE
		return
		
	set_anim(AIR)
	
	
func before_attack():
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	set_anim(BEFORE_ATTACK)
	if !state_started:
		state_started = true
		can_attack = false
		await anim.animation_finished
		if state == BEFORE_ATTACK:
			state = ATTACK
	
	
func attack():
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	set_anim(ATTACK)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ATTACK:
			state = AFTER_ATTACK
			
			
func after_attack():
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	set_anim(AFTER_ATTACK)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == AFTER_ATTACK:
			$AttackCooldown.start()
			state = IDLE
			
			
func before_ulti():
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	set_anim(BEFORE_ULTI)
	if !state_started:
		state_started = true
		can_attack = false
		can_ulti = false
		await anim.animation_finished
		if state == BEFORE_ULTI:
			state = ULTI
	
	
func ulti():
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	set_anim(ULTI)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ULTI:
			state = AFTER_ULTI
			
			
func after_ulti():
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	set_anim(AFTER_ULTI)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == AFTER_ULTI:
			$UltiCooldown.start()
			$AttackCooldown.start()
			state = IDLE
	
	
func dead():
	if not knockback_dir: velocity.x = 0
	velocity.y = 0
	set_anim(DEAD)
	if !state_started:
		state_started = true
#		await anim.animation_finished
		if state == DEAD:
			queue_free()
	
	
func close_enough_to_attack():
	# and abs(abs(player.global_position.y) - abs(global_position.y)) <= y_attack_dis
	if can_ulti:
		return true if abs(abs(global.player.global_position.x) - abs(global_position.x)) <= x_attack_dis_ulti else false
	elif can_attack:
		return true if abs(abs(global.player.global_position.x) - abs(global_position.x)) <= x_attack_dis_attack else false

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
	can_ulti = true


func _on_eyes_body_entered(body):
	can_attack = true
	if not chasing:
		$Qmark.frame = 0
		$Qmark.visible = true
		$Qmark.playing = true
	$WalkingTimer.stop()
	$ChaseTimer.stop()
	$UltiCooldown.start()
	see_player = true


func _on_eyes_body_exited(body):
	$UltiCooldown.stop()
	can_ulti = false
	see_player = false
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
