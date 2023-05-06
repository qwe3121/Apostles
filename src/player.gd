extends CharacterBody2D
var np = false

@onready var block_stamina_timer = $BlockStaminaTimer
@onready var wall_slide_stamina_timer = $WallSlideStaminaTimer


#stamina cost
var sc_second_jump = 0
var sc_roll = 10
var sc_dash = 20
var sc_wall_slide = 0
var sc_block = 0
var sc_weak_attack = 0
var sc_strong_attack = 0
var sc_first_jump_attack = 0
var sc_second_jump_attack = 0

var stamina_increasing_per_sec = 5

#adrenaline cost
var ac_fruit_ninja = 40


@onready var death_screen = $CanvasLayer/DeathScreen
@onready var ui = $CanvasLayer/PlayerUI

@onready var anim = $AnimationPlayer
@onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycasts
@onready var right_wall_raycasts = $WallRaycasts/RightWallRaycasts
@onready var adrenaline_bar_over = $CanvasLayer/PlayerUI/AdrenalineBarOver
@onready var stamina_bar_over = $CanvasLayer/PlayerUI/StaminaBarOver
@onready var adrenaline_bar_under = $CanvasLayer/PlayerUI/AdrenalineBarUnder
@onready var stamina_bar_under = $CanvasLayer/PlayerUI/StaminaBarUnder
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var weak_combo_timer = $WeakComboTimer
@onready var strong_combo_timer = $StrongComboTimer
@onready var from_jump_to_air_timer = $FromJumpToAirTimer
#@onready var can_stand_up_raycasts = $CanStandUpRaycasts
@onready var can_stand_up_shapecast = $CanStandUpRaycasts/ShapeCast2D
@onready var wall_slide_cooldown = $WallSlideCooldown
@onready var hitbox_col = $Hitbox/CollisionShape2D
@onready var blood_pos = $BloodPos

@onready var sunlens_anim = $CanvasLayer/SunLens/SunLensAnim
@onready var sunlens_timer = $CanvasLayer/SunLens/SunlensTimer

#wall raycasts
@onready var ws_left_top_raycast = $WallRaycasts/LeftWallRaycasts/LeftTopRaycast
@onready var ws_left_bot_raycast = $WallRaycasts/LeftWallRaycasts/LeftBotRaycast
@onready var ws_right_top_raycast = $WallRaycasts/RightWallRaycasts/RightTopRaycast
@onready var ws_right_bot_raycast = $WallRaycasts/RightWallRaycasts/RightBotRaycast

#fruit ninja stuff
@onready var fruit_ninja_line = $FruitNinjaLine
@onready var fruit_ninja_particles = $FruitNinjaParticles
@onready var fruit_ninja_timer = $FruitNinjaTimer
@onready var fruit_ninja_area = $FruitNinjaLine/Area2D
var fruit_ninjaing = false
var fruit_ninjaing_thru_line = false
var fruit_ninja_targets = []
var fruit_ninja_line_already_painted = false


var learned_skills = {
	"fruit_ninja": true
}


#debuffs section

var flying_cause_of_mk6 = false
var slowed_cause_of_mk6 = false


enum {IDLE, RUN, AIR, JUMP, SIT, CROUCH, ROLL, DASH, WALL_SLIDE, BLOCK, WEAK_ATTACK_1, 
WEAK_ATTACK_2, WEAK_ATTACK_3, WEAK_ATTACK_4, STRONG_ATTACK_1, STRONG_ATTACK_2, STRONG_ATTACK_3, 
STRONG_ATTACK_4, LANDING, FIRST_JUMP_ATTACK_1, FIRST_JUMP_ATTACK_2, FIRST_JUMP_ATTACK_3, 
SECOND_JUMP_ATTACK_1, SECOND_JUMP_ATTACK_2, SECOND_JUMP_ATTACK_3,
DEAD, FRUIT_NINJA, REINCARNATION, BLOCKED}

var state = REINCARNATION : set = set_state

func set_state(value):
	if state == DEAD:
		return
		
	if not state == value: 
		state_started = false
		single_anim_not_played_yet = true

	state = value

var dir = 0
var anim_dir = 1
var wall_dir = 0

var weak_combo_index = 1
var strong_combo_index = 1
var jump_attack_index = 1

var jump_index = 1
var pre_jump = 1

var state_started = false
var wall_jumping

var single_anim_not_played_yet = true

var last_damage_source: String
var bullet_knockback_dir
var bullet_dead_anim_speredi: bool = false
var bullet_knockback: bool = false

