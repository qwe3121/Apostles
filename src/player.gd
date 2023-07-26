extends CharacterBody2D
var np = false

@onready var dash_icon_anim = $CanvasLayer/PlayerUI/DashIcon/DashIconAnim
var can_dash = true : set = set_can_dash

func set_can_dash(value):
	if value == false:
		dash_icon_anim.play("using")
	can_dash = value
	
var can_fruit_ninja = true : set = set_can_fruit_ninja

func set_can_fruit_ninja(value):
	pass

var can_block = true : set = set_can_block

func set_can_block(value):
	pass

var can_roll = true : set = set_can_roll

func set_can_roll(value):
	pass
	
	
@onready var blood_splash_screen_anim = $CanvasLayer/BloodSplashScreen/BloodSplashScreenAnim
@onready var blood_splash_screen_timer = $CanvasLayer/BloodSplashScreen/BloodSplashScreenTimer

var adrenaline = 100 : set = set_adrenaline
var blood_splash_screen_showed = false

func set_adrenaline(value):
	if value < 0: value = 0
	if value > 100: value = 100
	adrenaline = value
	
	
func show_blood_splash_screen():
	if not blood_splash_screen_showed: blood_splash_screen_anim.play("show")
	blood_splash_screen_timer.start()
	
	
func _on_blood_splash_screen_anim_animation_finished(anim_name):
	if anim_name == "show":
		blood_splash_screen_showed = true
	else:
		blood_splash_screen_showed = false
		killstreak = 0
		killstreak_timer.stop()


func _on_blood_splash_screen_timer_timeout():
	if blood_splash_screen_showed:
		blood_splash_screen_anim.play("hide")
		blood_splash_screen_timer.stop()
		
		
@onready var killstreak_timer = $KillstreakTimer
		
		
var killstreak = 0 : set = set_killstreak

func set_killstreak(value):
	if value < 0: killstreak = 0
	killstreak = value
	if killstreak > 2:
		show_blood_splash_screen()
	killstreak_timer.start()
	
	
func _on_killstreak_timer_timeout():
	killstreak = 0
	


@onready var death_screen = $CanvasLayer/DeathScreen
@onready var ui = $CanvasLayer/PlayerUI

@onready var anim = $AnimationPlayer
@onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycasts
@onready var right_wall_raycasts = $WallRaycasts/RightWallRaycasts

@onready var animated_sprite = $AnimatedSprite2D
@onready var sword_hitbox = $SwordHitbox
@onready var sword_hitbox_col = $SwordHitbox/CollisionShape2D

@onready var dash_hitbox = $DashHitbox
@onready var special_attack_1_hitbox = $SpecialAttack1Hitbox
@onready var weak_combo_timer = $WeakComboTimer
@onready var strong_combo_timer = $StrongComboTimer
@onready var from_jump_to_air_timer = $FromJumpToAirTimer

@onready var col = $CollisionShape2D
@onready var hurtbox_4_traps_col = $HurtboxForTraps/CollisionShape2D
var need_to_change_col_size: bool = false
var can_increase_col: bool = true
var pre_anim: String

var flashing = 0
@onready var flashlight_timer = $FlashlightTimer

var can_get_damage = true
@onready var gettin_damage_CD = $GettinDamageCD

@onready var can_stand_up_shapecast = $CanStandUpRaycasts/ShapeCast2D
@onready var wall_slide_cooldown = $WallSlideCooldown
@onready var blood_pos = $BloodPos

@onready var lens_flare_anim = $CanvasLayer/LensFlare/LensFlareAnim
@onready var lens_flare_timer = $CanvasLayer/LensFlare/LensFlareTimer

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
var slowed_cause_of_mk6 = false : set = set_slowed_cause_of_mk6

func set_slowed_cause_of_mk6(value):
	slowed_cause_of_mk6 = value
	
	var cur_anim_name = anim.current_animation
	
	if cur_anim_name == "" or cur_anim_name == " " or cur_anim_name == null:
		return
	
	if value:
		anim.speed_scale = animations_speed_scales[cur_anim_name] / 2
	else:
		anim.speed_scale = animations_speed_scales[cur_anim_name]


enum states {IDLE, RUN, AIR, JUMP, SIT, CROUCH, ROLL, DASH, WALL_SLIDE, WEAK_ATTACK_1, 
WEAK_ATTACK_2, WEAK_ATTACK_3, WEAK_ATTACK_4, STRONG_ATTACK_1, STRONG_ATTACK_2, STRONG_ATTACK_3, 
STRONG_ATTACK_4, LANDING, FIRST_JUMP_ATTACK_1, FIRST_JUMP_ATTACK_2, FIRST_JUMP_ATTACK_3, 
SECOND_JUMP_ATTACK_1, SECOND_JUMP_ATTACK_2, SECOND_JUMP_ATTACK_3,
DEAD, FRUIT_NINJA, REINCARNATION, BLOCKED, DOWN_DASH, SPECIAL_ATTACK_1}
# if ADDING NEW STATE - DO NOT FORGET TO ADD IT IN state_counter
# !!!
# !!!
# !!!

var state_ins_counter = {
	states.IDLE: 0,
	states.RUN: 0,
	states.AIR: 0, 
	states.JUMP: 0,
	states.SIT: 0,
	states.CROUCH: 0,
	states.ROLL: 0,
	states.DASH: 0,
	states.WALL_SLIDE: 0,
	states.WEAK_ATTACK_1: 0,
	states.WEAK_ATTACK_2: 0,
	states.WEAK_ATTACK_3: 0,
	states.WEAK_ATTACK_4: 0,
	states.STRONG_ATTACK_1: 0,
	states.STRONG_ATTACK_2: 0,
	states.STRONG_ATTACK_3: 0,
	states.STRONG_ATTACK_4: 0,
	states.LANDING: 0,
	states.FIRST_JUMP_ATTACK_1: 0,
	states.FIRST_JUMP_ATTACK_2: 0,
	states.FIRST_JUMP_ATTACK_3: 0,
	states.SECOND_JUMP_ATTACK_1: 0,
	states.SECOND_JUMP_ATTACK_2: 0,
	states.SECOND_JUMP_ATTACK_3: 0,
	states.DEAD: 0,
	states.FRUIT_NINJA: 0,
	states.REINCARNATION: 0,
	states.BLOCKED: 0,
	states.DOWN_DASH: 0,
	states.SPECIAL_ATTACK_1: 0,
}

