extends CharacterBody2D
var np = false


@onready var anim = $AnimationPlayer
@onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycasts
@onready var right_wall_raycasts = $WallRaycasts/RightWallRaycasts
@onready var adrenaline_bar = $CanvasLayer/PlayerUI/AdrenalineBar
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var label = $Label
@onready var weak_combo_timer = $WeakComboTimer
@onready var strong_combo_timer = $StrongComboTimer
@onready var from_jump_to_air_timer = $FromJumpToAirTimer
@onready var can_stand_up_raycasts = $CanStandUpRaycasts
@onready var wall_slide_cooldown = $WallSlideCooldown
@onready var hurtbox_col = $Hurtbox/CollisionShape2D
@onready var hitbox_col = $Hitbox/CollisionShape2D


enum {IDLE, RUN, AIR, JUMP, SIT, CROUCH, ROLL, DASH, WALL_SLIDE, BLOCK, WEAK_ATTACK_1, 
WEAK_ATTACK_2, WEAK_ATTACK_3, WEAK_ATTACK_4, STRONG_ATTACK_1, STRONG_ATTACK_2, STRONG_ATTACK_3, 
STRONG_ATTACK_4, LANDING, FIRST_JUMP_ATTACK_1, FIRST_JUMP_ATTACK_2, FIRST_JUMP_ATTACK_3, 
SECOND_JUMP_ATTACK_1, SECOND_JUMP_ATTACK_2, SECOND_JUMP_ATTACK_3,
DEAD}

var state = IDLE : set = set_state

func set_state(value):
	if value == BLOCK or value == DASH or value == ROLL:
		blocking = true
		events.emit_signal("player_blocking")
	elif state == BLOCK or state == DASH or state == ROLL:
		blocking = false
		events.emit_signal("player_blocking")
	
	if not state == value: single_anim_not_played_yet = true
#	print("from " + str(state) + " to " + str(value) + " with value " + str(single_anim_not_played_yet))
	if not state == value: state_started = false
	state = value

var dir = 1
var anim_dir = 1
var wall_dir = 0

var weak_combo_index = 1
var strong_combo_index = 1
var jump_attack_index = 1

var blocking = false

var jump_index = 1
var pre_jump = 1

var state_started = false
var wall_jumping

var single_anim_not_played_yet = true

var adrenaline = 100 : set = set_adrenaline # dash, roll and strong_attacks

func set_adrenaline(value):
	adrenaline = 100
	adrenaline_bar.value = adrenaline

var speed = 300
var jump_velocity = -600
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var hp = 1


func get_damage():
	if state == DASH:
		return
	
	hp -= 1
	if hp <= 0:
		state_started = false
		state = DEAD
	pass

func set_dir():
	dir = Input.get_axis("LEFT", "RIGHT")
	if dir:
		anim_dir = dir


