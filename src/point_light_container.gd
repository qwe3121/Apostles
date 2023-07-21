extends Node2D


@export var moving: bool = false
@export var speed_scale = 0.5 #only matters if moving checked


func _ready():
	if moving:
		$AnimationPlayer.speed_scale = speed_scale
		$AnimationPlayer.play("moving")