var stamina = 100 : set = set_stamina

func set_stamina(value):
	stamina = value
	if stamina > 100:
		stamina = 100
	elif stamina < 0:
		stamina = 0
	var tween1 = create_tween()
	tween1.tween_property(stamina_bar_over, "value", stamina, 0.1)
	var tween2 = create_tween()
	tween2.tween_property(stamina_bar_under, "value", stamina, 0.25)
	
var adrenaline = 0 : set = set_adrenaline

func set_adrenaline(value):
	adrenaline = value
	if adrenaline > 100:
		adrenaline = 100
	elif adrenaline < 0:
		adrenaline = 0
	var tween1 = create_tween()
	tween1.tween_property(adrenaline_bar_over, "value", adrenaline, 0.1)
	var tween2 = create_tween()
	tween2.tween_property(adrenaline_bar_under, "value", adrenaline, 0.2)

var speed = 400 # было 300
var jump_velocity = -450 # было -600
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var hp = 1


func get_damage(source: String, can_block, damager = null): #fire, bullet, hit, cut
	if can_block and (state == BLOCK or state == ROLL or state == BLOCKED):
		if state == BLOCK:
			block_stamina_timer.stop()
			state = BLOCKED
		return
	
	if state == DASH or state == DEAD or state == REINCARNATION or state == FRUIT_NINJA or cfg.cfg_data.undead:
		return
		
	last_damage_source = source

	hp -= 1
	if hp <= 0:
		state_started = false
		from_jump_to_air_timer.stop()
		if damager != null:
			if damager.name == "TrapHitbox":
				damager.turn_into_bloody_version()
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
			anim.play("Idle")
		RUN: 
			anim.play("Run")
		AIR: 
			if pre_jump == 1 or pre_jump == 0:
				if single_anim_not_played_yet:
					anim.play("FirstAir")
				else:
					anim.play("FirstAirCycle")
			elif pre_jump == 2:
				if single_anim_not_played_yet:
					anim.play("SecondAir")
				else:
					anim.play("SecondAirCycle")
		JUMP:
			if pre_jump == 1 or pre_jump == 0:
				if single_anim_not_played_yet:
					anim.play("FirstJump")
				else:
					anim.play("FirstJumpCycle")
			elif pre_jump == 2:
				if single_anim_not_played_yet:
					anim.play("SecondJump")
				else:
					anim.play("SecondJumpCycle")
		SIT: 
			anim.play("Sit")
		CROUCH: 
			anim.play("Crouch")
		ROLL:
			anim.play("Roll") 
		DASH: 
			anim.play("Dash")
		WALL_SLIDE:
			anim.play("WallSlide")
		WEAK_ATTACK_1:
			anim.play("WeakAttack1")
		WEAK_ATTACK_2:
			anim.play("WeakAttack2")
		WEAK_ATTACK_3:
			anim.play("WeakAttack3")
		WEAK_ATTACK_4:
			anim.play("WeakAttack4")
		STRONG_ATTACK_1:
			anim.play("StrongAttack1")
		STRONG_ATTACK_2:
			anim.play("StrongAttack2")
		STRONG_ATTACK_3:
			anim.play("StrongAttack3")
		STRONG_ATTACK_4:
			anim.play("StrongAttack4")
		LANDING:
			anim.play("SecondLanding")
		FIRST_JUMP_ATTACK_1:
			anim.play("FirstJumpAttack1")
		FIRST_JUMP_ATTACK_2:
			anim.play("FirstJumpAttack2")
		FIRST_JUMP_ATTACK_3:
			anim.play("FirstJumpAttack3")
		SECOND_JUMP_ATTACK_1:
			anim.play("SecondJumpAttack1")
		SECOND_JUMP_ATTACK_2:
			anim.play("SecondJumpAttack2")
		SECOND_JUMP_ATTACK_3:
			anim.play("SecondJumpAttack3")
		DEAD:
			match last_damage_source:
				"bullet":
					if bullet_dead_anim_speredi:
						anim.play("bullet_dead_speredi")
					else:
						anim.play("bullet_dead_szadi")
				"hit":
					anim.play("hit_dead")
				"fire":
					anim.play("fire_dead")
				"cut":
					anim.play("cut_dead")
		BLOCK:
			anim.play("Block")
		BLOCKED:
			anim.play("Blocked")
		FRUIT_NINJA:
			anim.play("FruitNinja")
		REINCARNATION:
			anim.play("reincarnation")
				
				