func set_anim(animation_name):
	if animation_name == WALL_SLIDE:
		animated_sprite.flip_h = wall_dir == -1
	else:
		animated_sprite.flip_h = !(anim_dir == 1)
		hitbox.scale.x = anim_dir
	match animation_name:
		IDLE: 
			anim.play("Idle", -1, 1, false)
		RUN: 
			anim.play("Run", -1, 1, false)
		AIR: 
			if pre_jump == 1 or pre_jump == 0:
				if single_anim_not_played_yet:
					anim.play("FirstAir", -1, 1, false)
				else:
					anim.play("FirstAirCycle", -1, 1, false)
			elif pre_jump == 2:
				if single_anim_not_played_yet:
					anim.play("SecondAir", -1, 1, false)
				else:
					anim.play("SecondAirCycle", -1, 1, false)
		JUMP:
			if pre_jump == 1 or pre_jump == 0:
				if single_anim_not_played_yet:
					anim.play("FirstJump", -1, 3.5, false)
				else:
					anim.play("FirstJumpCycle", -1, 1, false)
			elif pre_jump == 2:
				if single_anim_not_played_yet:
					anim.play("SecondJump", -1, 2, false)
				else:
					anim.play("SecondJumpCycle", -1, 1, false)
		SIT: 
			anim.play("Sit", -1, 1, false)
		CROUCH: 
			anim.play("Crouch", -1, 1, false)
		ROLL:
			anim.play("Roll", -1, 1.5, false) 
		DASH: 
			anim.play("Dash", -1, 20.0, false)
		WALL_SLIDE:
			anim.play("WallSlide", -1, 1, false)
		WEAK_ATTACK_1:
			anim.play("WeakAttack1", -1, 2, false)
		WEAK_ATTACK_2:
			anim.play("WeakAttack2", -1, 2, false)
		WEAK_ATTACK_3:
			anim.play("WeakAttack3", -1, 2, false)
		WEAK_ATTACK_4:
			anim.play("WeakAttack4", -1, 2, false)
		STRONG_ATTACK_1:
			anim.play("StrongAttack1", -1, 0.8, false)
		STRONG_ATTACK_2:
			anim.play("StrongAttack2", -1, 0.8, false)
		STRONG_ATTACK_3:
			anim.play("StrongAttack3", -1, 0.8, false)
		STRONG_ATTACK_4:
			anim.play("StrongAttack4", -1, 0.6, false)
		LANDING:
			anim.play("SecondLanding", -1, 3, false)
		FIRST_JUMP_ATTACK_1:
			anim.play("FirstJumpAttack1", -1, 2, false)
		FIRST_JUMP_ATTACK_2:
			anim.play("FirstJumpAttack2", -1, 2, false)
		FIRST_JUMP_ATTACK_3:
			anim.play("FirstJumpAttack3", -1, 2, false)
		SECOND_JUMP_ATTACK_1:
			anim.play("SecondJumpAttack1", -1, 2, false)
		SECOND_JUMP_ATTACK_2:
			anim.play("SecondJumpAttack2", -1, 1.5, false)
		SECOND_JUMP_ATTACK_3:
			anim.play("SecondJumpAttack3", -1, 1, false)
#		DEAD:
#			anim.play("Dead", -1, 1, false)
		BLOCK:
			anim.play("Block", -1, 1, false)
				
				
				
func _ready():
	global.player = self


func _physics_process(delta):
	match state:
		IDLE:
			label.text = "IDLE"
			idle()
		RUN:
			label.text = "RUN"
			run()
		AIR:
			label.text = "AIR"
			air(delta)
		JUMP:
			label.text = "JUMP"
			jump(delta)
		SIT:
			label.text = "SIT"
			sit()
		CROUCH:
			label.text = "CROUCH"
			crouch()
		WALL_SLIDE:
			label.text = "WALL_SLIDE"
			wall_slide(delta)
		DASH:
			label.text = "DASH"
			dash()
		ROLL:
			label.text = "ROLL"
			roll()
		WEAK_ATTACK_1:
			label.text = "WEAK_ATTACK_1"
			weak_attack_1()
		WEAK_ATTACK_2:
			label.text = "WEAK_ATTACK_2"
			weak_attack_2()
		WEAK_ATTACK_3:
			label.text = "WEAK_ATTACK_3"
			weak_attack_3()
		WEAK_ATTACK_4:
			label.text = "WEAK_ATTACK_4"
			weak_attack_4()
		STRONG_ATTACK_1:
			label.text = "STRONG_ATTACK_1"
			strong_attack_1()
		STRONG_ATTACK_2:
			label.text = "STRONG_ATTACK_2"
			strong_attack_2()
		STRONG_ATTACK_3:
			label.text = "STRONG_ATTACK_3"
			strong_attack_3()
		STRONG_ATTACK_4:
			label.text = "STRONG_ATTACK_4"
			strong_attack_4(delta)
		LANDING:
			label.text = "LANDING"
			landing()
		FIRST_JUMP_ATTACK_1:
			label.text = "FIRST_JUMP_ATTACK_1"
			first_jump_attack_1()
		FIRST_JUMP_ATTACK_2:
			label.text = "FIRST_JUMP_ATTACK_2"
			first_jump_attack_2()
		FIRST_JUMP_ATTACK_3:
			label.text = "FIRST_JUMP_ATTACK_3"
			first_jump_attack_3()
		SECOND_JUMP_ATTACK_1:
			label.text = "SECOND_JUMP_ATTACK_1"
			second_jump_attack_1()
		SECOND_JUMP_ATTACK_2:
			label.text = "SECOND_JUMP_ATTACK_2"
			second_jump_attack_2()
		SECOND_JUMP_ATTACK_3:
			label.text = "SECOND_JUMP_ATTACK_3"
			second_jump_attack_3()
		DEAD:
			label.text = "DEAD"
			dead(delta)
		BLOCK:
			label.text = "BLOCK"
			block()
			
	move_and_slide()