var state = states.REINCARNATION : set = set_state

func set_state(value):
	if state == states.DEAD:
		return
		
	if not state == value: 
		state_started = false
		single_anim_not_played_yet = true
		
	state_ins_counter[value] += 1
	if state_ins_counter[value] > 1000:
		state_ins_counter[value] = 0

	state = value
	
var animations_speed_scales = {
	"Blocked": 1,
	"Crouch": 1,
	"Dash": 20, 
	"FirstAir": 1, 
	"FirstAirCycle": 1, 
	"FirstJump": 3.5, 
	"FirstJumpAttack1": 1.8,
	"FirstJumpAttack2": 1.8,
	"FirstJumpAttack3": 1.8,
	"FirstJumpCycle": 1, 
	"Idle": 0.5,
	"Roll": 2, 
	"Run": 1,
	"SecondAir": 1,
	"SecondAirCycle": 1,
	"SecondJump": 2, 
	"SecondJumpAttack1": 1.8,
	"SecondJumpAttack2": 1.35,
	"SecondJumpAttack3": 0.9,
	"SecondJumpCycle": 1,
	"SecondLanding": 3,
	"Sit": 0.7,
	"StrongAttack1": 0.8,
	"StrongAttack2": 0.8,
	"StrongAttack3": 0.8,
	"StrongAttack4": 0.6,
	"WallSlide": 1,
	"WeakAttack1": 1.4,
	"WeakAttack2": 1.4,
	"WeakAttack3": 1.4,
	"WeakAttack4": 1.4,
	"bullet_dead_speredi": 2,
	"bullet_dead_szadi": 2,
	"cut_dead": 1,
	"fire_dead": 0.5,
	"hit_dead": 0.5,
	"reincarnation": 2,
	"stun": 2,
	"DamageDash": 25,
	"FirstDownDash": 10,
	"SecondDownDash": 10,
	"SpecialAttack1": 2,
}

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
var bullet_dead_anim_speredi: bool = false

var knockback_dir = 0

var speed = 400
var knockback_speed = 400
var jump_velocity = -450
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var hp = 175 : set = set_hp


@onready var hp_bar_sprite = $CanvasLayer/PlayerUI/hpBar
@onready var hp_number_1 = $CanvasLayer/PlayerUI/hp_number_1
@onready var hp_number_2 = $CanvasLayer/PlayerUI/hp_number_2
@onready var hp_number_3 = $CanvasLayer/PlayerUI/hp_number_3


func set_hp(value):
	if value > 175: value = 175
	if value < 0: value = 0
	var frame = ((175 - value) * 3) + 2
	hp_bar_sprite.frame = frame
	var array = []
	for i in str(value):
		array.append(int(i))
	if len(array) == 3:
		hp_number_1.frame = array[0]
		hp_number_2.frame = array[1]
		hp_number_3.frame = array[2]
	elif len(array) == 2:
		hp_number_1.frame = 0
		hp_number_2.frame = array[0]
		hp_number_3.frame = array[1]
	else:
		hp_number_1.frame = 0
		hp_number_2.frame = 0
		hp_number_3.frame = array[0]
	hp = value
	
	
func get_damage(source: String, damage: int, can_block_that_damage: bool, k_dir = 0, respect_damage_cd: bool = true, damager = null): #fire, bullet, hit, cut
	if not can_get_damage and respect_damage_cd:
		return
	
	if can_block_that_damage and state == states.BLOCKED:
		shake_camera()
		return
	
	if state == states.DASH or state == states.DEAD or state == states.REINCARNATION \
	or state == states.FRUIT_NINJA or cfg.cfg_data.undead or state == states.DOWN_DASH:
		return
		
	last_damage_source = source

	if not state == states.SPECIAL_ATTACK_1: hp -= damage
	
	global.camera.shake()
	
	can_get_damage = false
	gettin_damage_CD.start()
	
	knockback_dir = k_dir
	
	if hp <= 0:
		state_started = false
		from_jump_to_air_timer.stop()
		if damager != null:
			if damager.name == "TrapHitbox":
				damager.turn_into_bloody_version()
		state = states.DEAD
	elif not flashing:
		flashing = 1
		animated_sprite.material.set_shader_parameter("flash_modifier", 1.0)
		flashlight_timer.start()
		

func set_dir():
	dir = Input.get_axis("LEFT", "RIGHT")
	if dir:
		anim_dir = dir
	return dir

func set_anim(animation_name):
	pre_anim = anim.current_animation
	
	if need_to_change_col_size:
		change_col_size()
	
	if animation_name == states.WALL_SLIDE:
		animated_sprite.flip_h = wall_dir == -1
	else:
		animated_sprite.flip_h = !(anim_dir == 1)
		sword_hitbox.scale.x = anim_dir
		special_attack_1_hitbox.scale.x = anim_dir
		
	match animation_name:
		states.IDLE: 
			anim.play("Idle")
		states.RUN: 
			anim.play("Run")
		states.AIR: 
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
		states.JUMP:
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
		states.SIT: 
			anim.play("Sit")
		states.CROUCH: 
			anim.play("Crouch")
		states.ROLL:
			anim.play("Roll") 
		states.DASH: 
