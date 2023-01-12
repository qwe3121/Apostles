extends Node2D


func _physics_process(delta):
	$Parallax/Clouds.motion_offset.x += 5 * delta


func save_world():
	return "res://src/world.tscn"
