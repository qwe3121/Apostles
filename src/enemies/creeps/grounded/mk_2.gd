extends CharacterBody2D


var hp = 2
var speed = 100
var knockback_speed = 100

var close_en_to_attack = false
var close_en_to_ulti = false
var close_en_to_prefire_attack = false
var close_en_to_prefire_ulti = false

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
@onready var turned_timer = $TurnedTimer
@onready var attack_cooldown = $AttackCooldown
@onready var ulti_cooldown = $UltiCooldown
@onready var blood_pos = $BloodPos
@onready var ulti_hitbox = $UltiHitbox/CollisionShape2D
@onready var attack_hitbox = $AttackHitbox/CollisionShape2D
@onready var move_back_timer = $MoveBackTimer
var need_to_check_if_see_player = false

@onready var small_move_back_col = $CheckIfPlayerInside/SmallCol
@onready var big_move_back_col = $CheckIfPlayerInside/BigCol

@onready var gettin_damage_CD = $GettinDamageCD

@onready var move_particles = $MoveParticles
var can_show_move_particles = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum states {IDLE, RUN, BEFORE_ATTACK, ATTACK, AFTER_ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, \
AIR, FRUIT_DEAD, BEFORE_ATTACK_N_RUN, \
ATTACK_N_RUN, AFTER_ATTACK_N_RUN, BEFORE_ULTI_N_RUN, ULTI_N_RUN, AFTER_ULTI_N_RUN, STUNNED}

var state_ins_counter = {
	states.IDLE: 0,
	states.RUN: 0,
	states.BEFORE_ATTACK: 0,
	states.ATTACK: 0,
	states.AFTER_ATTACK: 0,
	states.BEFORE_ULTI: 0,
	states.ULTI: 0,
	states.AFTER_ULTI: 0,
	states.DEAD: 0,
	states.AIR: 0,
	states.FRUIT_DEAD: 0,
	states.BEFORE_ATTACK_N_RUN: 0,
	states.ATTACK_N_RUN: 0,
	states.AFTER_ATTACK_N_RUN: 0,
	states.BEFORE_ULTI_N_RUN: 0,
	states.ULTI_N_RUN: 0,
	states.AFTER_ULTI_N_RUN: 0,
	states.STUNNED: 0
}

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
			return "AFTER_ATTACK"
		5: 
			return "BEFORE_ULTI"
		6:
			return "ULTI"
		7:
			return "AFTER_ULTI"
		8:
			return "DEAD"
		9:
			return "AIR"
		10:
			return "FRUIT_DEAD"
		11:
			return "STUNNED"

var state = states.AIR : set = set_state

func set_state(value):
	if state == states.STUNNED:
		if value != states.IDLE and value != states.DEAD and value != states.FRUIT_DEAD:
			return
	
	if value == states.DEAD or value == states.FRUIT_DEAD:
		if player_move_state == move_state_const.MOVE_BACK:
			dir *= -1
			anim_dir *= -1
			
	player_move_state = move_state_const.RUN
	
	if state == states.DEAD or state == states.FRUIT_DEAD:
		return
		
	state_ins_counter[value] += 1
	if state_ins_counter[value] > 1000:
		state_ins_counter[value] = 0
	
	if not state == value: state_started = false
#	print("from " + const_to_str(state) + " into " + const_to_str(value))
	state = value

var dir = 1
var anim_dir = 1
var attack_dir = 1

var state_started = false

var can_attack = true
var can_ulti = false : set = set_can_ulti

func set_can_ulti(value):
	can_ulti = false

var walking = 1 #1 is walking 0 is chilling

var chasing = false

var there_is_blocked_area = false

var is_on_wall

var turned = false

var flashing = 0
var knockback_dir = 0

var last_knockback_dir = 0

var player_is_inside = false
var need_to_choose_dir_to_move_back = false
var player_is_deep_inside = false
var player_move_state
enum move_state_const {IDLE, RUN, MOVE_BACK}

var can_get_damage = true

