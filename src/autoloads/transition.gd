extends CanvasLayer


@onready var vid = $VideoStreamPlayer
@onready var anim = $AnimationPlayer


func change_scene(target: String):
	global.cur_menu.process_mode = Node.PROCESS_MODE_DISABLED
	
	events.emit_signal("scene_is_about_to_be_changed")
	if cfg.cfg_data.glitchy_transition_on:
		anim.play("fade_in")
		await anim.animation_finished
		var scene = load(target)
		vid.play()
		await vid.finished
		get_tree().change_scene_to_packed(scene)
		anim.play("fade_out")
	else:
		anim.play("fade_in")
		await anim.animation_finished
		var scene = load(target)
		get_tree().change_scene_to_packed(scene)
		anim.play("fade_out")
