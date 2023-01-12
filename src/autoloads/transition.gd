extends CanvasLayer


func change_scene(target: String):
	events.emit_signal("scene_is_about_to_be_changed")
	if cfg.cfg_data.glitchy_transition_on:
		$AnimationPlayer.play("fade_in")
		await $AnimationPlayer.animation_finished
		var scene = load(target)
		$VideoStreamPlayer.play()
		await $VideoStreamPlayer.finished
		get_tree().change_scene_to_packed(scene)
		$AnimationPlayer.play("fade_out")
	else:
		$AnimationPlayer.play("fade_in")
		await $AnimationPlayer.animation_finished
		var scene = load(target)
		get_tree().change_scene_to_packed(scene)
		$AnimationPlayer.play("fade_out")
