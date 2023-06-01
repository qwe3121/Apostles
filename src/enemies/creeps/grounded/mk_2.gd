extends CharacterBody2D


var hp = 4000
var speed = 75

var close_en_to_attack = false

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
@onready var qmark = $Qmark
@onready var ulti_hitbox = $UltiHitbox/Col
@onready var attack_hitbox = $AttackHitbox/Col
@onready var move_back_timer = $MoveBackTimer
var need_to_check_if_see_player = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum {IDLE, RUN, BEFORE_ATTACK, ATTACK, AFTER_ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, AIR, FRUIT_DEAD, MOVE_BACK, BEFORE_ATTACK_N_RUN, BEFORE_ATTACK_N_MOVE_BACK, \
ATTACK_N_RUN, ATTACK_N_MOVE_BACK, AFTER_ATTACK_N_MOVE_BACK, AFTER_ATTACK_N_RUN, BEFORE_ULTI_N_RUN, BEFORE_ULTI_N_MOVE_BACK, ULTI_N_RUN, ULTI_N_MOVE_BACK, AFTER_ULTI_N_RUN, \
AFTER_ULTI_N_MOVE_BACK}

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
			return "FRUID_DEAD"

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
var need_to_choose_dir_to_move_back = false
var player_is_deep_inside = false
var player_move_state
enum move_state_const {IDLE, RUN, MOVE_BACK}

func _ready():
	animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)
	animated_sprite.material.set_shader_parameter("alpha", 1.0)

	blood.modulate.a = randf_range(0.6, 1.0)

	walking_timer.wait_time = randi_range(1,5)
	walking_timer.autostart = true
	

func get_damage(value, k_dir = 0, damager = null):
	if state == DEAD or state == FRUIT_DEAD:
		return
	
	hp -= value
	knockback_dir = k_dir
	
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
	if damager == null: global.camera.shake()
		
