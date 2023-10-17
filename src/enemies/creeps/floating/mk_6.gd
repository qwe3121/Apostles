extends CharacterBody2D


var hp = 3
var speed = 150
var y_pos_before_ulti
var knockback_speed = 100

var close_en_to_attack = false

var need_to_slow_player = false
var need_player_to_fly = false

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
@onready var turned_timer = $TurnedTimer
@onready var attack_cooldown = $AttackCooldown
@onready var ulti_cooldown = $UltiCooldown
@onready var blood_pos = $BloodPos
@onready var attack_hitbox = $AttackHitbox/CollisionPolygon2D
@onready var ulti_slow_hitbox = $UltiSlowHitbox/CollisionShape2D
@onready var rocks_dropdown_hitbox = $RocksDropdownHitbox/CollisionShape2D
@onready var ulti_dropdown_hitbox = $UltiDropdownHitbox/CollisionShape2D
@onready var dead_zone = $AnimatedSprite2D/DeadZone
var need_to_check_if_see_player = false

@onready var gettin_damage_CD = $GettinDamageCD

var gravity = 0

enum states {IDLE, RUN, BEFORE_ATTACK, ATTACK, BEFORE_ULTI, ULTI, AFTER_ULTI, DEAD, FRUIT_DEAD, STUNNED, RETURNING_AFTER_STUN}

var state_ins_counter = {
	states.IDLE: 0,
	states.RUN: 0,
	states.BEFORE_ATTACK: 0,
	states.ATTACK: 0,
	states.BEFORE_ULTI: 0,
	states.ULTI: 0,
	states.AFTER_ULTI: 0,
	states.DEAD: 0,
	states.FRUIT_DEAD: 0,
	states.STUNNED: 0,
	states.RETURNING_AFTER_STUN: 0
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
			return "BEFORE_ULTI"
		5: 
			return "ULTI"
		6:
			return "AFTER_ULTI"
		7:
			return "DEAD"
		8:
			return "FRUIT_DEAD"
		9:
			return "STUNNED"
		10:
			return "RETURNING_AFTER_STUN"

var state = states.IDLE : set = set_state

func set_state(value):
	if state == states.STUNNED:
		if value != states.RETURNING_AFTER_STUN and value != states.DEAD and value != states.FRUIT_DEAD:
			return
			
	if state == states.RETURNING_AFTER_STUN:
		if value != states.IDLE and value != states.DEAD and value != states.FRUIT_DEAD and value != states.STUNNED:
			return
	
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
var can_ulti = true

var walking = 1 #1 is walking 0 is chilling

var chasing = false

var there_is_blocked_area = false

var is_on_wall

var turned = false

var flashing = 0
var knockback_dir = 0

var last_knockback_dir = 0

var player_is_deep_inside = false

var can_get_damage = true

var visible_on_screen = false

var unit_is_stunned = false
@onready var stun_duration_timer = $StunDuration


func _ready():
	if len(states) != len(state_ins_counter.keys()):
		assert(false, "state_ins_counter dictionary is not full!")
	
	animated_sprite.material.set_shader_parameter("flash_modifier", 0.0)
	
	y_pos_before_ulti = global_position.y

	blood.modulate.a = randf_range(0.6, 1.0)
	
	
func _on_walking_timer_ready():
	$WalkingTimer.wait_time = randi_range(1,5)
	$WalkingTimer.start()


func get_damage(value, k_dir = 0, damager = null):
	if not can_get_damage and damager == null:
		return
		
	if state == states.DEAD or state == states.FRUIT_DEAD:
		return
	
	hp -= value
	stun()
	knockback_dir = k_dir
	
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
	if see_player or chasing:
		if not unit_is_stunned and is_alive():
			animated_sprite.flip_h = attack_dir == 1
			animated_sprite.position.x = 3 * attack_dir
	else:
		if not unit_is_stunned and is_alive():
			animated_sprite.flip_h = anim_dir == 1
			animated_sprite.position.x = 3 * anim_dir
		
	blood.flip_h = !(last_knockback_dir == 1)
	check_for_blocked_area_col.position.x = 26 * anim_dir
	wall_detector_col.position.x = 20.75 * anim_dir

	match animation_name:
		states.IDLE: 
			if chasing or see_player:
				anim.play("idle_run")
			else:
				anim.play("p_idle_run")
		states.RUN: 
			if chasing or see_player:
				anim.play("idle_run")
			else:
				anim.play("p_idle_run")
		states.BEFORE_ATTACK:
			anim.play("before_attack")
		states.ATTACK:
			anim.play("attack")
		states.BEFORE_ULTI:
			anim.play("before_ulti")
		states.ULTI:
			anim.play("ulti")
		states.AFTER_ULTI:
			anim.play("after_ulti")
		states.DEAD:
			anim.play("dead")
		states.FRUIT_DEAD:
			anim.play("fruit_ninja_dead")
		states.STUNNED:
			anim.play("stun")
		states.RETURNING_AFTER_STUN:
			if chasing or see_player:
				anim.play("idle_run")
			else:
				anim.play("p_idle_run")


func set_dir():
	if player_is_deep_inside: return
	if global_position.x < global.player.global_position.x:
		dir = 1
	else:
		dir = -1
	anim_dir = dir
	
	
func set_attack_dir():
	if player_is_deep_inside: return

	if global_position.x < global.player.global_position.x:
		attack_dir = 1
	else:
		attack_dir = -1


func _physics_process(delta):
	if need_to_check_if_see_player:
		if not check_if_vision_is_blocked_by_wall() and visible_on_screen:
			on_see_player()
		else:
			on_unsee_player()
			
	if see_player:
		set_attack_dir()
		
	if need_player_to_fly:
		global.player.flying_cause_of_mk6 = true
		
	if need_to_slow_player:
		global.player.slowed_cause_of_mk6 = true
	
	
	match state:
		states.IDLE: 
			idle()
		states.RUN: 
			run()
		states.BEFORE_ATTACK:
			before_attack(delta)
		states.ATTACK:
			attack(delta)
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
		states.RETURNING_AFTER_STUN:
			returning_after_stun(delta)
			
	if knockback_dir and not (state == states.DEAD or state == states.FRUIT_DEAD):
		if knockback_dir == dir:
			velocity.x = knockback_speed * 2 * knockback_dir
		else: velocity.x = knockback_speed * knockback_dir
			
	move_and_slide()


func idle():
	if see_player:
		set_dir()
		if can_attack:
			if can_ulti and close_en_to_attack:
				state = states.BEFORE_ULTI
				return
			if can_attack and close_en_to_attack:
				state = states.BEFORE_ATTACK
				return
		if not close_en_to_attack:
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
	if see_player:
		set_dir()
		if can_attack:
			if can_ulti and close_en_to_attack:
				state = states.BEFORE_ULTI
				return
			if can_attack and close_en_to_attack:
				state = states.BEFORE_ATTACK
				return
		if close_en_to_attack:
			dir = 0
			state = states.IDLE
			return
			
	if (is_on_wall or there_is_blocked_area) and not turned and (not see_player and not chasing):
		turned = true
		turned_timer.start()
		dir *= -1
		if dir: anim_dir = dir
	
	if (is_on_wall or there_is_blocked_area) and (see_player or chasing):
		dir = 0
		set_anim(states.IDLE)
	else:
		set_anim(states.RUN)
		
	velocity.y = 0
	velocity.x = dir * speed
	
	
func before_attack(delta):
	velocity.x = 0
	velocity.y = 0
	set_anim(states.BEFORE_ATTACK)
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
	velocity.x = 0
	velocity.y = 0
	set_anim(states.ATTACK)
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.ATTACK]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.ATTACK]:
			return
		if state == states.ATTACK:
			attack_cooldown.start()
			if not chasing:
				walking = 0
				walking_timer_start()
				state = states.IDLE
			else:
				state = states.RUN
			
			