func _ready():
	global.player = self


func _physics_process(delta):
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == FRUIT_NINJA and adrenaline >= ac_fruit_ninja:
		adrenaline -= ac_fruit_ninja
		from_jump_to_air_timer.stop()
		Engine.time_scale = 0.3
		state = FRUIT_NINJA

	match state:
		IDLE:
			idle()
		RUN:
			run()
		AIR:
			air(delta)
		JUMP:
			jump(delta)
		SIT:
			sit()
		CROUCH:
			crouch()
		WALL_SLIDE:
			wall_slide(delta)
		DASH:
			dash()
		ROLL:
			roll()
		WEAK_ATTACK_1:
			weak_attack_1()
		WEAK_ATTACK_2:
			weak_attack_2()
		WEAK_ATTACK_3:
			weak_attack_3()
		WEAK_ATTACK_4:
			weak_attack_4()
		STRONG_ATTACK_1:
			strong_attack_1()
		STRONG_ATTACK_2:
			strong_attack_2()
		STRONG_ATTACK_3:
			strong_attack_3()
		STRONG_ATTACK_4:
			strong_attack_4(delta)
		LANDING:
			landing()
		FIRST_JUMP_ATTACK_1:
			first_jump_attack_1()
		FIRST_JUMP_ATTACK_2:
			first_jump_attack_2()
		FIRST_JUMP_ATTACK_3:
			first_jump_attack_3()
		SECOND_JUMP_ATTACK_1:
			second_jump_attack_1()
		SECOND_JUMP_ATTACK_2:
			second_jump_attack_2()
		SECOND_JUMP_ATTACK_3:
			second_jump_attack_3()
		DEAD:
			dead(delta)
		BLOCK:
			block()
		BLOCKED:
			blocked()
		FRUIT_NINJA:
			fruit_ninja()
		REINCARNATION:
			reincarnation(delta)

	if flying_cause_of_mk6 and not state == DASH:
		velocity.y = -1
		velocity.x /= 500 * delta

	if slowed_cause_of_mk6 and not state == DASH:
		velocity = velocity/2

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
		
	if Input.is_action_pressed("DASH") and stamina >= sc_dash:
		stamina -= sc_dash
		if np:
			print("from idle to DASH")
		state = DASH
		return
		
	if Input.is_action_pressed("BLOCK") and stamina >= sc_block:
		block_stamina_timer.start()
		if np:
			print("from idle to block")
		state = BLOCK
		return

	if Input.is_action_pressed("RMB ATTACK") and stamina >= sc_weak_attack:
		stamina -= sc_weak_attack
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
		
	if Input.is_action_pressed("LMB ATTACK") and stamina >= sc_strong_attack:
		stamina -= sc_strong_attack
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
		strong_combo_timer.start()
		return
		
	if Input.is_action_pressed("ROLL") and stamina >= sc_roll:
		stamina -= sc_roll
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
		
	if Input.is_action_pressed("DASH") and stamina >= sc_dash:
		stamina -= sc_dash
		if np:
			print("from run to DASH")
		state = DASH
		return
		
	if Input.is_action_pressed("BLOCK") and stamina >= sc_block:
		block_stamina_timer.start()
		if np:
			print("from run to block")
		state = BLOCK
		return
		
	if Input.is_action_pressed("RMB ATTACK") and stamina >= sc_weak_attack:
		stamina -= sc_weak_attack
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
		
	if Input.is_action_pressed("LMB ATTACK") and stamina >= sc_strong_attack:
		stamina -= sc_strong_attack
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
		strong_combo_timer.start()
		return
		
	if Input.is_action_pressed("ROLL") and stamina >= sc_roll:
		stamina -= sc_roll
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
		
	if Input.is_action_pressed("DASH") and stamina >= sc_dash:
		stamina -= sc_dash
		if np:
			print("from air to DASH")
		state = DASH
		return
		
	if not is_on_floor() and Input.is_action_just_pressed("JUMP") and jump_index == 2 and stamina >= sc_second_jump:
		stamina -= sc_second_jump
		jump_attack_index = 4
		jump_index = 0
		pre_jump = 2
		from_jump_to_air_timer.start()
		velocity.y = jump_velocity
		if np:
			print("from AIR to JUMP")
		state = JUMP
		return
		
	if (Input.is_action_pressed("RMB ATTACK") or Input.is_action_pressed("LMB ATTACK")) and not flying_cause_of_mk6:
		if pre_jump == 1 and stamina >= sc_first_jump_attack and not jump_attack_index > 3:
			from_jump_to_air_timer.stop()
			stamina -= sc_first_jump_attack
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
		elif pre_jump == 2 and stamina >= sc_second_jump_attack and not jump_attack_index < 4:
			from_jump_to_air_timer.stop()
			stamina -= sc_second_jump_attack
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
		
	if wall_dir and !wall_jumping and !is_on_floor() and stamina >= sc_wall_slide:
		wall_slide_stamina_timer.start()
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
	elif not is_on_floor() and Input.is_action_just_pressed("JUMP") and jump_index == 2 and stamina >= sc_second_jump:
		stamina -= sc_second_jump
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
		
	if Input.is_action_pressed("DASH") and stamina >= sc_dash:
		from_jump_to_air_timer.stop()
		stamina -= sc_dash
		if np:
			print("from jump to DASH")
		state = DASH
		return
		
	if wall_dir and !wall_jumping and !is_on_floor() and stamina >= sc_wall_slide:
		wall_slide_stamina_timer.start()
		from_jump_to_air_timer.stop()
		velocity.y = 0
		dir = -wall_dir
		if dir:
			anim_dir = dir
		if np:
			print("from JUMP to WALL_SLIDE")
		state = WALL_SLIDE
		return
		
	if (Input.is_action_pressed("RMB ATTACK") or Input.is_action_pressed("LMB ATTACK")) and not flying_cause_of_mk6:
		if pre_jump == 1 and stamina >= sc_first_jump_attack and not jump_attack_index > 3:
			from_jump_to_air_timer.stop()
			stamina -= sc_first_jump_attack
			if jump_attack_index == 1:
				jump_attack_index = 2
				if np:
					print("from jump to FIRST_JUMP_ATTACK_1")
				state = FIRST_JUMP_ATTACK_1
				return
			elif jump_attack_index == 2:
				jump_attack_index = 3
				if np:
					print("from jump to FIRST_JUMP_ATTACK_2")
				state = FIRST_JUMP_ATTACK_2
				return
			elif jump_attack_index == 3:
				jump_attack_index = 4
				if np:
					print("from jump to FIRST_JUMP_ATTACK_3")
				state = FIRST_JUMP_ATTACK_3
				return
		elif pre_jump == 2 and stamina >= sc_second_jump_attack and not jump_attack_index < 4:
			from_jump_to_air_timer.stop()
			stamina -= sc_second_jump_attack
			if jump_attack_index == 4:
				jump_attack_index = 5
				if np:
					print("from jump to SECOND_JUMP_ATTACK_1")
				state = SECOND_JUMP_ATTACK_1
				return
			elif jump_attack_index == 5:
				jump_attack_index = 6
				if np:
					print("from jump to SECOND_JUMP_ATTACK_2")
				state = SECOND_JUMP_ATTACK_2
				return
			elif jump_attack_index == 6:
				jump_attack_index = 0
				if np:
					print("from jump to SECOND_JUMP_ATTACK_3")
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
		
	if Input.is_action_pressed("ROLL") and stamina >= sc_roll:
		stamina -= sc_roll
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
		
	if Input.is_action_pressed("ROLL") and stamina >= sc_roll:
		stamina -= sc_roll
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
#	var count = 0
#	for raycast in can_stand_up_raycasts.get_children():
#		if raycast.is_colliding():
#			count += 1
#	if count:
#		return false
#	else:
#		return true
	return not can_stand_up_shapecast.is_colliding()
	

