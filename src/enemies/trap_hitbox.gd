extends Area2D


@onready var blood_fade_anim = $"../BloodFadeAnim"


func _on_body_entered(body):
	if body.name == "Player":
		body.get_damage("cut")
		if global.player.state != 7:
			blood_fade_anim.play("fade_out")
	else:
		body.get_damage(body.hp, 0, true)
		blood_fade_anim.play("fade_out")