func before_ulti(delta):
	velocity.x = 0
	velocity.y += speed * delta * 8
	set_anim(states.BEFORE_ULTI)
	if !state_started:
		state_started = true
		attack_cooldown.stop()
		can_attack = false
		can_ulti = false
	if is_on_floor():
		if state == states.BEFORE_ULTI:
			state = states.ULTI
	
	
func ulti(delta):
	velocity.x = 0
	velocity.y = 0
	set_anim(states.ULTI)
	if !state_started:
		state_started = true
		var state_ins_number = state_ins_counter[states.ULTI]
		await anim.animation_finished
		if state_ins_number != state_ins_counter[states.ULTI]:
			return
		if state == states.ULTI:
			state = states.AFTER_ULTI
			
			
func after_ulti(delta):
	velocity.x = 0
	velocity.y += -speed * delta * 8
	set_anim(states.AFTER_ULTI)
	if global_position.y - y_pos_before_ulti <= 1:
		if state == states.AFTER_ULTI:
			ulti_cooldown.start()
			attack_cooldown.start()
			velocity.y = 0 # ITS IMPORTANT TO RESET VELOCITY SO MK6 DOES NOT
			#GO TOO HIGH !!!!!!!!!
			global_position.y = y_pos_before_ulti
			if not chasing:
				walking = 0
				walking_timer_start()
				state = states.IDLE
			else:
				state = states.RUN
	
	
