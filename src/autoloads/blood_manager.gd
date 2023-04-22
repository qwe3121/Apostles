extends Node


var blood_drop = preload("res://src/blood_drop.tscn")


func create_blood(sprite_of_level_background, sprite_of_level_foreground, last_knockback_dir, blood_pos):
	var blood_drop_instance = blood_drop.instantiate()
	sprite_of_level_background.add_child(blood_drop_instance)
	blood_drop_instance.configurate()
	
	if last_knockback_dir == 0:
		blood_drop_instance.x_vel = randi_range(-800, 800)
	else:
		blood_drop_instance.x_vel = randi_range(-800, -500) if last_knockback_dir == -1 else randi_range(500, 800)
	
	blood_drop_instance.global_position = blood_pos.global_position
	
	var blood_drop_instance_2 = blood_drop.instantiate()
	sprite_of_level_foreground.add_child(blood_drop_instance_2)
	blood_drop_instance_2.trace.modulate.a = blood_drop_instance.trace.modulate.a
	blood_drop_instance_2.drop.modulate.a = blood_drop_instance.drop.modulate.a
	blood_drop_instance_2.drop.texture = blood_drop_instance.drop.texture
	blood_drop_instance_2.trace.texture = blood_drop_instance.trace.texture
	blood_drop_instance_2.y_vel = blood_drop_instance.y_vel
	
	blood_drop_instance_2.x_vel = blood_drop_instance.x_vel
	blood_drop_instance_2.global_position = blood_drop_instance.global_position
