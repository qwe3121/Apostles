extends Area2D


@export var can_block: bool = false
@export_enum("hit", "fire", "bullet", "cut") var damage_source: String = "hit"


var see_player = false


func _process(delta):
	if see_player:
		global.player.get_damage(damage_source, can_block)


func _on_body_entered(body):
	see_player = true


func _on_body_exited(body):
	see_player = false
