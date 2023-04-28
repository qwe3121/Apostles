extends Area2D


@onready var blood_fade_anim = $"../BloodFadeAnim"


func _on_body_entered(body):
#	if body.name == "Player":
#		body.get_damage("cut")
#		if not blood_fade_anim == null:
#			if global.player.state != 7 and not cfg.cfg_data.undead:
#				if not blood_fade_anim.current_animation == "fade_out":
#					blood_fade_anim.play("fade_out")
#	else:
	body.get_damage(body.hp, 0, true)
	if not blood_fade_anim == null: 
		if not blood_fade_anim.current_animation == "fade_out":
			blood_fade_anim.play("fade_out")


func _on_area_entered(area):
	if area.get_parent().name == "Player":
		area.get_parent().get_damage("cut")
		if not blood_fade_anim == null:
			if global.player.state != 7 and not cfg.cfg_data.undead:
				if not blood_fade_anim.current_animation == "fade_out":
					blood_fade_anim.play("fade_out")
	else:
		if not blood_fade_anim == null:
			if not blood_fade_anim.current_animation == "fade_out":
				blood_fade_anim.play("fade_out")