func idle():
	if dir:
		if np:
			print("from idle to run")
		state = RUN
		return
		
	if not is_on_floor():
		if np:
			print("from idle to air")
		jump_index = 2
		state = AIR
		return
		
	if Input.is_action_pressed("DASH") and adrenaline >= 50:
		adrenaline -= 50
		if np:
			print("from idle to DASH")
		state = DASH
		return
		
	if Input.is_action_pressed("BLOCK"):
		if np:
			print("from idle to block")
		state = BLOCK
		return

	if Input.is_action_pressed("RMB ATTACK"):
		if weak_combo_index == 1:
			if np:
				print("from idle to weak_attack_1")
			state = WEAK_ATTACK_1
			weak_combo_index = 2
		elif weak_combo_index == 2:
			if np:
				print("from idle to weak_attack_2")
			state = WEAK_ATTACK_2
			weak_combo_index = 3
		elif weak_combo_index == 3:
			if np:
				print("from idle to weak_attack_3")
			state = WEAK_ATTACK_3
			weak_combo_index = 4
		elif weak_combo_index == 4:
			if np:
				print("from idle to weak_attack_4")
			state = WEAK_ATTACK_4
			weak_combo_index = 1 
		weak_combo_timer.start()
		return
		
	if Input.is_action_pressed("LMB ATTACK") and adrenaline >= 15:
		if strong_combo_index == 1:
			if np:
				print("from idle to strong_attack_1")
			state = STRONG_ATTACK_1
			strong_combo_index = 2
		elif strong_combo_index == 2:
			if np:
				print("from idle to strong_attack_2")
			state = STRONG_ATTACK_2
			strong_combo_index = 3
		elif strong_combo_index == 3:
			if np:
				print("from idle to STRONG_attack_3")
			state = STRONG_ATTACK_3
			strong_combo_index = 4
		elif strong_combo_index == 4:
			if np:
				print("from idle to STRONG_attack_4")
			state = STRONG_ATTACK_4
			strong_combo_index = 1 
		adrenaline -= 15
		strong_combo_timer.start()
		return
		
	if Input.is_action_pressed("ROLL") and adrenaline >= 20:
		adrenaline -= 20
		if np:
			print("from idle to roll")
		state = ROLL
		return
		
	if Input.is_action_pressed("JUMP"):
		if np:
			print("from idle to jump")
		state = JUMP
		return
		
	if Input.is_action_pressed("DOWN"):
		if np:
			print("from idle to sit")
		state = SIT
		return
		
	set_anim(IDLE)
	set_dir()
	
	velocity.x = 0
	velocity.y = 0
		
		
func run():
	if not is_on_floor():
		if np:
			print("from idle to air")
		jump_index = 2
		state = AIR
		return
		
	if Input.is_action_pressed("DASH") and adrenaline >= 50:
		adrenaline -= 50
		if np:
			print("from run to DASH")
		state = DASH
		return
		
	if Input.is_action_pressed("BLOCK"):
		if np:
			print("from run to block")
		state = BLOCK
		return
		
	if Input.is_action_pressed("RMB ATTACK"):
		if weak_combo_index == 1:
			if np:
				print("from idle to weak_attack_1")
			state = WEAK_ATTACK_1
			weak_combo_index = 2
		elif weak_combo_index == 2:
			if np:
				print("from idle to weak_attack_2")
			state = WEAK_ATTACK_2
			weak_combo_index = 3
		elif weak_combo_index == 3:
			if np:
				print("from idle to weak_attack_3")
			state = WEAK_ATTACK_3
			weak_combo_index = 4
		elif weak_combo_index == 4:
			if np:
				print("from idle to weak_attack_4")
			state = WEAK_ATTACK_4
			weak_combo_index = 1 
		weak_combo_timer.start()
		return
		
	if Input.is_action_pressed("LMB ATTACK") and adrenaline >= 15:
		if strong_combo_index == 1:
			if np:
				print("from idle to strong_attack_1")
			state = STRONG_ATTACK_1
			strong_combo_index = 2
		elif strong_combo_index == 2:
			if np:
				print("from idle to strong_attack_2")
			state = STRONG_ATTACK_2
			strong_combo_index = 3
		elif strong_combo_index == 3:
			if np:
				print("from idle to STRONG_attack_3")
			state = STRONG_ATTACK_3
			strong_combo_index = 4
		elif strong_combo_index == 4:
			if np:
				print("from idle to STRONG_attack_4")
			state = STRONG_ATTACK_4
			strong_combo_index = 1 
		adrenaline -= 15
		strong_combo_timer.start()
		return
		
	if Input.is_action_pressed("ROLL") and adrenaline >= 20:
		adrenaline -= 20
		if np:
			print("from run to roll")
		state = ROLL
		return
		
	if Input.is_action_pressed("JUMP"):
		if np:
			print("from run to jump")
		state = JUMP
		return
		
	if Input.is_action_pressed("DOWN"):
		if np:
			print("from run to sit")
		state = SIT
		return
		
	set_anim(RUN)
	set_dir()
	
	velocity.y = 0
	if dir:
		velocity.x = dir * speed
	else:
		if np:
			print("from run to idle")
		state = IDLE
		return
	

