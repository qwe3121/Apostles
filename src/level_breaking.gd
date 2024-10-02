extends Area2D


func _on_body_entered(body: Node2D) -> void:
	global.player.get_damage("cut", global.player.hp, false, 0, false, self)