func wall_slide(delta):
	if stamina < sc_wall_slide:
		if np:
			print("from wall_slide to air cause of stamina luck")
		jump_index = 2
		wall_slide_stamina_timer.stop()
		state = AIR
		return
	
	if Input.is_action_just_pressed("DOWN"):
		velocity.x = -wall_dir * speed
		if np:
			print("from wall_slide to air cause of DOWN button")
		jump_index = 2
		wall_slide_stamina_timer.stop()
		state = AIR
		return
	
	if Input.is_action_pressed("JUMP") and stamina >= sc_second_jump:
		stamina -= sc_second_jump
		wall_slide_cooldown.start()
		wall_jumping = true
		jump_index = 0
		pre_jump = 0
		dir = 0
		if np:
			print("from wall_slide to jump")
		wall_slide_stamina_timer.stop()
		state = JUMP
		return
		
	if is_on_floor():
		jump_index = 1
		if np:
			print("from wall_slide to idle")
		wall_slide_stamina_timer.stop()
		state = IDLE
		return
		
	if !wall_dir and not is_on_floor():
		if np:
			print("from wall_slide to air")
		jump_index = 2
		wall_slide_stamina_timer.stop()
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
			
	velocity.x = anim_dir * speed * 1.5
#	velocity.y = 0 # комментирование этой строки фиксит баг, при котором
#		происходит неправильное поведение velocity.y после того, как из roll попадаешь в air,
#		но из-за этого в теории стоит ожидать других багов


