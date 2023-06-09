extends Node2D


@onready var viewport_camera = $SubViewport/Camera2D
@onready var player_camera = $Player/Camera2D


func _ready():	
	get_tree().paused = false
	Engine.time_scale = cfg.default_time_scale
	$Parallax/Sprite2D.texture = $SubViewport.get_texture()


func _physics_process(delta):
	viewport_camera.position = player_camera.global_position
	viewport_camera.offset = player_camera.offset


func _on_timer_timeout():
	dialog.start("res://src/dialogues/timelines/test.dtl")