#			anim.play("Dash")
			anim.play("DamageDash")
		states.WALL_SLIDE:
			anim.play("WallSlide")
		states.WEAK_ATTACK_1:
			anim.play("WeakAttack1")
		states.WEAK_ATTACK_2:
			anim.play("WeakAttack2")
		states.WEAK_ATTACK_3:
			anim.play("WeakAttack3")
		states.WEAK_ATTACK_4:
			anim.play("WeakAttack4")
		states.STRONG_ATTACK_1:
			anim.play("StrongAttack1")
		states.STRONG_ATTACK_2:
			anim.play("StrongAttack2")
		states.STRONG_ATTACK_3:
			anim.play("StrongAttack3")
		states.STRONG_ATTACK_4:
			anim.play("StrongAttack4")
		states.LANDING:
			anim.play("SecondLanding")
		states.FIRST_JUMP_ATTACK_1:
			anim.play("FirstJumpAttack1")
		states.FIRST_JUMP_ATTACK_2:
			anim.play("FirstJumpAttack2")
		states.FIRST_JUMP_ATTACK_3:
			anim.play("FirstJumpAttack3")
		states.SECOND_JUMP_ATTACK_1:
			anim.play("SecondJumpAttack1")
		states.SECOND_JUMP_ATTACK_2:
			anim.play("SecondJumpAttack2")
		states.SECOND_JUMP_ATTACK_3:
			anim.play("SecondJumpAttack3")
		states.DEAD:
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
		states.BLOCKED:
			anim.play("Blocked")
		states.FRUIT_NINJA:
			anim.play("FruitNinja")
		states.REINCARNATION:
			anim.play("reincarnation")
		states.DOWN_DASH:
			if pre_jump == 1 or pre_jump == 0:
				anim.play("FirstDownDash")
			elif pre_jump == 2:
				anim.play("SecondDownDash")
		states.SPECIAL_ATTACK_1:
			anim.play("SpecialAttack1")
			
	if anim.current_animation != pre_anim:
		need_to_change_col_size = true
			
			
func _on_animation_player_animation_started(anim_name):
	anim.speed_scale = animations_speed_scales[anim_name]
	if slowed_cause_of_mk6: anim.speed_scale /= 2


func _ready():
	for anim_name in anim.get_animation_list():
		if anim_name == "RESET": continue
		if anim_name not in animations_speed_scales.keys():
			assert(false, "player's animations_time_scales dictionary is not full!")
			
	if len(states) != len(state_ins_counter.keys()):
		assert(false, "state_ins_counter dictionary is not full!")
	
	animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)
	global.player = self


func _physics_process(delta):
	match state:
		states.IDLE:
			idle()
		states.RUN:
			run()
		states.AIR:
			air(delta)
		states.JUMP:
			jump(delta)
		states.SIT:
			sit()
		states.CROUCH:
			crouch()
		states.WALL_SLIDE:
			wall_slide(delta)
		states.DASH:
			dash()
		states.ROLL:
			roll()
		states.WEAK_ATTACK_1:
			weak_attack_1()
		states.WEAK_ATTACK_2:
			weak_attack_2()
		states.WEAK_ATTACK_3:
			weak_attack_3()
		states.WEAK_ATTACK_4:
			weak_attack_4()
		states.STRONG_ATTACK_1:
			strong_attack_1()
		states.STRONG_ATTACK_2:
			strong_attack_2()
		states.STRONG_ATTACK_3:
			strong_attack_3()
		states.STRONG_ATTACK_4:
			strong_attack_4(delta)
		states.LANDING:
			landing()
		states.FIRST_JUMP_ATTACK_1:
			first_jump_attack_1()
		states.FIRST_JUMP_ATTACK_2:
			first_jump_attack_2()
		states.FIRST_JUMP_ATTACK_3:
			first_jump_attack_3()
		states.SECOND_JUMP_ATTACK_1:
			second_jump_attack_1()
		states.SECOND_JUMP_ATTACK_2:
			second_jump_attack_2()
		states.SECOND_JUMP_ATTACK_3:
			second_jump_attack_3()
		states.DEAD:
			dead(delta)
		states.BLOCKED:
			blocked()
		states.FRUIT_NINJA:
			fruit_ninja()
		states.REINCARNATION:
			reincarnation(delta)
		states.DOWN_DASH:
			down_dash(delta)
		states.SPECIAL_ATTACK_1:
			special_attack_1()

	if knockback_dir:
		if knockback_dir == dir:
			velocity.x = knockback_speed * 2 * knockback_dir
		else: velocity.x = knockback_speed * knockback_dir

	if flying_cause_of_mk6 and not state == states.DASH:
		velocity.y = -1
		velocity.x /= 500 * delta

	if slowed_cause_of_mk6 and not state == states.DASH:
		velocity = velocity/2

	move_and_slide()


