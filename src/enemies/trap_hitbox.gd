extends Area2D


func _on_body_entered(body):
	if body.name == "Player":
		body.get_damage("cut")
	else:
		body.get_damage(body.hp, 0, true)