var visible_on_screen = false

var unit_is_stunned = false
@onready var stun_duration_timer = $StunDuration


func _ready():
	if len(states) != len(state_ins_counter.keys()):
		assert(false, "state_ins_counter dictionary is not full!")
	
	animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)

	blood.modulate.a = randf_range(0.6, 1.0)
	
	
func _on_walking_timer_ready():
	$WalkingTimer.wait_time = randi_range(1,5)
	$WalkingTimer.start()


func get_damage(value, k_dir = 0, damager = null, do_stun: bool = false, stun_dur: int = 2):
	if not can_get_damage and damager == null:
		return
		
	if state == states.DEAD or state == states.FRUIT_DEAD:
		return
	
	hp -= value
	if do_stun: stun(stun_dur)
	knockback_dir = k_dir
	can_show_move_particles = false
	
	can_get_damage = false
	gettin_damage_CD.start()
	
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
		state = states.DEAD
	elif not flashing:
		flashing = 1
		animated_sprite.material.set_shader_parameter("flash_modifier", 1.0)
		flashlight_timer.start()
	global.camera.shake()
		
func set_anim(animation_name):
	if player_move_state == move_state_const.MOVE_BACK:
		if move_back_timer.is_stopped():
			move_back_timer.start()
	else:
		if not move_back_timer.is_stopped():
			move_back_timer.stop()
		
	if see_player or chasing:
		if not unit_is_stunned and is_alive():
			animated_sprite.flip_h = attack_dir == 1
			attack_hitbox.position.x = 32 * attack_dir
			ulti_hitbox.position.x = 49 * attack_dir
	else:
		if not unit_is_stunned and is_alive():
			animated_sprite.flip_h = anim_dir == 1
			attack_hitbox.position.x = 32 * anim_dir
			ulti_hitbox.position.x = 49 * anim_dir
		
	blood.flip_h = !(last_knockback_dir == 1)
	check_for_pit.position.x = 24.75 * anim_dir
	check_for_blocked_area_col.position.x = 23.5 * anim_dir
	wall_detector_col.position.x = 18.25 * anim_dir

	match animation_name:
		states.IDLE: 
			if chasing or see_player:
				anim.play("idle")
			else:
				anim.play("p_idle")
		states.RUN: 
			if chasing or see_player:
				anim.play("run")
			else:
				anim.play("p_run")
		states.BEFORE_ATTACK:
			if anim.current_animation == "before_attack_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("before_attack")
				anim.seek(cur_pos, true)
			else:
				anim.play("before_attack")
		states.BEFORE_ATTACK_N_RUN:
			if anim.current_animation == "before_attack":
				var cur_pos = anim.current_animation_position
				anim.play("before_attack_n_run")
				anim.seek(cur_pos, true)
			else:
				anim.play("before_attack_n_run")
		states.ATTACK:
			if anim.current_animation == "attack_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("attack")
				anim.seek(cur_pos, true)
			else:
				anim.play("attack")
		states.ATTACK_N_RUN:
			if anim.current_animation == "attack":
				var cur_pos = anim.current_animation_position
				anim.play("attack_n_run")
				anim.seek(cur_pos, true)
			else:
				anim.play("attack_n_run")
		states.AFTER_ATTACK:
			if anim.current_animation == "after_attack_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("after_attack")
				anim.seek(cur_pos, true)
			else:
				anim.play("after_attack")
		states.AFTER_ATTACK_N_RUN:
			if anim.current_animation == "after_attack":
				var cur_pos = anim.current_animation_position
				anim.play("after_attack_n_run")
				anim.seek(cur_pos, true)
			else:
				anim.play("after_attack_n_run")
		states.BEFORE_ULTI:
			if anim.current_animation == "before_ulti_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("before_ulti")
				anim.seek(cur_pos, true)
			else:
				anim.play("before_ulti")
		states.BEFORE_ULTI_N_RUN:
			if anim.current_animation == "before_ulti":
				var cur_pos = anim.current_animation_position
				anim.play("before_ulti_n_run")
				anim.seek(cur_pos, true)
			else:
				anim.play("before_ulti_n_run")
		states.ULTI:
			if anim.current_animation == "ulti_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("ulti")
				anim.seek(cur_pos, true)
			else:
				anim.play("ulti")
		states.ULTI_N_RUN:
			if anim.current_animation == "ulti":
				var cur_pos = anim.current_animation_position
				anim.play("ulti_n_run")
				anim.seek(cur_pos, true)
			else:
				anim.play("ulti_n_run")
		states.AFTER_ULTI:
			if anim.current_animation == "after_ulti_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("after_ulti")
				anim.seek(cur_pos, true)
			else:
				anim.play("after_ulti")
		states.AFTER_ULTI_N_RUN:
			if anim.current_animation == "after_ulti":
				var cur_pos = anim.current_animation_position
				anim.play("after_ulti_n_run")
				anim.seek(cur_pos, true)
			else:
				anim.play("after_ulti_n_run")
		states.DEAD:
			anim.play("dead")
		states.FRUIT_DEAD:
			anim.play("fruit_ninja_dead")
		states.STUNNED:
			anim.play("stun")