func idle():
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == states.FRUIT_NINJA and can_fruit_ninja:
		can_fruit_ninja = false
		from_jump_to_air_timer.stop()
		Engine.time_scale = cfg.default_time_scale/4
		if np: print("from IDLE to FRUIT_NINJA")
		state = states.FRUIT_NINJA
		return
	
	if dir:
		if np:
			print("from idle to run")
		state = states.RUN
		return
		
	if not is_on_floor():
		if np:
			print("from idle to air")
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		state = states.AIR
		return
		
	if Input.is_action_pressed("SPECIAL ATTACK 1"):
		if np:
			print("from idle to special attack 1")
		from_jump_to_air_timer.stop()
		state = states.SPECIAL_ATTACK_1
		return
		
	if Input.is_action_pressed("DOWN DASH") and can_dash:
		can_dash = false
		if np:
			print("from idle to down_dash")
		state = states.DOWN_DASH
		return
		
	if Input.is_action_pressed("DASH") and can_dash:
		can_dash = false
		if np:
			print("from idle to DASH")
		state = states.DASH
		return
		
	if Input.is_action_pressed("BLOCK") and can_block:
		can_block = false
		if np:
			print("from idle to BLOCKED")
		state = states.BLOCKED
		return

	if Input.is_action_pressed("RMB ATTACK"):
		if weak_combo_index == 1:
			if np:
				print("from idle to weak_attack_1")
			state = states.WEAK_ATTACK_1
			weak_combo_index = 2
		elif weak_combo_index == 2:
			if np:
				print("from idle to weak_attack_2")
			state = states.WEAK_ATTACK_2
			weak_combo_index = 3
		elif weak_combo_index == 3:
			if np:
				print("from idle to weak_attack_3")
			state = states.WEAK_ATTACK_3
			weak_combo_index = 4
		elif weak_combo_index == 4:
			if np:
				print("from idle to weak_attack_4")
			state = states.WEAK_ATTACK_4
			weak_combo_index = 1 
		weak_combo_timer.start()
		return
		
	if Input.is_action_pressed("LMB ATTACK"):
		if strong_combo_index == 1:
			if np:
				print("from idle to strong_attack_1")
			state = states.STRONG_ATTACK_1
			strong_combo_index = 2
		elif strong_combo_index == 2:
			if np:
				print("from idle to strong_attack_2")
			state = states.STRONG_ATTACK_2
			strong_combo_index = 3
		elif strong_combo_index == 3:
			if np:
				print("from idle to STRONG_attack_3")
			state = states.STRONG_ATTACK_3
			strong_combo_index = 4
		elif strong_combo_index == 4:
			if np:
				print("from idle to STRONG_attack_4")
			state = states.STRONG_ATTACK_4
			strong_combo_index = 1 
		strong_combo_timer.start()
		return
		
	if Input.is_action_pressed("ROLL") and can_roll:
		can_roll = false
		if np:
			print("from idle to roll")
		state = states.ROLL
		return
		
	if Input.is_action_pressed("JUMP"):
		if np:
			print("from idle to jump")
		state = states.JUMP
		return
		
	if Input.is_action_pressed("DOWN"):
		if np:
			print("from idle to sit")
		state = states.SIT
		return
		
	set_anim(states.IDLE)
	set_dir()
	
	velocity.x = 0
	velocity.y = 0
		
		
func run():
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == states.FRUIT_NINJA and can_fruit_ninja:
		can_fruit_ninja = false
		from_jump_to_air_timer.stop()
		Engine.time_scale = cfg.default_time_scale/4
		if np: print("from RUN to FRUIT_NINJA")
		state = states.FRUIT_NINJA
		return
	
	if not is_on_floor():
		if np:
			print("from idle to air")
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		state = states.AIR
		return
		
	if Input.is_action_pressed("SPECIAL ATTACK 1"):
		if np:
			print("from RUN to special attack 1")
		from_jump_to_air_timer.stop()
		state = states.SPECIAL_ATTACK_1
		return
		
	if Input.is_action_pressed("DOWN DASH") and can_dash:
		can_dash = false
		if np:
			print("from run to down_dash")
		state = states.DOWN_DASH
		return
		
	if Input.is_action_pressed("DASH") and can_dash:
		can_dash = false
		if np:
			print("from run to DASH")
		state = states.DASH
		return
		
	if Input.is_action_pressed("BLOCK") and can_block:
		can_block = false
		if np:
			print("from run to BLOCKED")
		state = states.BLOCKED
		return
		
	if Input.is_action_pressed("RMB ATTACK"):
		if weak_combo_index == 1:
			if np:
				print("from idle to weak_attack_1")
			state = states.WEAK_ATTACK_1
			weak_combo_index = 2
		elif weak_combo_index == 2:
			if np:
				print("from idle to weak_attack_2")
			state = states.WEAK_ATTACK_2
			weak_combo_index = 3
		elif weak_combo_index == 3:
			if np:
				print("from idle to weak_attack_3")
			state = states.WEAK_ATTACK_3
			weak_combo_index = 4
		elif weak_combo_index == 4:
			if np:
				print("from idle to weak_attack_4")
			state = states.WEAK_ATTACK_4
			weak_combo_index = 1 
		weak_combo_timer.start()
		return
		
	if Input.is_action_pressed("LMB ATTACK"):
		if strong_combo_index == 1:
			if np:
				print("from idle to strong_attack_1")
			state = states.STRONG_ATTACK_1
			strong_combo_index = 2
		elif strong_combo_index == 2:
			if np:
				print("from idle to strong_attack_2")
			state = states.STRONG_ATTACK_2
			strong_combo_index = 3
		elif strong_combo_index == 3:
			if np:
				print("from idle to STRONG_attack_3")
			state = states.STRONG_ATTACK_3
			strong_combo_index = 4
		elif strong_combo_index == 4:
			if np:
				print("from idle to STRONG_attack_4")
			state = states.STRONG_ATTACK_4
			strong_combo_index = 1 
		strong_combo_timer.start()
		return
		
	if Input.is_action_pressed("ROLL") and can_roll:
		can_roll = false
		if np:
			print("from run to roll")
		state = states.ROLL
		return
		
	if Input.is_action_pressed("JUMP"):
		if np:
			print("from run to jump")
		state = states.JUMP
		return
		
	if Input.is_action_pressed("DOWN"):
		if np:
			print("from run to sit")
		state = states.SIT
		return
		
	set_anim(states.RUN)
	set_dir()
	
	velocity.y = 0
	if dir:
		velocity.x = dir * speed
	else:
		if np:
			print("from run to idle")
		state = states.IDLE
		return
	