func _on_animation_player_animation_finished(anim_name):
	if ((anim_name == "FirstAir" or anim_name == "SecondAir") and state == AIR) or ((anim_name == "FirstJump" or anim_name == "SecondJump") and state == JUMP):
		single_anim_not_played_yet = false #bug with single_anim_not_played_it and air state most likely fixed this way
 

func weak_attack_1():
	set_anim(WEAK_ATTACK_1)
	velocity.x = anim_dir * speed / 16
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
	velocity.x = anim_dir * speed / 16
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
	velocity.x = anim_dir * speed / 16
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
	velocity.x = anim_dir * speed / 16
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
	velocity.x = anim_dir * speed / 10
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
	velocity.x = anim_dir * speed / 10
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
	velocity.x = anim_dir * speed / 10
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == STRONG_ATTACK_3:
			if np:
				print("from strong_attack_3 to idle")
			state = IDLE
			
			
func strong_attack_4(delta):
	set_anim(STRONG_ATTACK_4)
	velocity.x = anim_dir * speed / 10
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


func _on_stamina_timer_timeout():
	stamina += stamina_increasing_per_sec


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
	velocity.x = anim_dir * speed / 20
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
	velocity.x = anim_dir * speed / 20
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
	velocity.x = anim_dir * speed / 20
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
	velocity.x = anim_dir * speed / 20
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
	velocity.x = anim_dir * speed / 20
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
	velocity.x = anim_dir * speed / 20
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
	if not Input.is_action_pressed("BLOCK") or stamina < sc_block:
		if np:
			print("from block to idle")
		block_stamina_timer.stop()
		state = IDLE
		
		
func blocked():
	set_anim(BLOCKED)
	velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == BLOCKED:
			if np:
				print("from BLOCKED to BLOCK")
		state = BLOCK

func _on_hitbox_body_entered(body):
	if global_position.x > body.global_position.x:
		body.get_damage(1, -1)
	else:
		body.get_damage(1, 1)
	
	
func dead(delta):
	set_anim(DEAD)
	velocity.y += gravity * delta
	if last_damage_source == "bullet" and bullet_knockback:
		velocity.x = bullet_knockback_dir * 200
	else:
		velocity.x = 0
	if !state_started:
		hitbox_col.disabled = true
		state_started = true
		await anim.animation_finished
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
		
		
func off_bullet_knockback():
	bullet_knockback = false
		
		
func fruit_ninja():
	velocity.y = 0
	velocity.x = 0
	
	if fruit_ninjaing_thru_line:
		if !state_started:
			animated_sprite.visible = false
			
			state_started = true
			Engine.time_scale = 1.0
			
			fruit_ninja_line.clear_points()
			
			for target in fruit_ninja_targets:
				target.kill_with_fruit_ninja()
				await events.fruit_kill
				
			for child in fruit_ninja_area.get_children():
				child.queue_free()
			
			fruit_ninjaing = false
			fruit_ninjaing_thru_line = false
			fruit_ninja_targets = []
			fruit_ninja_line_already_painted = false
			if np:
				print("from fruit ninja to idle")
			animated_sprite.visible = true
			state = IDLE
			return
	else:
		if (Input.is_action_pressed("LMB ATTACK") or Input.is_action_pressed("RMB ATTACK")) and not fruit_ninja_line_already_painted:
			if not fruit_ninjaing: 
				fruit_ninja_particles.emitting = true
				fruit_ninja_timer.start()
				fruit_ninjaing = true
			fruit_ninja_line.add_point(get_global_mouse_position())
			fruit_ninja_particles.global_position = get_global_mouse_position()
		elif fruit_ninjaing:
			fruit_ninjaing = false
			fruit_ninja_line_already_painted = true
			fruit_ninja_particles.emitting = false
			fruit_ninja_timer.stop()
			create_fruit_ninja_col()
			await get_tree().create_timer(0.05).timeout
			fruit_ninjaing_thru_line = true