func set_dir():
	if player_is_deep_inside: return
	if global_position.x < global.player.global_position.x:
		dir = 1
	else:
		dir = -1
	anim_dir = dir
	
	
func set_dir_to_move_back(choose_dir_randomly: bool):
	if choose_dir_randomly:
		dir = 1 if randi_range(0,1) else -1
	else:
		if global_position.x < global.player.global_position.x:
			dir = -1
		else:
			dir = 1
		
	anim_dir = dir
	
	
func set_attack_dir():
	if player_is_deep_inside: return

	if global_position.x < global.player.global_position.x:
		attack_dir = 1
	else:
		attack_dir = -1

func _physics_process(delta):
	if velocity.x != 0 and can_show_move_particles:
		if can_show_move_particles: move_particles.visible = true
		if velocity.x > 0:
			if animated_sprite.flip_h:
				move_particles.position.x = 2
				move_particles.flip_h = true
			else:
				move_particles.position.x = -3
				move_particles.flip_h = true
		elif velocity.x < 0:
			if animated_sprite.flip_h:
				move_particles.position.x = 3
				move_particles.flip_h = false
			else:
				move_particles.position.x = -2
				move_particles.flip_h = false
	else:
		move_particles.visible = false
	
	if not can_attack and not attack_cooldown.is_stopped():
		small_move_back_col.disabled = true
		big_move_back_col.disabled = false
	else:
		small_move_back_col.disabled = false
		big_move_back_col.disabled = true
	
	if need_to_check_if_see_player:
		if not check_if_vision_is_blocked_by_wall() and visible_on_screen:
			on_see_player()
		else:
			on_unsee_player()
			
	if see_player:
		set_attack_dir()

	match state:
		states.IDLE: 
			idle()
		states.RUN: 
			run()
		states.AIR:
			air(delta)
		states.BEFORE_ATTACK:
			before_attack(delta)
		states.ATTACK:
			attack(delta)
		states.AFTER_ATTACK:
			after_attack(delta)
		states.BEFORE_ULTI:
			before_ulti(delta)
		states.ULTI:
			ulti(delta)
		states.AFTER_ULTI:
			after_ulti(delta)
		states.DEAD:
			dead(delta)
		states.FRUIT_DEAD:
			fruit_dead(delta)
		states.STUNNED:
			stunned(delta)
			
	if knockback_dir and not (state == states.DEAD or state == states.FRUIT_DEAD):
		if knockback_dir == dir:
			velocity.x = knockback_speed * 2 * knockback_dir
		else: velocity.x = knockback_speed * knockback_dir
			
	move_and_slide()