func set_anim(animation_name):
	if animation_name == MOVE_BACK or animation_name == ATTACK_N_MOVE_BACK \
	or animation_name == BEFORE_ATTACK_N_MOVE_BACK or animation_name == AFTER_ATTACK_N_MOVE_BACK \
	or animation_name == BEFORE_ULTI_N_MOVE_BACK or animation_name == ULTI_N_MOVE_BACK \
	or animation_name == AFTER_ULTI_N_MOVE_BACK:
		if move_back_timer.is_stopped():
			move_back_timer.start()
		animated_sprite.flip_h = anim_dir == -1
		attack_hitbox.position.x = -32 * anim_dir
		ulti_hitbox.position.x = -49 * anim_dir
	else:
		if not move_back_timer.is_stopped():
			move_back_timer.stop()
		animated_sprite.flip_h = anim_dir == 1
		attack_hitbox.position.x = 32 * anim_dir
		ulti_hitbox.position.x = 49 * anim_dir
		
	blood.flip_h = !(last_knockback_dir == 1)
	blood.position.x = 30 * last_knockback_dir
	check_for_pit.position.x = 24.75 * anim_dir
	check_for_blocked_area_col.position.x = 31 * anim_dir
	wall_detector_col.position.x = 18.25 * anim_dir

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
			if anim.current_animation == "before_attack_n_run" \
			or anim.current_animation == "before_attack_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("before_attack")
				anim.seek(cur_pos)
			else:
				anim.play("before_attack")
		BEFORE_ATTACK_N_MOVE_BACK:
			if anim.current_animation == "before_attack" or \
			anim.current_animation == "before_attack_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("before_attack_n_move_back")
				anim.seek(cur_pos)
			else:
				anim.play("before_attack_n_move_back")
		BEFORE_ATTACK_N_RUN:
			if anim.current_animation == "before_attack" or \
			anim.current_animation == "before_attack_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("before_attack_n_run")
				anim.seek(cur_pos)
			else:
				anim.play("before_attack_n_run")
		ATTACK:
			if anim.current_animation == "attack_n_run" \
			or anim.current_animation == "attack_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("attack")
				anim.seek(cur_pos)
			else:
				anim.play("attack")
		ATTACK_N_RUN:
			if anim.current_animation == "attack" \
			or anim.current_animation == "attack_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("attack_n_run")
				anim.seek(cur_pos)
			else:
				anim.play("attack_n_run")
		ATTACK_N_MOVE_BACK:
			if anim.current_animation == "attack" \
			or anim.current_animation == "attack_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("attack_n_move_back")
				anim.seek(cur_pos)
			else:
				anim.play("attack_n_move_back")
		AFTER_ATTACK:
			if anim.current_animation == "after_attack_n_run" \
			or anim.current_animation == "after_attack_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("after_attack")
				anim.seek(cur_pos)
			else:
				anim.play("after_attack")
		AFTER_ATTACK_N_RUN:
			if anim.current_animation == "after_attack_n_move_back" \
			or anim.current_animation == "after_attack":
				var cur_pos = anim.current_animation_position
				anim.play("after_attack_n_run")
				anim.seek(cur_pos)
			else:
				anim.play("after_attack_n_run")
		AFTER_ATTACK_N_MOVE_BACK:
			if anim.current_animation == "after_attack_n_run" \
			or anim.current_animation == "after_attack":
				var cur_pos = anim.current_animation_position
				anim.play("after_attack_n_move_back")
				anim.seek(cur_pos)
			else:
				anim.play("after_attack_n_move_back")
		BEFORE_ULTI:
			if anim.current_animation == "before_ulti_n_run" \
			or anim.current_animation == "before_ulti_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("before_ulti")
				anim.seek(cur_pos)
			else:
				anim.play("before_ulti")
		BEFORE_ULTI_N_RUN:
			if anim.current_animation == "before_ulti" \
			or anim.current_animation == "before_ulti_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("before_ulti_n_run")
				anim.seek(cur_pos)
			else:
				anim.play("before_ulti_n_run")
		BEFORE_ULTI_N_MOVE_BACK:
			if anim.current_animation == "before_ulti_n_run" \
			or anim.current_animation == "before_ulti":
				var cur_pos = anim.current_animation_position
				anim.play("before_ulti_n_move_back")
				anim.seek(cur_pos)
			else:
				anim.play("before_ulti_n_move_back")
		ULTI:
			if anim.current_animation == "ulti_n_run" \
			or anim.current_animation == "ulti_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("ulti")
				anim.seek(cur_pos)
			else:
				anim.play("ulti")
		ULTI_N_RUN:
			if anim.current_animation == "ulti_n_move_back" \
			or anim.current_animation == "ulti":
				var cur_pos = anim.current_animation_position
				anim.play("ulti_n_run")
				anim.seek(cur_pos)
			else:
				anim.play("ulti_n_run")
		ULTI_N_MOVE_BACK:
			if anim.current_animation == "ulti_n_run" \
			or anim.current_animation == "ulti":
				var cur_pos = anim.current_animation_position
				anim.play("ulti_n_move_back")
				anim.seek(cur_pos)
			else:
				anim.play("ulti_n_move_back")
		AFTER_ULTI:
			if anim.current_animation == "after_ulti_n_run" \
			or anim.current_animation == "after_ulti_n_move_back":
				var cur_pos = anim.current_animation_position
				anim.play("after_ulti")
				anim.seek(cur_pos)
			else:
				anim.play("after_ulti")
		AFTER_ULTI_N_RUN:
			if anim.current_animation == "after_ulti_n_move_back" \
			or anim.current_animation == "after_ulti":
				var cur_pos = anim.current_animation_position
				anim.play("after_ulti_n_run")
				anim.seek(cur_pos)
			else:
				anim.play("after_ulti_n_run")
		AFTER_ULTI_N_MOVE_BACK:
			if anim.current_animation == "after_ulti" \
			or anim.current_animation == "after_ulti_n_run":
				var cur_pos = anim.current_animation_position
				anim.play("after_ulti_n_move_back")
				anim.seek(cur_pos)
			else:
				anim.play("after_ulti_n_move_back")
		DEAD:
			anim.play("dead")
		FRUIT_DEAD:
			anim.play("fruit_ninja_dead")
		MOVE_BACK:
			anim.play("move_back")
			
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


func _physics_process(delta):
	if need_to_check_if_see_player:
		if not check_if_vision_is_blocked_by_wall():
			on_see_player()

	match state:
		IDLE: 
			idle()
		RUN: 
			run()
		AIR:
			air(delta)
		BEFORE_ATTACK:
			before_attack(delta)
		ATTACK:
			attack(delta)
		AFTER_ATTACK:
			after_attack(delta)
		BEFORE_ULTI:
			before_ulti(delta)
		ULTI:
			ulti(delta)
		AFTER_ULTI:
			after_ulti(delta)
		DEAD:
			dead(delta)
		FRUIT_DEAD:
			fruit_dead(delta)
			
	if knockback_dir and not (state == DEAD or state == FRUIT_DEAD):
		if knockback_dir == dir:
			velocity.x = speed * 2 * knockback_dir
		else: velocity.x = speed * knockback_dir
			
	move_and_slide()


