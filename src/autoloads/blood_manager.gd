extends Node


var blood_drop = preload("res://src/blood_drop.tscn")


func create_blood(last_knockback_dir, blood_pos):
	if not cfg.cfg_data.blood_traces_on: return
	
	var level_sprites = global.cur_level.sprites

	var blood_drop_instance = blood_drop.instantiate()
	level_sprites[0].add_child(blood_drop_instance)
	blood_drop_instance.configurate()
	if last_knockback_dir == 0:
		blood_drop_instance.x_vel = randi_range(-800, 800)
	else:
		blood_drop_instance.x_vel = randi_range(-800, -500) if last_knockback_dir == -1 else randi_range(500, 800)
	blood_drop_instance.global_position = blood_pos.global_position

	var trace_modulate_a = blood_drop_instance.trace.modulate.a
	var drop_modulate_a = blood_drop_instance.drop.modulate.a
	var drop_texture = blood_drop_instance.drop.texture
	var trace_texture = blood_drop_instance.trace.texture
	var y_vel = blood_drop_instance.y_vel
	var x_vel = blood_drop_instance.x_vel
	var ins_global_pos = blood_drop_instance.global_position

	for i in len(level_sprites):
		if i == 0:
			continue

		var blood_drop_ins = blood_drop.instantiate()

		level_sprites[i].add_child(blood_drop_ins)

		blood_drop_ins.trace.modulate.a = trace_modulate_a
		blood_drop_ins.drop.modulate.a = drop_modulate_a
		blood_drop_ins.drop.texture = drop_texture
		blood_drop_ins.trace.texture = trace_texture
		blood_drop_ins.y_vel = y_vel
		blood_drop_ins.x_vel = x_vel
		blood_drop_ins.global_position = ins_global_pos
