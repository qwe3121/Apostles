extends Area2D


@export var can_block: bool = false
@export_enum("hit", "fire", "bullet", "cut") var damage_source: String = "hit"
@export var damage: int = 1


var see_player = false

@onready var col = $Col


func _process(delta):
	if see_player:
		if col.global_position.x > global.player.global_position.x:
			global.player.get_damage(damage_source, damage, can_block, null, -1)
		else:
			global.player.get_damage(damage_source, damage, can_block, null, 1)



func _on_body_entered(body):
	see_player = true


func _on_body_exited(body):
	see_player = false