func air(delta):
	if is_on_floor():
		if np:
			print("from air to landing")
		jump_index = 1
		jump_attack_index = 1
		state = LANDING
		return
		
	if Input.is_action_pressed("DASH") and adrenaline >= 50:
		adrenaline -= 50
		if np:
			print("from air to DASH")
		state = DASH
		return
		
	if not is_on_floor() and Input.is_action_just_pressed("JUMP") and jump_index == 2:
		jump_attack_index = 4
		jump_index = 0
		pre_jump = 2
		from_jump_to_air_timer.start()
		velocity.y = jump_velocity
		if np:
			print("from AIR to JUMP")
		state = JUMP
		return
		
	if Input.is_action_pressed("RMB ATTACK"):
		from_jump_to_air_timer.stop()
		if pre_jump == 1:
			if jump_attack_index == 1:
				jump_attack_index = 2
				if np:
					print("from air to FIRST_JUMP_ATTACK_1")
				state = FIRST_JUMP_ATTACK_1
				return
			elif jump_attack_index == 2:
				jump_attack_index = 3
				if np:
					print("from air to FIRST_JUMP_ATTACK_2")
				state = FIRST_JUMP_ATTACK_2
				return
			elif jump_attack_index == 3:
				jump_attack_index = 4
				if np:
					print("from air to FIRST_JUMP_ATTACK_3")
				state = FIRST_JUMP_ATTACK_3
				return
		elif pre_jump == 2:
			if jump_attack_index == 4:
				jump_attack_index = 5
				if np:
					print("from air to SECOND_JUMP_ATTACK_1")
				state = SECOND_JUMP_ATTACK_1
				return
			elif jump_attack_index == 5:
				jump_attack_index = 6
				if np:
					print("from air to SECOND_JUMP_ATTACK_2")
				state = SECOND_JUMP_ATTACK_2
				return
			elif jump_attack_index == 6:
				jump_attack_index = 0
				if np:
					print("from air to SECOND_JUMP_ATTACK_3")
				state = SECOND_JUMP_ATTACK_3
				return
		
	if wall_dir and !wall_jumping and !is_on_floor():
		velocity.y = 0
		dir = -wall_dir
		if dir:
			anim_dir = dir
		if np:
			print("from air to WALL_SLIDE")
		state = WALL_SLIDE
		return
		
	set_anim(AIR)
	update_wall_direction()
	set_dir()
	
	velocity.y += gravity * delta
	
	if dir:
		velocity.x = dir * speed
	else:
		velocity.x = 0