func idle():
	if not is_on_floor():
		state = states.AIR
		return
	
	if see_player:
		if not player_is_inside: set_dir()
		if can_attack:
			if can_ulti and close_en_to_prefire_ulti:
				state = states.BEFORE_ULTI
				return
			if can_attack and close_en_to_prefire_attack:
				state = states.BEFORE_ATTACK
				return
		if player_is_inside or (not close_en_to_attack and big_move_back_col.disabled):
			state = states.RUN
			return
	else:
		if walking:
			dir = 1 if randi_range(0,1) else -1
			anim_dir = dir
			state = states.RUN
			return
			
	set_anim(states.IDLE)
	
	velocity.y = 0
	velocity.x = 0
			
			
func run():
	if not is_on_floor():
		state = states.AIR
		return
		
	if see_player:
		if not player_is_inside: set_dir()
		if can_attack:
			if can_ulti and close_en_to_prefire_ulti:
				state = states.BEFORE_ULTI
				return
			if can_attack and close_en_to_prefire_attack:
				state = states.BEFORE_ATTACK
				return
		if player_is_inside:
			if need_to_choose_dir_to_move_back:
				need_to_choose_dir_to_move_back = false
				set_dir_to_move_back(false)
		elif close_en_to_attack or not big_move_back_col.disabled:
			dir = 0
			player_move_state = move_state_const.IDLE
			state = states.IDLE
			return
			
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and (see_player or chasing):
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		dir = anim_dir
		player_move_state = move_state_const.RUN
	else:
		dir = anim_dir
		player_move_state = move_state_const.MOVE_BACK
		
	if player_move_state == move_state_const.IDLE:
		set_anim(states.IDLE)
	else:
		set_anim(states.RUN)
		
	velocity.y = 0
	velocity.x = dir * speed
	
	
func air(delta):
	if is_on_floor():
		state = states.IDLE
		return
		
	set_anim(states.AIR)
	
	velocity.y += gravity * delta
	velocity.x = 0
	
	
func before_attack(delta):
	if see_player:
		if not player_is_inside: 
			set_dir()
		else:
			if need_to_choose_dir_to_move_back:
				need_to_choose_dir_to_move_back = false
				set_dir_to_move_back(false)
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or (close_en_to_attack and not player_is_inside)) and (see_player or chasing):
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		dir = anim_dir
		player_move_state = move_state_const.RUN
	else:
		dir = anim_dir
		player_move_state = move_state_const.MOVE_BACK
		
	if player_move_state == move_state_const.IDLE:
		set_anim(states.BEFORE_ATTACK)
	else:
		set_anim(states.BEFORE_ATTACK_N_RUN)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		can_attack = false
		var state_ins_number = state_ins_counter[states.BEFORE_ATTACK]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.BEFORE_ATTACK]:
			return
		if state == states.BEFORE_ATTACK:
			state = states.ATTACK
	
	
func attack(delta):
	if see_player:
		if not player_is_inside: 
			set_dir()
		else:
			if need_to_choose_dir_to_move_back:
				need_to_choose_dir_to_move_back = false
				set_dir_to_move_back(false)
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or (close_en_to_attack and not player_is_inside)) and (see_player or chasing):
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		dir = anim_dir
		player_move_state = move_state_const.RUN
	else:
		dir = anim_dir
		player_move_state = move_state_const.MOVE_BACK
		
	if player_move_state == move_state_const.IDLE:
		set_anim(states.ATTACK)
	else:
		set_anim(states.ATTACK_N_RUN)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.ATTACK]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.ATTACK]:
			return
		if state == states.ATTACK:
			state = states.AFTER_ATTACK
			
			
func after_attack(delta):
	if see_player:
		if not player_is_inside: 
			set_dir()
		else:
			if need_to_choose_dir_to_move_back:
				need_to_choose_dir_to_move_back = false
				set_dir_to_move_back(false)
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or (close_en_to_attack and not player_is_inside)) and (see_player or chasing):
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		dir = anim_dir
		player_move_state = move_state_const.RUN
	else:
		dir = anim_dir
		player_move_state = move_state_const.MOVE_BACK
		
	if player_move_state == move_state_const.IDLE:
		set_anim(states.AFTER_ATTACK)
	else:
		set_anim(states.AFTER_ATTACK_N_RUN)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.AFTER_ATTACK]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.AFTER_ATTACK]:
			return
		if state == states.AFTER_ATTACK:
			attack_cooldown.start()
			if not chasing:
				walking = 0
				walking_timer_start()
				state = states.IDLE
			else:
				state = states.RUN
			
			
