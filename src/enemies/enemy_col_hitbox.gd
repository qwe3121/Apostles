extends Area2D


var see_player = false

@onready var col = $Col


func _process(delta):
	if see_player:
		if col.global_position.x > global.player.global_position.x:
			global.player.get_col_damage("fire", 1, -1)
		else:
			global.player.get_col_damage("fire", 1, 1)


func _on_body_entered(body):
	see_player = true


func _on_body_exited(body):
	see_player = false