func jump(delta):
	if is_on_floor() and jump_index == 1:
		pre_jump = 1
		jump_index = 2
		from_jump_to_air_timer.start()
		velocity.y = jump_velocity
	elif not is_on_floor() and Input.is_action_just_pressed("JUMP") and jump_index == 2:
		jump_attack_index = 4
		single_anim_not_played_yet = true
		pre_jump = 2
		jump_index = 0
		from_jump_to_air_timer.start()
		velocity.y = jump_velocity
	elif is_on_floor():
		from_jump_to_air_timer.stop()
		if np:
			print("to LANDING from jump")
		state = LANDING
		jump_index = 1
		jump_attack_index = 1
		return
		
	if Input.is_action_pressed("DASH") and adrenaline >= 50:
		from_jump_to_air_timer.stop()
		adrenaline -= 50
		if np:
			print("from jump to DASH")
		state = DASH
		return
		
	if wall_dir and !wall_jumping and !is_on_floor():
		from_jump_to_air_timer.stop()
		velocity.y = 0
		dir = -wall_dir
		if dir:
			anim_dir = dir
		if np:
			print("from JUMP to WALL_SLIDE")
		state = WALL_SLIDE
		return
		
	if Input.is_action_pressed("RMB ATTACK"):
		from_jump_to_air_timer.stop()
		if pre_jump == 1:
			if jump_attack_index == 1:
				jump_attack_index = 2
				if np:
					print("from air to FIRST_JUMP_ATTACK_1")
				state = FIRST_JUMP_ATTACK_1
				return
			elif jump_attack_index == 2:
				jump_attack_index = 3
				if np:
					print("from air to FIRST_JUMP_ATTACK_2")
				state = FIRST_JUMP_ATTACK_2
				return
			elif jump_attack_index == 3:
				jump_attack_index = 4
				if np:
					print("from air to FIRST_JUMP_ATTACK_3")
				state = FIRST_JUMP_ATTACK_3
				return
		elif pre_jump == 2:
			if jump_attack_index == 4:
				jump_attack_index = 5
				if np:
					print("from air to SECOND_JUMP_ATTACK_1")
				state = SECOND_JUMP_ATTACK_1
				return
			elif jump_attack_index == 5:
				jump_attack_index = 6
				if np:
					print("from air to SECOND_JUMP_ATTACK_2")
				state = SECOND_JUMP_ATTACK_2
				return
			elif jump_attack_index == 6:
				jump_attack_index = 0
				if np:
					print("from air to SECOND_JUMP_ATTACK_3")
				state = SECOND_JUMP_ATTACK_3
				return
		
	set_anim(JUMP)
	update_wall_direction()
	if !wall_jumping:
		set_dir()
		
	velocity.y += gravity * delta
	
	if wall_jumping:
		velocity.x += -wall_dir * speed * 25 * delta #было 50
		velocity.y = jump_velocity
	elif dir:
		velocity.x = dir * speed
	else:
		velocity.x = 0
	
		
func _on_from_jump_to_air_timer_timeout():
	if np:
		print("to air because of timer runned in jump")
	state = AIR


func sit():
	if check_if_can_stand_up():
		if !Input.is_action_pressed("DOWN"):
			if np:
				print("from sit to idle")
			state = IDLE
			return
		if Input.is_action_just_pressed("JUMP") and is_on_floor():
			if np:
				print("from sit to jump")
			state = JUMP
			return
			
	if dir:
		if np:
			print("from sit to crouch")
		state = CROUCH
		return
		
	if Input.is_action_pressed("ROLL") and adrenaline >= 20:
		adrenaline -= 20
		if np:
			print("from sit to roll")
		state = ROLL
		return
		
	if not is_on_floor():
		if np:
			print("from sit to air")
		jump_index = 2
		state = AIR
		return
		
	set_anim(SIT)
	set_dir()
	
	velocity.x = 0
	velocity.y = 0
	
	
func crouch():
	if check_if_can_stand_up():
		if !Input.is_action_pressed("DOWN"):
			if np:
				print("from crouch to sit")
			state = SIT #maybe should be idle but works fine
			return
		if Input.is_action_just_pressed("JUMP") and is_on_floor():
			if np:
				print("from crouch to jump")
			state = JUMP
			return
		
	if not is_on_floor():
		if np:
			print("from crouch to air")
		jump_index = 2
		state = AIR
		return
		
	if Input.is_action_pressed("ROLL") and adrenaline >= 20:
		adrenaline -= 20
		if np:
			print("from crouch to roll")
		state = ROLL
		return
		
	set_anim(CROUCH)
	set_dir()
	
	velocity.y = 0
	
	if dir:
		velocity.x = dir * speed / 2
	else:
		if np:
			print("from crouch to sit")
		state = SIT
		return
	
	
