extends Area2D


var targets_array = []


func _process(delta):
	if len(targets_array) > 0:
		for target in targets_array:
			if target.name == "HurtboxForTraps":
				global.player.get_damage("cut", global.player.hp, false, 0, false, self)
			else:
				target.get_damage(target.hp, 0, self)


func _on_body_entered(body):
	targets_array.append(body)


func _on_body_exited(body):
	targets_array.erase(body)


func turn_into_bloody_version():
	if get_parent() is Path2D:
		get_parent().modulate = Color("510000")


func _on_area_entered(area):
	if area.name == "HurtboxForTraps": 
		targets_array.append(area)
		return
	turn_into_bloody_version()


func _on_area_exited(area):
	if area.name == "HurtboxForTraps": 
		targets_array.erase(area)
