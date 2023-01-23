extends CharacterBody2D


@export var speed = 300

@export var x_attack_dis = 100
#@export var y_attack_dis = 50

var see_player = false

@onready var anim = $AnimationPlayer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum {IDLE, RUN, ATTACK, DEAD, AIR}
var state = AIR : set = set_state

func set_state(value):
	state_started = false
	state = value

var dir = 1
var anim_dir

var state_started = false

var can_attack = true

var walking = 1 #1 is walking 0 is chilling

var chasing = false

var there_is_trap = false

var hp = 5

var turned = false


func _ready():
	walking_timer()
	


func get_damage(value):
	hp -= value
	if hp <= 0:
		$ChaseTimer.stop()
		$WalkingTimer.stop()
		state = DEAD

		
func set_anim(animation_name):
	if anim_dir == 1:
		$Sprite2D.flip_h = true
		$Sprite2D.position.x = 36
		$CheckForPit.position.x = 43
		$EnemyHitbox/CollisionShape2D.position.x = 24
		$CheckForTrap/CollisionShape2D.position.x = 26
	elif anim_dir == -1:
		$Sprite2D.flip_h = false
		$Sprite2D.position.x = -36
		$CheckForPit.position.x = -43
		$EnemyHitbox/CollisionShape2D.position.x = -24
		$CheckForTrap/CollisionShape2D.position.x = -26
	match animation_name:
		IDLE: 
			anim.play("idle", -1, 1, false)
		RUN: 
			anim.play("run", -1, 1, false)
		ATTACK:
			anim.play("attack", -1, 1, false)
		DEAD:
			anim.play("dead", -1, 1, false)
			
			
func set_dir():
	if global_position.x < global.player.global_position.x:
		dir = 1
	else:
		dir = -1
	anim_dir = dir


func _physics_process(delta):
	match state:
		IDLE:
			idle()
		RUN:
			run()
		ATTACK:
			attack()
		DEAD:
			dead()
		AIR:
			air(delta)
			
	move_and_slide()


func idle():
	velocity.y = 0
	velocity.x = 0
	
	if not is_on_floor():
		state = AIR
		return
	
	if see_player:
		set_dir()
		if close_enough_to_attack() and can_attack:
			state = ATTACK
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
	velocity.x = dir * speed
	
	if not is_on_floor():
		state = AIR
		return
		
	if see_player:
		set_dir()
		if close_enough_to_attack() and can_attack:
			state = ATTACK
			return
		elif close_enough_to_attack():
			state = IDLE
			return
			
	if (is_on_wall() or not $CheckForPit.is_colliding() or there_is_trap) and not turned and not see_player and not chasing:
		turned = true
		$TurnedTimer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall() or not $CheckForPit.is_colliding() or there_is_trap) and (see_player or chasing):
		dir = 0
		set_anim(IDLE)
	else:
		set_anim(RUN)
	
	
func air(delta):
	velocity.y += gravity * delta
	velocity.x = 0
	
	if is_on_floor():
		state = IDLE
		return
		
	set_anim(AIR)
	
	
func attack():
	velocity.x = 0
	velocity.y = 0
	set_anim(ATTACK)
	if !state_started:
		state_started = true
		can_attack = false
		$AttackCooldown.start()
		await anim.animation_finished
		state_started = false
		state = RUN
	
	
func dead():
	velocity.x = 0
	velocity.y = 0
	set_anim(DEAD)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == DEAD:
			queue_free()
	
	
func close_enough_to_attack():
	# and abs(abs(player.global_position.y) - abs(global_position.y)) <= y_attack_dis
	return true if abs(abs(global.player.global_position.x) - abs(global_position.x)) <= x_attack_dis else false


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


func _on_eyes_body_entered(body):
	$WalkingTimer.stop()
	$ChaseTimer.stop()
	see_player = true


func _on_eyes_body_exited(body):
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


func _on_check_for_trap_area_entered(area):
	there_is_trap = true


func _on_check_for_trap_area_exited(area):
	there_is_trap = false
