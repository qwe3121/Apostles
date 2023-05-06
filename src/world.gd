extends Node2D


@onready var viewport_camera = $SubViewport/Camera2D
@onready var player_camera = $Player/Camera2D


func _ready():	
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().get_root().size_changed.connect(_on_size_changed)
	_on_size_changed()
	$Parallax/Sprite2D.texture = $SubViewport.get_texture()


func _on_size_changed():
	var viewport_size = get_viewport_rect().size
	$SubViewport/Parallax/ColorRect.size = viewport_size
	$SubViewport.size = viewport_size


func _physics_process(delta):
	viewport_camera.position = player_camera.global_position
	viewport_camera.offset = player_camera.offset