func before_ulti(delta):
	if see_player:
		if not player_is_inside: 
			set_dir()
		else:
			if need_to_choose_dir_to_move_back:
				need_to_choose_dir_to_move_back = false
				set_dir_to_move_back(false)
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or (close_en_to_ulti and not player_is_inside)) and (see_player or chasing):
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		dir = anim_dir
		player_move_state = move_state_const.RUN
	else:
		dir = anim_dir
		player_move_state = move_state_const.MOVE_BACK
		
	if player_move_state == move_state_const.IDLE:
		set_anim(states.BEFORE_ULTI)
	else:
		set_anim(states.BEFORE_ULTI_N_RUN)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		attack_cooldown.stop()
		can_attack = false
		can_ulti = false
		var state_ins_number = state_ins_counter[states.BEFORE_ULTI]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.BEFORE_ULTI]:
			return
		if state == states.BEFORE_ULTI:
			state = states.ULTI
	
	
func ulti(delta):
	if see_player:
		if not player_is_inside: 
			set_dir()
		else:
			if need_to_choose_dir_to_move_back:
				need_to_choose_dir_to_move_back = false
				set_dir_to_move_back(false)
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or (close_en_to_ulti and not player_is_inside)) and (see_player or chasing):
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		dir = anim_dir
		player_move_state = move_state_const.RUN
	else:
		dir = anim_dir
		player_move_state = move_state_const.MOVE_BACK
		
	if player_move_state == move_state_const.IDLE:
		set_anim(states.ULTI)
	else:
		set_anim(states.ULTI_N_RUN)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.ULTI]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.ULTI]:
			return
		if state == states.ULTI:
			state = states.AFTER_ULTI
			
			
func after_ulti(delta):
	if see_player:
		if not player_is_inside: 
			set_dir()
		else:
			if need_to_choose_dir_to_move_back:
				need_to_choose_dir_to_move_back = false
				set_dir_to_move_back(false)
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or (close_en_to_attack and not player_is_inside)) and (see_player or chasing):
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		dir = anim_dir
		player_move_state = move_state_const.RUN
	else:
		dir = anim_dir
		player_move_state = move_state_const.MOVE_BACK
		
	if player_move_state == move_state_const.IDLE:
		set_anim(states.AFTER_ULTI)
	else:
		set_anim(states.AFTER_ULTI_N_RUN)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.AFTER_ULTI]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.AFTER_ULTI]:
			return
		if state == states.AFTER_ULTI:
			ulti_cooldown.start()
			attack_cooldown.start()
			if not chasing:
				walking = 0
				walking_timer_start()
				state = states.IDLE
			else:
				state = states.RUN
	
	
func dead(delta):
	set_anim(states.DEAD)
	velocity.x = 0
	if not is_on_floor(): velocity.y += gravity * delta
	if !state_started:
		state_started = true
		ulti_hitbox.disabled = true
		attack_hitbox.disabled = true
		$CollisionHitbox/CollisionShape2D.disabled = true
		global.player.killstreak += 1
		for c in range(b_drops):
			blood_manager.create_blood_drops(last_knockback_dir, blood_pos)
		var state_ins_number = state_ins_counter[states.DEAD]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.DEAD]:
			return
		if state == states.DEAD:
			queue_free()


