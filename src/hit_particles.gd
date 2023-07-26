extends GPUParticles2D


func _physics_process(delta):
	if not emitting:
		await get_tree().create_timer(2).timeout
		queue_free()
