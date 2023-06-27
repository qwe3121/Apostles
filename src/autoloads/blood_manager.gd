extends Node


var blood_drop = preload("res://src/blood_drop.tscn")
var blood_trace = preload("res://src/blood_trace.tscn")


func create_blood_drops(last_knockback_dir, blood_pos):
	if not cfg.cfg_data.blood_traces_on: return
	
	var blood_drop_instance = blood_drop.instantiate()
	global.cur_level.add_child(blood_drop_instance)
	blood_drop_instance.configurate()
	if last_knockback_dir == 0:
		blood_drop_instance.x_vel = randi_range(-800, 800)
	else:
		blood_drop_instance.x_vel = randi_range(-800, -500) if last_knockback_dir == -1 else randi_range(500, 800)
	blood_drop_instance.global_position = blood_pos.global_position


func create_blood_traces(pos):
	if not cfg.cfg_data.blood_traces_on: return
	
	var level_sprites = global.cur_level.sprites

	var blood_trace_instance = blood_trace.instantiate()
	level_sprites[0].add_child(blood_trace_instance)
	
#	blood_trace_instance.modulate.a = randf_range(0.5, 1.0)
	blood_trace_instance.texture = load("res://sprites/blood/traces/%d.png" % randi_range(1, 5))
	
	blood_trace_instance.global_position = pos

#	var modulate_a = blood_trace_instance.modulate.a
	var texture = blood_trace_instance.texture

	for i in len(level_sprites):
		if i == 0:
			continue

		var blood_trace_ins = blood_trace.instantiate()

		level_sprites[i].add_child(blood_trace_ins)

#		blood_trace_ins.modulate.a = modulate_a
		blood_trace_ins.texture = texture
		blood_trace_ins.global_position = pos