func update_wall_direction():
	var is_near_wall_left = check_is_valid_wall(left_wall_raycasts)
	var is_near_wall_right = check_is_valid_wall(right_wall_raycasts)

	if is_near_wall_left and is_near_wall_right:
		wall_dir = dir
	else:
		wall_dir = -int(is_near_wall_left) + int(is_near_wall_right)


func check_is_valid_wall(wall_raycasts):
	var count = 0
	for raycast in wall_raycasts.get_children():
		if raycast.is_colliding():
			var dot = acos(Vector2.UP.dot(raycast.get_collision_normal()))
			if dot > PI * 0.35 and dot < PI * 0.55:
				count += 1
	if count == 2:
		return true
	else:
		return false
		
		
func check_if_can_stand_up():
	var count = 0
	for raycast in can_stand_up_raycasts.get_children():
		if raycast.is_colliding():
			count += 1
	if count:
		return false
	else:
		return true
	

func wall_slide(delta):
	if Input.is_action_pressed("JUMP"):
		wall_slide_cooldown.start()
		wall_jumping = true
		jump_index = 0
		pre_jump = 0
		dir = 0
		if np:
			print("from wall_slide to jump")
		state = JUMP
		return
		
	if is_on_floor():
		jump_index = 1
		if np:
			print("from wall_slide to idle")
		state = IDLE
		return
		
	if !wall_dir and not is_on_floor():
		if np:
			print("from wall_slide to air")
		jump_index = 2
		state = AIR
		return
	
	set_anim(WALL_SLIDE)
	update_wall_direction()
	
	velocity.y += gravity / 6 * delta
	velocity.x = wall_dir * speed
	
	
func _on_wall_slide_cooldown_timeout():
	wall_jumping = false
	
	
func dash():
	set_anim(DASH)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == DASH:
			if np:
				print("from dash to AIR")
			pre_jump = 2
			state = AIR
			return
			
	velocity.x = anim_dir * speed * 12
	velocity.y = 0
		
		
func roll():
	if not is_on_floor():
		jump_index = 2
		if np:
			print("from ROLL to AIR")
		state = AIR
		return
	set_anim(ROLL)
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ROLL:
			if np:
				print("from ROLL to SIT")
			state = SIT
			return
			
	velocity.x = anim_dir * speed * 3
#	velocity.y = 0 # комментирование этой строки фиксит баг, при котором
#		происходит неправильное поведение velocity.y после того, как из roll попадаешь в air,
#		но из-за этого в теории стоит ожидать других багов


func _on_animation_player_animation_finished(anim_name):
#	if anim_name == "FirstAir" or anim_name == "FirstJump" or anim_name == "SecondAir" or anim_name == "SecondJump":
#		single_anim_not_played_yet = false
	single_anim_not_played_yet = false 
	#вроде бы без проверки фиксится баг, при котором во втором прыжке сразу включается цикличная версия анимации
	#а может и нет, впрочем баг некритичный


func weak_attack_1():
	set_anim(WEAK_ATTACK_1)
	velocity.x = anim_dir * speed / 8
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == WEAK_ATTACK_1:
			if np:
				print("from weak_attack_1 to idle")
			state = IDLE
			
			
func weak_attack_2():
	set_anim(WEAK_ATTACK_2)
	velocity.x = anim_dir * speed / 8
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == WEAK_ATTACK_2:
			if np:
				print("from weak_attack_2 to idle")
			state = IDLE
			
			
func weak_attack_3():
	set_anim(WEAK_ATTACK_3)
	velocity.x = anim_dir * speed / 8
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == WEAK_ATTACK_3:
			if np:
				print("from weak_attack_3 to idle")
			state = IDLE
		
		
func weak_attack_4():
	set_anim(WEAK_ATTACK_4)
	velocity.x = anim_dir * speed / 8
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == WEAK_ATTACK_4:
			if np:
				print("from weak_attack_4 to idle")
			state = IDLE
			
			
func _on_weak_combo_timer_timeout():
	weak_combo_index = 1
	

