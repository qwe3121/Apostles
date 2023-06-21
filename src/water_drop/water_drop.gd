extends CharacterBody2D


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	elif not $AnimatedSprite2D.is_playing():
		$Sprite2D.visible = false
		$AnimatedSprite2D.visible = true
		$AnimatedSprite2D.play("water_drop")

	move_and_slide()


func _on_animated_sprite_2d_animation_finished():
	queue_free()