func dead(delta):
	velocity.y = 0
	velocity.x = 0
	set_anim(states.DEAD)
	if !state_started:
		state_started = true
		attack_hitbox.disabled = true
		rocks_dropdown_hitbox.disabled = true
		ulti_dropdown_hitbox.disabled = true
		ulti_slow_hitbox.disabled = true
		$CollisionHitbox/CollisionShape2D.disabled = true
		dead_zone.visible = false
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
	if not state == states.BEFORE_ATTACK and not state == states.ATTACK and not state == states.BEFORE_ULTI \
	and not state == states.ULTI and not state == states.AFTER_ULTI and not state == states.STUNNED \
	and not state == states.RETURNING_AFTER_STUN:
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
	
	if not state == states.BEFORE_ATTACK and not state == states.ATTACK and not state == states.BEFORE_ULTI \
	and not state == states.ULTI and not state == states.AFTER_ULTI and not state == states.STUNNED \
	and not state == states.RETURNING_AFTER_STUN:
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
	if not state == states.BEFORE_ATTACK and not state == states.ATTACK and not state == states.BEFORE_ULTI \
	and not state == states.ULTI and not state == states.AFTER_ULTI and not state == states.STUNNED \
	and not state == states.RETURNING_AFTER_STUN:
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
		
		velocity.y = 0
		velocity.x = 0


func _on_wall_detector_body_entered(body):
	is_on_wall = true


func _on_wall_detector_body_exited(body):
	is_on_wall = false
		
		
func kill_with_fruit_ninja():
	chase_timer.stop()
	walking_timer.stop()
	state = states.FRUIT_DEAD
	global.camera.shake()
	
	
func fruit_dead(delta):
	velocity.x = 0
	velocity.y = 0
	set_anim(states.FRUIT_DEAD)
	if !state_started:
		state_started = true
		attack_hitbox.disabled = true
		rocks_dropdown_hitbox.disabled = true
		ulti_dropdown_hitbox.disabled = true
		ulti_slow_hitbox.disabled = true
		$CollisionHitbox/CollisionShape2D.disabled = true
		dead_zone.visible = false
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
			
			
func returning_after_stun(delta):
	velocity.x = 0
	velocity.y += -speed * delta * 8
	set_anim(states.RETURNING_AFTER_STUN)
	if global_position.y - y_pos_before_ulti <= 1:
		if state == states.RETURNING_AFTER_STUN:
			velocity.y = 0 # ITS IMPORTANT TO RESET VELOCITY SO MK6 DOES NOT
			#GO TOO HIGH !!!!!!!!!
			global_position.y = y_pos_before_ulti
			ulti_cooldown.start()
			attack_cooldown.start()
			walking = 0
			walking_timer_start()
			state = states.IDLE
			
			
func stunned(delta):
	set_anim(states.STUNNED)
	velocity.x = 0
	velocity.y = 0
	if !state_started:
		state_started = true
		rocks_dropdown_hitbox.disabled = true
		ulti_dropdown_hitbox.disabled = true
		attack_hitbox.disabled = true
		ulti_slow_hitbox.disabled = true
		dead_zone.visible = false
	if not unit_is_stunned:
		if state == states.STUNNED:
			state = states.RETURNING_AFTER_STUN
			
			
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
			
			
func _on_attack_hitbox_body_entered(body):
	need_player_to_fly = true


func _on_attack_hitbox_body_exited(body):
	need_player_to_fly = false
	global.player.flying_cause_of_mk6 = false
	
	
func shake_camera():
	if dead_zone_visible_on_screen: global.camera.shake()


func _on_ulti_slow_hitbox_body_entered(body):
	need_to_slow_player = true


func _on_ulti_slow_hitbox_body_exited(body):
	need_to_slow_player = false
	global.player.slowed_cause_of_mk6 = false


func _on_check_if_player_deep_inside_body_entered(body):
	player_is_deep_inside = true


func _on_check_if_player_deep_inside_body_exited(body):
	player_is_deep_inside = false
	
	
func is_alive():
	if state != states.DEAD and state != states.FRUIT_DEAD and hp > 0:
		return true
	return false
	
	
var dead_zone_visible_on_screen = false


func _on_dead_zone_visible_on_screen_notifier_screen_entered():
	dead_zone_visible_on_screen = true


func _on_dead_zone_visible_on_screen_notifier_screen_exited():
	dead_zone_visible_on_screen = false


func _on_visible_on_screen_notifier_2d_screen_entered():
	visible_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	visible_on_screen = false


func _on_gettin_damage_cd_timeout():
	can_get_damage = true