func strong_attack_1():
	set_anim(STRONG_ATTACK_1)
	velocity.x = anim_dir * speed / 5
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == STRONG_ATTACK_1:
			if np:
				print("from strong_attack_1 to idle")
			state = IDLE
			
			
func strong_attack_2():
	set_anim(STRONG_ATTACK_2)
	velocity.x = anim_dir * speed / 5
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == STRONG_ATTACK_2:
			if np:
				print("from strong_attack_2 to idle")
			state = IDLE
			
			
func strong_attack_3():
	set_anim(STRONG_ATTACK_3)
	velocity.y = 0
	velocity.x = anim_dir * speed / 5
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == STRONG_ATTACK_3:
			if np:
				print("from strong_attack_3 to idle")
			state = IDLE
			
			
func strong_attack_4(delta):
	set_anim(STRONG_ATTACK_4)
	velocity.x = anim_dir * speed / 5
	velocity.y += gravity * 15 * delta 
	if !state_started:
		velocity.y = jump_velocity * 3
		state_started = true
		await anim.animation_finished
		if state == STRONG_ATTACK_4:
			if np:
				print("from strong_attack_4 to idle")
			state = IDLE


func _on_strong_combo_timer_timeout():
	strong_combo_index = 1


func _on_adrenaline_timer_timeout():
	if adrenaline < 100:
		adrenaline += 10


func landing():
	set_anim(LANDING)
	set_dir()
	if not is_on_floor():
		jump_index = 2
		state_started = false
		if np:
			print("from landing to AIR")
		state = AIR
		return
	velocity.x = dir * speed
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == LANDING:
			if np:
				print("from landing to idle")
			state = IDLE


func first_jump_attack_1():
	set_anim(FIRST_JUMP_ATTACK_1)
	velocity.x = anim_dir * speed / 10
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == FIRST_JUMP_ATTACK_1:
			jump_index = 2
			if np:
				print("from FIRST_JUMP_ATTACK_1 to AIR")
			state = AIR
	
	
func first_jump_attack_2():
	set_anim(FIRST_JUMP_ATTACK_2)
	velocity.x = anim_dir * speed / 10
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == FIRST_JUMP_ATTACK_2:
			jump_index = 2
			if np:
				print("from FIRST_JUMP_ATTACK_2 to AIR")
			state = AIR
	
	
func first_jump_attack_3():
	set_anim(FIRST_JUMP_ATTACK_3)
	velocity.x = anim_dir * speed / 10
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == FIRST_JUMP_ATTACK_3:
			jump_index = 2
			if np:
				print("from FIRST_JUMP_ATTACK_3 to AIR")
			state = AIR
	
	
func second_jump_attack_1():
	set_anim(SECOND_JUMP_ATTACK_1)
	velocity.x = anim_dir * speed / 10
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == SECOND_JUMP_ATTACK_1:
			jump_index = 0
			if np:
				print("from SECOND_JUMP_ATTACK_1 to AIR")
			state = AIR
	
	
func second_jump_attack_2():
	set_anim(SECOND_JUMP_ATTACK_2)
	velocity.x = anim_dir * speed / 10
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == SECOND_JUMP_ATTACK_2:
			jump_index = 0
			if np:
				print("from SECOND_JUMP_ATTACK_2 to AIR")
			state = AIR
	
	
func second_jump_attack_3():
	set_anim(SECOND_JUMP_ATTACK_3)
	velocity.x = anim_dir * speed / 10
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == SECOND_JUMP_ATTACK_3:
			jump_index = 0
			if np:
				print("from SECOND_JUMP_ATTACK_3 to AIR")
			state = AIR
			
			
func block():
	set_anim(BLOCK)
	velocity.x = 0
	velocity.y = 0
	if not Input.is_action_pressed("BLOCK"):
		if np:
			print("from block to idle")
		blocking = false
		hurtbox_col.disabled = true
		state = IDLE
		hurtbox_col.disabled = false


func _on_hitbox_body_entered(body):
	if global_position.x > body.global_position.x:
		body.get_damage(1, -1)
	else:
		body.get_damage(1, 1)
	
	
func dead(delta):
	set_anim(DEAD)
	velocity.y += gravity * delta
	velocity.y = 0
	if !state_started:
		hitbox_col.disabled = true
		state_started = true
#		await anim.animation_finished
		get_tree().reload_current_scene()
