extends Area2D


@onready var blood_fade_anim = get_node_or_null("../BloodFadeAnim")


var targets_array = []


func _process(delta):
	if len(targets_array) > 0:
		for target in targets_array:
			if target.name == "Player":
				target.get_damage("cut", target.hp, false, self)
			else:
				target.get_damage(target.hp, 0, self)


func _on_body_entered(body):
	targets_array.append(body)


func _on_body_exited(body):
	targets_array.erase(body)


func _on_area_entered(area):
	turn_into_bloody_version()


func turn_into_bloody_version():
	if not blood_fade_anim == null:
		if not blood_fade_anim.current_animation == "fade_out":
			blood_fade_anim.play("fade_out")