func air(delta):
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == states.FRUIT_NINJA and can_fruit_ninja:
		can_fruit_ninja = false
		from_jump_to_air_timer.stop()
		Engine.time_scale = cfg.default_time_scale/4
		if np: print("from AIR to FRUIT_NINJA")
		state = states.FRUIT_NINJA
		return
	
	if is_on_floor():
		if np:
			print("from air to landing")
		jump_index = 1
		jump_attack_index = 1
		state = states.LANDING
		return
		
	if Input.is_action_pressed("SPECIAL ATTACK 1"):
		if np:
			print("from AIR to special attack 1")
		from_jump_to_air_timer.stop()
		state = states.SPECIAL_ATTACK_1
		return
		
	if Input.is_action_pressed("DOWN DASH") and can_dash:
		can_dash = false
		if np:
			print("from air to down_dash")
		state = states.DOWN_DASH
		return
		
	if Input.is_action_pressed("DASH") and can_dash:
		can_dash = false
		if np:
			print("from air to DASH")
		state = states.DASH
		return
		
	if Input.is_action_pressed("BLOCK") and can_block:
		can_block = false
		if np:
			print("from air to BLOCKED")
		state = states.BLOCKED
		return
		
	if not is_on_floor() and Input.is_action_just_pressed("JUMP") and jump_index == 2:
		jump_attack_index = 4
		jump_index = 0
		pre_jump = 2
		from_jump_to_air_timer.start()
		velocity.y = jump_velocity
		if np:
			print("from AIR to JUMP")
		state = states.JUMP
		return
		
	if (Input.is_action_pressed("RMB ATTACK") or Input.is_action_pressed("LMB ATTACK")) and not flying_cause_of_mk6:
		if pre_jump == 1 and not jump_attack_index > 3:
			from_jump_to_air_timer.stop()
			if jump_attack_index == 1:
				jump_attack_index = 2
				if np:
					print("from air to FIRST_JUMP_ATTACK_1")
				state = states.FIRST_JUMP_ATTACK_1
				return
			elif jump_attack_index == 2:
				jump_attack_index = 3
				if np:
					print("from air to FIRST_JUMP_ATTACK_2")
				state = states.FIRST_JUMP_ATTACK_2
				return
			elif jump_attack_index == 3:
				jump_attack_index = 4
				if np:
					print("from air to FIRST_JUMP_ATTACK_3")
				state = states.FIRST_JUMP_ATTACK_3
				return
		elif (pre_jump == 2 or pre_jump == 0) and not jump_attack_index < 4:
			from_jump_to_air_timer.stop()
			if jump_attack_index == 4:
				jump_attack_index = 5
				if np:
					print("from air to SECOND_JUMP_ATTACK_1")
				state = states.SECOND_JUMP_ATTACK_1
				return
			elif jump_attack_index == 5:
				jump_attack_index = 6
				if np:
					print("from air to SECOND_JUMP_ATTACK_2")
				state = states.SECOND_JUMP_ATTACK_2
				return
			elif jump_attack_index == 6:
				jump_attack_index = 0
				if np:
					print("from air to SECOND_JUMP_ATTACK_3")
				state = states.SECOND_JUMP_ATTACK_3
				return
		
	if wall_dir and !wall_jumping and !is_on_floor():
		velocity.y = 0
		dir = -wall_dir
		if dir:
			anim_dir = dir
		if np:
			print("from air to WALL_SLIDE")
		state = states.WALL_SLIDE
		return
		
	set_anim(states.AIR)
	update_wall_direction()
	set_dir()
	
	velocity.y += gravity * delta
	
	if dir:
		velocity.x = dir * speed
	else:
		velocity.x = 0


func jump(delta):
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == states.FRUIT_NINJA and can_fruit_ninja:
		can_fruit_ninja = false
		from_jump_to_air_timer.stop()
		Engine.time_scale = cfg.default_time_scale/4
		if np: print("from JUMP to FRUIT_NINJA")
		state = states.FRUIT_NINJA
		return
	
	if is_on_floor() and jump_index == 1:
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
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
		state = states.LANDING
		jump_index = 1
		jump_attack_index = 1
		return
		
	if Input.is_action_pressed("SPECIAL ATTACK 1"):
		if np:
			print("from JUMP to special attack 1")
		from_jump_to_air_timer.stop()
		state = states.SPECIAL_ATTACK_1
		return
		
	if Input.is_action_pressed("DOWN DASH") and can_dash:
		from_jump_to_air_timer.stop()
		can_dash = false
		if np:
			print("from jump to down_dash")
		state = states.DOWN_DASH
		return
		
	if Input.is_action_pressed("DASH") and can_dash:
		from_jump_to_air_timer.stop()
		can_dash = false
		if np:
			print("from jump to DASH")
		state = states.DASH
		return
		
	if Input.is_action_pressed("BLOCK") and can_block:
		can_block = false
		if np:
			print("from jump to BLOCKED")
		state = states.BLOCKED
		return
		
	if wall_dir and !wall_jumping and !is_on_floor():
		from_jump_to_air_timer.stop()
		velocity.y = 0
		dir = -wall_dir
		if dir:
			anim_dir = dir
		if np:
			print("from JUMP to WALL_SLIDE")
		state = states.WALL_SLIDE
		return
		
	if (Input.is_action_pressed("RMB ATTACK") or Input.is_action_pressed("LMB ATTACK")) and not flying_cause_of_mk6:
		if pre_jump == 1 and not jump_attack_index > 3:
			from_jump_to_air_timer.stop()
			if jump_attack_index == 1:
				jump_attack_index = 2
				if np:
					print("from jump to FIRST_JUMP_ATTACK_1")
				state = states.FIRST_JUMP_ATTACK_1
				return
			elif jump_attack_index == 2:
				jump_attack_index = 3
				if np:
					print("from jump to FIRST_JUMP_ATTACK_2")
				state = states.FIRST_JUMP_ATTACK_2
				return
			elif jump_attack_index == 3:
				jump_attack_index = 4
				if np:
					print("from jump to FIRST_JUMP_ATTACK_3")
				state = states.FIRST_JUMP_ATTACK_3
				return
		elif (pre_jump == 2 or pre_jump == 0) and not jump_attack_index < 4:
			from_jump_to_air_timer.stop()
			if jump_attack_index == 4:
				jump_attack_index = 5
				if np:
					print("from jump to SECOND_JUMP_ATTACK_1")
				state = states.SECOND_JUMP_ATTACK_1
				return
			elif jump_attack_index == 5:
				jump_attack_index = 6
				if np:
					print("from jump to SECOND_JUMP_ATTACK_2")
				state = states.SECOND_JUMP_ATTACK_2
				return
			elif jump_attack_index == 6:
				jump_attack_index = 0
				if np:
					print("from jump to SECOND_JUMP_ATTACK_3")
				state = states.SECOND_JUMP_ATTACK_3
				return
		
	set_anim(states.JUMP)
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
	state = states.AIR


