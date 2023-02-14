extends Node2D


@onready var clouds = $Parallax/Clouds


func _physics_process(delta):
	clouds.motion_offset.x += 5 * delta


func save_world():
	return "res://src/world.tscn"