func idle():
	if not is_on_floor():
		state = AIR
		return
		
	if player_is_inside:
		state = RUN
		return
	
	if see_player:
		set_dir()
		if close_en_to_attack and can_attack:
			if can_ulti:
				state = BEFORE_ULTI
				return
			if can_attack:
				state = BEFORE_ATTACK
				return
		elif not close_en_to_attack:
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
	velocity.x = 0
			
			
func run():
	if not is_on_floor():
		state = AIR
		return
		
	if player_is_inside:
		if need_to_choose_dir_to_move_back:
			need_to_choose_dir_to_move_back = false
			set_dir_to_move_back(false)
	else:
		if see_player:
			set_dir()
			if close_en_to_attack and can_attack:
				if can_ulti:
					state = BEFORE_ULTI
					return
				if can_attack:
					state = BEFORE_ATTACK
					return
			elif close_en_to_attack:
				state = IDLE
				return
			
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and ((not see_player and not chasing) or player_is_inside):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and (see_player or chasing) and not player_is_inside:
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		player_move_state = move_state_const.RUN
	else:
		player_move_state = move_state_const.MOVE_BACK
		
	match player_move_state:
		move_state_const.IDLE:
			set_anim(IDLE)
		move_state_const.RUN:
			set_anim(RUN)
		move_state_const.MOVE_BACK:
			set_anim(MOVE_BACK)
		
	velocity.y = 0
	velocity.x = dir * speed
	
	
func air(delta):
	if is_on_floor():
		state = IDLE
		return
		
	set_anim(AIR)
	
	velocity.y += gravity * delta
	velocity.x = 0
	
	
func before_attack(delta):
	if player_is_inside:
		if need_to_choose_dir_to_move_back:
			need_to_choose_dir_to_move_back = false
			set_dir_to_move_back(false)
	else:
		if see_player:
			set_dir()
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and ((not see_player and not chasing) or player_is_inside):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or close_en_to_attack) and (see_player or chasing) and not player_is_inside:
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		player_move_state = move_state_const.RUN
	else:
		player_move_state = move_state_const.MOVE_BACK
		
	match player_move_state:
		move_state_const.IDLE:
			set_anim(BEFORE_ATTACK)
		move_state_const.RUN:
			set_anim(BEFORE_ATTACK_N_RUN)
		move_state_const.MOVE_BACK:
			set_anim(BEFORE_ATTACK_N_MOVE_BACK)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		can_ulti = false
		can_attack = false
#		need_to_reset_ulti = true
		await anim.animation_finished
		if state == BEFORE_ATTACK:
			state = ATTACK
	
	
func attack(delta):
	if player_is_inside:
		if need_to_choose_dir_to_move_back:
			need_to_choose_dir_to_move_back = false
			set_dir_to_move_back(false)
	else:
		if see_player:
			set_dir()
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and ((not see_player and not chasing) or player_is_inside):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or close_en_to_attack) and (see_player or chasing) and not player_is_inside:
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		player_move_state = move_state_const.RUN
	else:
		player_move_state = move_state_const.MOVE_BACK
		
	match player_move_state:
		move_state_const.IDLE:
			set_anim(ATTACK)
		move_state_const.RUN:
			set_anim(ATTACK_N_RUN)
		move_state_const.MOVE_BACK:
			set_anim(ATTACK_N_MOVE_BACK)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ATTACK:
			state = AFTER_ATTACK
			
			
func after_attack(delta):
	if player_is_inside:
		if need_to_choose_dir_to_move_back:
			need_to_choose_dir_to_move_back = false
			set_dir_to_move_back(false)
	else:
		if see_player:
			set_dir()
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and ((not see_player and not chasing) or player_is_inside):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or close_en_to_attack) and (see_player or chasing) and not player_is_inside:
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		player_move_state = move_state_const.RUN
	else:
		player_move_state = move_state_const.MOVE_BACK
		
	match player_move_state:
		move_state_const.IDLE:
			set_anim(AFTER_ATTACK)
		move_state_const.RUN:
			set_anim(AFTER_ATTACK_N_RUN)
		move_state_const.MOVE_BACK:
			set_anim(AFTER_ATTACK_N_MOVE_BACK)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == AFTER_ATTACK:
			attack_cooldown.start()
			if not see_player:
				chasing = false
				walking = 0
				walking_timer_start()
			state = IDLE
			
			