func sit():
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == states.FRUIT_NINJA and can_fruit_ninja:
		can_fruit_ninja = false
		from_jump_to_air_timer.stop()
		Engine.time_scale = cfg.default_time_scale/4
		if np: print("from SIT to FRUIT_NINJA")
		state = states.FRUIT_NINJA
		return
	
	if check_if_can_stand_up():
		if !Input.is_action_pressed("DOWN"):
			if np:
				print("from sit to idle")
			state = states.IDLE
			return
		if Input.is_action_just_pressed("JUMP") and is_on_floor():
			if np:
				print("from sit to jump")
			state = states.JUMP
			return
			
	if dir:
		if np:
			print("from sit to crouch")
		state = states.CROUCH
		return
		
	if Input.is_action_pressed("ROLL") and can_roll:
		can_roll = false
		if np:
			print("from sit to roll")
		state = states.ROLL
		return
		
	if not is_on_floor():
		if np:
			print("from sit to air")
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		state = states.AIR
		return
		
	set_anim(states.SIT)
	set_dir()
	
	velocity.x = 0
	velocity.y = 0
	
	
func crouch():
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == states.FRUIT_NINJA and can_fruit_ninja:
		can_fruit_ninja = false
		from_jump_to_air_timer.stop()
		Engine.time_scale = cfg.default_time_scale/4
		if np: print("from CROUCH to FRUIT_NINJA")
		state = states.FRUIT_NINJA
		return
	
	if check_if_can_stand_up():
		if !Input.is_action_pressed("DOWN"):
			if np:
				print("from crouch to sit")
			state = states.SIT #maybe should be idle but works fine
			return
		if Input.is_action_just_pressed("JUMP") and is_on_floor():
			if np:
				print("from crouch to jump")
			state = states.JUMP
			return
		
	if not is_on_floor():
		if np:
			print("from crouch to air")
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		state = states.AIR
		return
		
	if Input.is_action_pressed("ROLL") and can_roll:
		can_roll = false
		if np:
			print("from crouch to roll")
		state = states.ROLL
		return
		
	set_anim(states.CROUCH)
	set_dir()
	
	velocity.y = 0
	
	if dir:
		velocity.x = dir * speed / 2
	else:
		if np:
			print("from crouch to sit")
		state = states.SIT
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
	if Input.is_action_just_pressed("FRUIT NINJA") and not state == states.FRUIT_NINJA and can_fruit_ninja:
		can_fruit_ninja = false
		from_jump_to_air_timer.stop()
		Engine.time_scale = cfg.default_time_scale/4
		print("from WALL_SLIDE to FRUIT_NINJA")
		state = states.FRUIT_NINJA
		return
	
	if Input.is_action_just_pressed("DOWN"):
		velocity.x = -wall_dir * speed
		if np:
			print("from wall_slide to air cause of DOWN button")
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		state = states.AIR
		return
	
	if Input.is_action_pressed("JUMP"):
		wall_slide_cooldown.start()
		wall_jumping = true
		jump_index = 0
		jump_attack_index = 4
		pre_jump = 0
		dir = 0
		if np:
			print("from wall_slide to jump")
		state = states.JUMP
		return
		
	if Input.is_action_pressed("SPECIAL ATTACK 1"):
		if np:
			print("from WALL_SLIDE to special attack 1")
		from_jump_to_air_timer.stop()
		state = states.SPECIAL_ATTACK_1
		return
		
	if Input.is_action_pressed("DOWN DASH") and can_dash:
		can_dash = false
		if np:
			print("from wall_slide to down_dash")
		state = states.DOWN_DASH
		return
		
	if Input.is_action_pressed("DASH") and can_dash:
		can_dash = false
		if np:
			print("from wall_slide to DASH")
		state = states.DASH
		return
		
	if is_on_floor():
		jump_index = 1
		if np:
			print("from wall_slide to idle")
		state = states.IDLE
		return
		
	if !wall_dir and not is_on_floor():
		if np:
			print("from wall_slide to air")
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		state = states.AIR
		return
	
	set_anim(states.WALL_SLIDE)
	update_wall_direction()
	
	velocity.y += gravity / 6 * delta
	velocity.x = wall_dir * speed
	
	
func _on_wall_slide_cooldown_timeout():
	wall_jumping = false
	
	
func special_attack_1():
	set_anim(states.SPECIAL_ATTACK_1)
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.SPECIAL_ATTACK_1]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.SPECIAL_ATTACK_1]:
			return
		if state == states.SPECIAL_ATTACK_1:
			if np:
				print("from special_attack_1 to AIR")
			pre_jump = 2
			jump_attack_index = 4
			state = states.AIR
			return
			
	velocity.x = anim_dir * speed
	velocity.y = 0
	
	
func dash():
	set_anim(states.DASH)
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.DASH]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.DASH]:
			return
		if state == states.DASH:
			if np:
				print("from dash to AIR")
			pre_jump = 2
			jump_attack_index = 4
			state = states.AIR
			return
			
	velocity.x = anim_dir * speed * 8
	velocity.y = 0
	
	
func down_dash(delta):
	set_anim(states.DOWN_DASH)
	if is_on_floor():
		if state == states.DOWN_DASH:
			if np:
				print("from down_dash to landing cause of floor")
			state = states.LANDING
			return
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.DOWN_DASH]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.DOWN_DASH]:
			return
		if state == states.DOWN_DASH:
			if np:
				print("from down_dash to AIR cause animation ended")
			pre_jump = 2
			jump_attack_index = 4
			state = states.AIR
			return
			
	velocity.x = 0
	velocity.y += gravity * delta * 20
		
		
