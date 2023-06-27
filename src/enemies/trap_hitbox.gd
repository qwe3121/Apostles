extends Area2D


var targets_array = []


func _process(delta):
	if len(targets_array) > 0:
		for target in targets_array:
			if target.name == "Player":
				target.get_damage("cut", target.hp, false, 0, false, self)
			else:
				target.get_damage(target.hp, 0, self)


func _on_body_entered(body):
	targets_array.append(body)


func _on_body_exited(body):
	targets_array.erase(body)


func turn_into_bloody_version():
	if get_parent() is Path2D:
		get_parent().modulate = Color("677007")