func _on_fruit_ninja_timer_timeout():
	fruit_ninja_particles.emitting = false
	fruit_ninjaing = false
	fruit_ninja_line_already_painted = true
	create_fruit_ninja_col()
	await get_tree().create_timer(0.05).timeout
	fruit_ninjaing_thru_line = true
	
	
func create_fruit_ninja_col():
	for i in fruit_ninja_line.points.size() - 1:
		var new_shape = CollisionShape2D.new()
		fruit_ninja_area.add_child(new_shape)
		var rect = RectangleShape2D.new()
		new_shape.position = (fruit_ninja_line.points[i] + fruit_ninja_line.points[i + 1]) / 2
		new_shape.rotation = fruit_ninja_line.points[i].direction_to(fruit_ninja_line.points[i + 1]).angle()
		var length = fruit_ninja_line.points[i].distance_to(fruit_ninja_line.points[i + 1])
		rect.extents = Vector2(length / 2, fruit_ninja_line.width)
		new_shape.shape = rect


func _on_area_2d_body_entered(body):
	if state == FRUIT_NINJA and body not in fruit_ninja_targets and not fruit_ninjaing_thru_line:
		var space_state = get_world_2d().get_direct_space_state()
		var params = PhysicsRayQueryParameters2D.new()
		params.from = blood_pos.global_position
		params.to = body.blood_pos.global_position
		params.exclude = [self]
		params.collide_with_areas = false
		params.collide_with_bodies = true
		params.hit_from_inside = true
		params.collision_mask = 0b00000000000000010010
		var result = space_state.intersect_ray(params)
		if len(result) == 0: return
		if result.collider.get_collision_layer() == 0b00000000000000000010: return
		fruit_ninja_targets.append(body)


func _on_sun_lens_anim_animation_finished(anim_name):
	sunlens_anim.get_animation("default").track_set_key_value(0, 1, Vector2(randi_range(-100, 1000), randi_range(-150, 100)))
	sunlens_anim.get_animation("default").track_set_key_value(0, 0, Vector2(randi_range(-100, 1000), randi_range(-150, 100)))
#	sunlens_anim.get_animation("default").track_set_key_value(1, 1, randf_range(0.7, 1.0))
	sunlens_anim.speed_scale = randf_range(0.5, 1.2)
	sunlens_timer.wait_time = randi_range(10, 20)
	sunlens_timer.start()


func _on_sunlens_timer_timeout():
	sunlens_anim.play("default")
	
	
func create_cuts_for_cut_dead():
	var cut_arm_1 = preload("res://src/player_cuts/cut_arm_1.tscn").instantiate()
	var cut_arm_2 = preload("res://src/player_cuts/cut_arm_2.tscn").instantiate()
	var cut_body = preload("res://src/player_cuts/cut_body.tscn").instantiate()
	var cut_leg_1 = preload("res://src/player_cuts/cut_leg_1.tscn").instantiate()
	var cut_leg_2 = preload("res://src/player_cuts/cut_leg_2.tscn").instantiate()
	var cut_pelvis = preload("res://src/player_cuts/cut_pelvis.tscn").instantiate()
	var cut_sword = preload("res://src/player_cuts/cut_sword.tscn").instantiate()
	add_child(cut_arm_1)
	cut_arm_1.global_position = global_position
	add_child(cut_arm_2)
	cut_arm_2.global_position = global_position
	add_child(cut_body)
	cut_body.global_position = global_position
	add_child(cut_leg_1)
	cut_leg_1.global_position = global_position
	add_child(cut_leg_2)
	cut_leg_2.global_position = global_position
	add_child(cut_pelvis)
	cut_pelvis.global_position = global_position
	add_child(cut_sword)
	cut_sword.global_position = global_position
	create_blood(20)


func create_blood(number: int = 5):
	for c in range(number):
		blood_manager.create_blood(0, blood_pos)


func reincarnation(delta):
	set_anim(REINCARNATION)
	velocity.x = 0
	velocity.y += gravity * delta * 10
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == REINCARNATION:
			if np:
				print("from REINC to idle")
			state = IDLE
			
			
func change_scene_to_dead_screen():
	ui.visible = false
	get_tree().paused = true
	death_screen.visible = true


func _on_block_stamina_timer_timeout():
	stamina -= sc_block


func _on_wall_slide_stamina_timer_timeout():
	stamina -= sc_wall_slide
	

func shake_camera():
	global.camera.shake(2)