func _on_walking_timer_timeout():
	if not state == states.BEFORE_ATTACK and not state == states.ATTACK and not state == states.AFTER_ATTACK \
	and not state == states.BEFORE_ULTI and not state == states.ULTI and not state == states.AFTER_ULTI \
	and not state == states.STUNNED:
		if walking:
			walking = 0
			state = states.IDLE
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
	
	if state == states.DEAD or state == states.FRUIT_DEAD:
		return
		
	see_player = false
	
	chasing = true
	chase_timer.start()
	
	if player_move_state == move_state_const.MOVE_BACK:
		dir *= -1
		anim_dir = dir
	
	if not state == states.BEFORE_ATTACK and not state == states.ATTACK and not state == states.AFTER_ATTACK \
	and not state == states.BEFORE_ULTI and not state == states.ULTI and not state == states.AFTER_ULTI \
	and not state == states.STUNNED:
		state = states.RUN
		
		
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
	if not state == states.BEFORE_ATTACK and not state == states.ATTACK and not state == states.AFTER_ATTACK \
	and not state == states.BEFORE_ULTI and not state == states.ULTI and not state == states.AFTER_ULTI \
	and not state == states.STUNNED:
		walking = 0
		walking_timer_start()
		state = states.IDLE


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
		can_show_move_particles = true
		
		velocity.y = 0
		velocity.x = 0


func _on_wall_detector_body_entered(body):
	is_on_wall = true


func _on_wall_detector_body_exited(body):
	is_on_wall = false


func _on_check_if_player_inside_body_entered(body):
	player_is_inside = true
	need_to_choose_dir_to_move_back = true


func _on_check_if_player_inside_body_exited(body):
	player_is_inside = false
		
		
func kill_with_fruit_ninja():
	chase_timer.stop()
	walking_timer.stop()
	state = states.FRUIT_DEAD
	global.camera.shake()
	
	
func fruit_dead(delta):
	set_anim(states.FRUIT_DEAD)
	velocity.x = 0
	if not is_on_floor(): velocity.y += gravity * delta
	if !state_started:
		state_started = true
		ulti_hitbox.disabled = true
		attack_hitbox.disabled = true
		$CollisionHitbox/CollisionShape2D.disabled = true
		last_knockback_dir = 1 if global_position > global.player.global_position else -1
		global.player.killstreak += 1
		for c in range(b_drops):
			blood_manager.create_blood_drops(last_knockback_dir, blood_pos)
		var state_ins_number = state_ins_counter[states.FRUIT_DEAD]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.FRUIT_DEAD]:
			return
		if state == states.FRUIT_DEAD:
			events.emit_signal("fruit_kill")
			queue_free()
			
			
func stunned(delta):
	set_anim(states.STUNNED)
	velocity.x = 0
	if not is_on_floor(): velocity.y += gravity * delta
	if !state_started:
		state_started = true
		ulti_hitbox.disabled = true
		attack_hitbox.disabled = true
	if not unit_is_stunned:
		if state == states.STUNNED:
			ulti_cooldown.start()
			attack_cooldown.start()
			walking = 0
			walking_timer_start()
			state = states.IDLE
			
			
func stun(duration: int = 2):
	if unit_is_stunned: return
	unit_is_stunned = true

	walking_timer.stop()
	attack_cooldown.stop()
	ulti_cooldown.stop()
	chase_timer.stop()

	can_attack = false
	can_ulti = false

	stun_duration_timer.wait_time = duration
	stun_duration_timer.start()
	state = states.STUNNED
	
	
func _on_stun_duration_timeout():
	unit_is_stunned = false


func _on_check_if_player_deep_inside_body_entered(body):
	player_is_deep_inside = true


func _on_check_if_player_deep_inside_body_exited(body):
	player_is_deep_inside = false


func _on_move_back_timer_timeout():
	move_back_timer.wait_time = randf_range(1.0, 8.0)
	dir *= -1
	if dir: anim_dir = dir
	
	
func is_alive():
	if state != states.DEAD and state != states.FRUIT_DEAD and hp > 0:
		return true
	return false


func _on_visible_on_screen_notifier_2d_screen_entered():
	visible_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	visible_on_screen = false


func _on_gettin_damage_cd_timeout():
	can_get_damage = true
