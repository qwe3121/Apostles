extends Node


var hit_particles = preload("res://src/hit_particles.tscn")
var sword_particles = preload("res://src/sword_particles.tscn")   

@onready var sword_particles_cd = $SwordParticlesCD
var can_create_sword_particles = true


func create_hit_particles(pos, dir):
	return
	var hit_particles_ins = hit_particles.instantiate()
	global.cur_level.add_child(hit_particles_ins)
	hit_particles_ins.process_material.direction.x = dir
	hit_particles_ins.global_position = pos
	hit_particles_ins.emitting = true


func create_sword_particles(pos):
	return
	if not can_create_sword_particles: return
	var sword_particles_ins = sword_particles.instantiate()
	global.cur_level.add_child(sword_particles_ins)
	sword_particles_ins.global_position = pos
	sword_particles_ins.emitting = true
	can_create_sword_particles = false
	sword_particles_cd.start()
	
	
func _on_sword_particles_cd_timeout():
	can_create_sword_particles = true
