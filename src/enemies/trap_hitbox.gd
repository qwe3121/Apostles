extends Area2D


func _on_body_entered(body):
	if body.name == "Player":
		body.get_damage(false)
	else:
		body.get_damage(body.hp)
