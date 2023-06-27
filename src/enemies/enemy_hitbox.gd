extends Area2D


@export var can_block: bool = false
@export_enum("hit", "fire", "bullet", "cut") var damage_source: String = "hit"
@export var damage: int = 1
@export var respect_col_pos: bool = false #if respect then rename collision node to "Col" and check this


var see_player = false

var attacking_entity


func _ready():
	if respect_col_pos:
		attacking_entity = $Col
	else:
		attacking_entity = get_parent()


func _process(delta):
	if see_player:
		if attacking_entity.global_position.x > global.player.global_position.x:
			global.player.get_damage(damage_source, damage, can_block, -1, true, null)
		else:
			global.player.get_damage(damage_source, damage, can_block, 1, true, null)


func _on_body_entered(body):
	see_player = true


func _on_body_exited(body):
	see_player = false