func roll():
	if not is_on_floor():
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		if np:
			print("from ROLL to AIR")
		state = states.AIR
		return
	set_anim(states.ROLL)
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.ROLL]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.ROLL]:
			return
		if state == states.ROLL:
			if np:
				print("from ROLL to SIT")
			state = states.SIT
			return
			
	velocity.x = anim_dir * speed * 1.5
#	velocity.y = 0 # commetning this fixes bug, which causes
#		incorrect behavior of velocity.y after comming into AIR state from ROLL


func _on_animation_player_animation_finished(anim_name):
	if ((anim_name == "FirstAir" or anim_name == "SecondAir") and state == states.AIR) \
	or ((anim_name == "FirstJump" or anim_name == "SecondJump") and state == states.JUMP):
		single_anim_not_played_yet = false #bug with single_anim_not_played_it and air state most likely fixed this way
 

func weak_attack_1():
	set_dir()
	set_anim(states.WEAK_ATTACK_1)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.WEAK_ATTACK_1]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.WEAK_ATTACK_1]:
			return
		if state == states.WEAK_ATTACK_1:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from weak_attack_1 to idle")
			state = states.IDLE
			
			
func weak_attack_2():
	set_dir()
	set_anim(states.WEAK_ATTACK_2)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.WEAK_ATTACK_2]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.WEAK_ATTACK_2]:
			return
		if state == states.WEAK_ATTACK_2:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from weak_attack_2 to idle")
			state = states.IDLE
			
			
func weak_attack_3():
	set_dir()
	set_anim(states.WEAK_ATTACK_3)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.WEAK_ATTACK_3]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.WEAK_ATTACK_3]:
			return
		if state == states.WEAK_ATTACK_3:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from weak_attack_3 to idle")
			state = states.IDLE
		
		
func weak_attack_4():
	set_dir()
	set_anim(states.WEAK_ATTACK_4)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.WEAK_ATTACK_4]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.WEAK_ATTACK_4]:
			return
		if state == states.WEAK_ATTACK_4:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from weak_attack_4 to idle")
			state = states.IDLE
			
			
func _on_weak_combo_timer_timeout():
	weak_combo_index = 1
	

func strong_attack_1():
	set_dir()
	set_anim(states.STRONG_ATTACK_1)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.STRONG_ATTACK_1]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.STRONG_ATTACK_1]:
			return
		if state == states.STRONG_ATTACK_1:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from strong_attack_1 to idle")
			state = states.IDLE
			
			
func strong_attack_2():
	set_dir()
	set_anim(states.STRONG_ATTACK_2)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.STRONG_ATTACK_2]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.STRONG_ATTACK_2]:
			return
		if state == states.STRONG_ATTACK_2:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from strong_attack_2 to idle")
			state = states.IDLE
			
			
func strong_attack_3():
	set_dir()
	set_anim(states.STRONG_ATTACK_3)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.STRONG_ATTACK_3]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.STRONG_ATTACK_3]:
			return
		if state == states.STRONG_ATTACK_3:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from strong_attack_3 to idle")
			state = states.IDLE
			
			
func strong_attack_4(delta):
	set_dir()
	set_anim(states.STRONG_ATTACK_4)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y += gravity * 15 * delta 
	if !state_started:
		velocity.y = jump_velocity * 3
		state_started = true
		var state_ins_number = state_ins_counter[states.STRONG_ATTACK_4]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.STRONG_ATTACK_4]:
			return
		if state == states.STRONG_ATTACK_4:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			if np:
				print("from strong_attack_4 to idle")
			state = states.IDLE


func _on_strong_combo_timer_timeout():
	strong_combo_index = 1


func landing():
	set_anim(states.LANDING)
	set_dir()
	if not is_on_floor():
		jump_index = 2
		pre_jump = 1
		jump_attack_index = 1
		state_started = false
		if np:
			print("from landing to AIR")
		state = states.AIR
		return
	if Input.is_action_pressed("JUMP"):
		if np:
			print("from landing to jump")
		state = states.JUMP
		return
	velocity.x = dir * speed
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.LANDING]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.LANDING]:
			return
		if state == states.LANDING:
			if np:
				print("from landing to sit")
			state = states.SIT


func first_jump_attack_1():
	set_dir()
	set_anim(states.FIRST_JUMP_ATTACK_1)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.FIRST_JUMP_ATTACK_1]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.FIRST_JUMP_ATTACK_1]:
			return
		if state == states.FIRST_JUMP_ATTACK_1:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			jump_index = 2
			if np:
				print("from FIRST_JUMP_ATTACK_1 to AIR")
			state = states.AIR
	
	
func first_jump_attack_2():
	set_dir()
	set_anim(states.FIRST_JUMP_ATTACK_2)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.FIRST_JUMP_ATTACK_2]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.FIRST_JUMP_ATTACK_2]:
			return
		if state == states.FIRST_JUMP_ATTACK_2:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			jump_index = 2
			if np:
				print("from FIRST_JUMP_ATTACK_2 to AIR")
			state = states.AIR
	
	
func first_jump_attack_3():
	set_dir()
	set_anim(states.FIRST_JUMP_ATTACK_3)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.FIRST_JUMP_ATTACK_3]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.FIRST_JUMP_ATTACK_3]:
			return
		if state == states.FIRST_JUMP_ATTACK_3:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			jump_index = 2
			if np:
				print("from FIRST_JUMP_ATTACK_3 to AIR")
			state = states.AIR
	
	
func second_jump_attack_1():
	set_dir()
	set_anim(states.SECOND_JUMP_ATTACK_1)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.SECOND_JUMP_ATTACK_1]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.SECOND_JUMP_ATTACK_1]:
			return
		if state == states.SECOND_JUMP_ATTACK_1:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			jump_index = 0
			if np:
				print("from SECOND_JUMP_ATTACK_1 to AIR")
			state = states.AIR
	
	
