extends Node2D


@onready var skylight_sub_viewport_camera = $SkylightViewportContainer/SkylightSubViewport/Camera2D
@onready var player_camera = $Player/Camera2D


func _ready():
	get_tree().paused = false
	Engine.time_scale = cfg.default_time_scale
	$BackgroundParallax/SkylightTexture.texture = $SkylightViewportContainer/SkylightSubViewport.get_texture()


func _physics_process(delta):
	skylight_sub_viewport_camera.position = player_camera.global_position
	skylight_sub_viewport_camera.offset = player_camera.offset


func _on_timer_timeout():
	dialog.start("res://src/dialogues/timelines/test.dtl")
