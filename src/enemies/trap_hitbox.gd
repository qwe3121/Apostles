extends Area2D


@onready var blood_fade_anim = $"../BloodFadeAnim"


func _on_body_entered(body):
	if body.name == "Player":
		body.get_damage("cut")
		if not blood_fade_anim == null:
			if global.player.state != 7 and not cfg.cfg_data.undead:
				blood_fade_anim.play("fade_out")
	else:
		body.get_damage(body.hp, 0, true)
		if not blood_fade_anim == null: blood_fade_anim.play("fade_out")