func second_jump_attack_2():
	set_dir()
	set_anim(states.SECOND_JUMP_ATTACK_2)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.SECOND_JUMP_ATTACK_2]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.SECOND_JUMP_ATTACK_2]:
			return
		if state == states.SECOND_JUMP_ATTACK_2:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			jump_index = 0
			if np:
				print("from SECOND_JUMP_ATTACK_2 to AIR")
			state = states.AIR
	
	
func second_jump_attack_3():
	set_dir()
	set_anim(states.SECOND_JUMP_ATTACK_3)
	if anim_dir == 1 and Input.is_action_pressed("RIGHT"):
		velocity.x = anim_dir * speed / 5
	elif anim_dir == -1 and Input.is_action_pressed("LEFT"):
		velocity.x = anim_dir * speed / 5
	else:
		velocity.x = anim_dir * speed / 30
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.SECOND_JUMP_ATTACK_3]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.SECOND_JUMP_ATTACK_3]:
			return
		if state == states.SECOND_JUMP_ATTACK_3:
			particles_manager.create_sword_particles(sword_hitbox_col.global_position)
			jump_index = 0
			if np:
				print("from SECOND_JUMP_ATTACK_3 to AIR")
			state = states.AIR


func blocked():
	set_anim(states.BLOCKED)
	velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.BLOCKED]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.BLOCKED]:
			return
		if state == states.BLOCKED:
			if np:
				print("from BLOCKED to AIR")
		state = states.AIR
	
	
func dead(delta):
	set_anim(states.DEAD)
	velocity.y += gravity * delta
	velocity.x = 0
	if !state_started:
		Engine.time_scale = cfg.default_time_scale
		$SwordHitbox/CollisionShape2D.disabled = true
		$DashHitbox/CollisionShape2D.disabled = true
		$SpecialAttack1Hitbox/CollisionShape2D.disabled = true
		ui.visible = false
		$CanvasLayer/LensFlare.visible = false
		death_screen.visible = true
		state_started = true
		
		
func fruit_ninja():
	velocity.y = 0
	velocity.x = 0
	
	if fruit_ninjaing_thru_line:
		if !state_started:
			animated_sprite.visible = false
			$PointLightContainer.visible = false
			
			state_started = true
			Engine.time_scale = cfg.default_time_scale
			
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
				print("from fruit ninja to LANDING")
			animated_sprite.visible = true
			$PointLightContainer.visible = true
			state = states.LANDING
			return
	else:
		if (Input.is_action_pressed("LMB ATTACK") or Input.is_action_pressed("RMB ATTACK")) and not fruit_ninja_line_already_painted:
			if not fruit_ninjaing: 
				fruit_ninja_particles.emitting = true
				fruit_ninja_timer.start()
				fruit_ninjaing = true
			if fruit_ninja_line.get_point_count() > 0:
				if get_global_mouse_position().distance_to(fruit_ninja_line.points[fruit_ninja_line.get_point_count() - 1]) > 5.0:
					fruit_ninja_line.add_point(get_global_mouse_position())
			else:
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
	if state == states.FRUIT_NINJA and body not in fruit_ninja_targets and not fruit_ninjaing_thru_line and body.is_alive():
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


func _on_lens_flare_anim_animation_finished(anim_name):
	lens_flare_anim.get_animation("default").track_set_key_value(0, 1, Vector2(randi_range(-100, 1000), randi_range(-150, 100)))
	lens_flare_anim.get_animation("default").track_set_key_value(0, 0, Vector2(randi_range(-100, 1000), randi_range(-150, 100)))
#	lens_flare_anim.get_animation("default").track_set_key_value(1, 1, randf_range(0.7, 1.0))
	lens_flare_anim.speed_scale = randf_range(0.5, 1.2)
	lens_flare_timer.wait_time = randi_range(30, 45)
	lens_flare_timer.start()


func _on_lens_flare_timer_timeout():
	lens_flare_anim.play("default")
	
	
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
		blood_manager.create_blood_drops(0, blood_pos)


func reincarnation(delta):
	set_anim(states.REINCARNATION)
	velocity.x = 0
	velocity.y += gravity * delta * 10
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.REINCARNATION]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.REINCARNATION]:
			return
		if state == states.REINCARNATION:
			if np:
				print("from REINC to idle")
			state = states.IDLE
			
			
func change_scene_to_dead_screen():
	get_tree().paused = true
	death_screen.set_process_input(true)
	

func shake_camera():
	global.camera.shake(2)


func _on_gettin_damage_cd_timeout():
	can_get_damage = true
	
func _on_flashlight_timer_timeout():
	if flashing == 1:
		animated_sprite.material.set_shader_parameter("flash_modifier", 0.5)
		flashing = 2
		flashlight_timer.start()
	elif flashing == 2:
		animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)
		flashing = 0
		knockback_dir = 0
		
		if not is_on_floor():
			velocity.y = 0
			velocity.x= 0
		
		
func change_col_to_crouch_mode():
	col.shape.size = Vector2(32, 63)
	col.position = Vector2(0, -31.5)
	hurtbox_4_traps_col.shape.size = Vector2(30, 37)
	hurtbox_4_traps_col.position = Vector2(0, -31.5)
	need_to_change_col_size = false
	
	
func change_col_to_full_size():
	col.shape.size = Vector2(32, 90)
	col.position = Vector2(0, -45)
	hurtbox_4_traps_col.shape.size = Vector2(30, 54)
	hurtbox_4_traps_col.position = Vector2(0, -45)
	need_to_change_col_size = false
	
	
func change_col_size():
	if anim.current_animation == "Crouch" or anim.current_animation == "FirstJump" or anim.current_animation == "FirstJumpCycle" \
	 or anim.current_animation == "Roll" or anim.current_animation == "Sit" or anim.current_animation == "WallSlide":
		change_col_to_crouch_mode()
	elif can_increase_col:
		change_col_to_full_size()


func _on_can_change_collision_checker_body_entered(body):
	can_increase_col = false


func _on_can_change_collision_checker_body_exited(body):
	can_increase_col = true 