func before_ulti(delta):
	if player_is_inside:
		if need_to_choose_dir_to_move_back:
			need_to_choose_dir_to_move_back = false
			set_dir_to_move_back(false)
	else:
		if see_player:
			set_dir()
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and ((not see_player and not chasing) or player_is_inside):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or close_en_to_attack) and (see_player or chasing) and not player_is_inside:
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		player_move_state = move_state_const.RUN
	else:
		player_move_state = move_state_const.MOVE_BACK
		
	match player_move_state:
		move_state_const.IDLE:
			set_anim(BEFORE_ULTI)
		move_state_const.RUN:
			set_anim(BEFORE_ULTI_N_RUN)
		move_state_const.MOVE_BACK:
			set_anim(BEFORE_ULTI_N_MOVE_BACK)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		attack_cooldown.stop()
		can_attack = false
		can_ulti = false
		await anim.animation_finished
		if state == BEFORE_ULTI:
			state = ULTI
	
	
func ulti(delta):
	if player_is_inside:
		if need_to_choose_dir_to_move_back:
			need_to_choose_dir_to_move_back = false
			set_dir_to_move_back(false)
	else:
		if see_player:
			set_dir()
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and ((not see_player and not chasing) or player_is_inside):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or close_en_to_attack) and (see_player or chasing) and not player_is_inside:
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		player_move_state = move_state_const.RUN
	else:
		player_move_state = move_state_const.MOVE_BACK
		
	match player_move_state:
		move_state_const.IDLE:
			set_anim(ULTI)
		move_state_const.RUN:
			set_anim(ULTI_N_RUN)
		move_state_const.MOVE_BACK:
			set_anim(ULTI_N_MOVE_BACK)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == ULTI:
			state = AFTER_ULTI
			
			
func after_ulti(delta):
	if player_is_inside:
		if need_to_choose_dir_to_move_back:
			need_to_choose_dir_to_move_back = false
			set_dir_to_move_back(false)
	else:
		if see_player:
			set_dir()
				
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area) and not turned and ((not see_player and not chasing) or player_is_inside):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or not check_for_pit.is_colliding() or there_is_blocked_area or close_en_to_attack) and (see_player or chasing) and not player_is_inside:
		dir = 0
		player_move_state = move_state_const.IDLE
	elif not player_is_inside:
		player_move_state = move_state_const.RUN
	else:
		player_move_state = move_state_const.MOVE_BACK
		
	match player_move_state:
		move_state_const.IDLE:
			set_anim(AFTER_ULTI)
		move_state_const.RUN:
			set_anim(AFTER_ULTI_N_RUN)
		move_state_const.MOVE_BACK:
			set_anim(AFTER_ULTI_N_MOVE_BACK)
	
	velocity.x = dir * speed
	if not is_on_floor(): velocity.y += gravity * delta
	
	if !state_started:
		state_started = true
		await anim.animation_finished
		if state == AFTER_ULTI:
#			ulti_cooldown.start()
			attack_cooldown.start()
			if not see_player:
				chasing = false
				walking = 0
				walking_timer_start()
			state = IDLE
	
	
func dead(delta):
	set_anim(DEAD)
	velocity.x = 0
	if not is_on_floor(): velocity.y += gravity * delta
	if !state_started:
		state_started = true
		ulti_hitbox.disabled = true
		attack_hitbox.disabled = true
		for c in range(b_drops):
			blood_manager.create_blood(last_knockback_dir, blood_pos)
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
	need_to_check_if_see_player = true


func on_see_player():
	need_to_check_if_see_player = false
	if not chasing and can_attack:
		qmark.visible = true
		qmark.play("popup")
	walking_timer.stop()
	chase_timer.stop()
	see_player = true


func _on_eyes_body_exited(body):
	if state == DEAD or state == FRUIT_DEAD:
		return
	need_to_check_if_see_player = false
	if not see_player:
		return
	see_player = false
	if not state == BEFORE_ATTACK and not state == ATTACK and not state == AFTER_ATTACK and not state == BEFORE_ULTI and not state == ULTI and not state == AFTER_ULTI:
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
		
		if not is_on_floor():
			velocity.y = 0
			velocity.x= 0


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
	state = FRUIT_DEAD
	global.camera.shake()
	
	
func fruit_dead(delta):
	set_anim(FRUIT_DEAD)
	velocity.x = 0
	if not is_on_floor(): velocity.y += gravity * delta
	if !state_started:
		state_started = true
		ulti_hitbox.disabled = true
		attack_hitbox.disabled = true
		last_knockback_dir = 1 if global_position > global.player.global_position else -1
		for c in range(b_drops):
			blood_manager.create_blood(last_knockback_dir, blood_pos)
		await anim.animation_finished
		if state == FRUIT_DEAD:
			events.emit_signal("fruit_kill")
			queue_free()


func _on_check_if_player_deep_inside_body_entered(body):
	player_is_deep_inside = true


func _on_check_if_player_deep_inside_body_exited(body):
	player_is_deep_inside = false


func _on_move_back_timer_timeout():
	dir *= -1
	if dir: anim_dir = dir
