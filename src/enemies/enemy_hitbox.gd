extends Area2D


@export var can_block: bool = false
@export var damage_source: String = "hit"


func _ready():
	if can_block:
		set_collision_mask_value(7, not global.player.blocking)
		events.player_blocking.connect(_on_player_blocking)
		
		
func _on_player_blocking():
	set_collision_mask_value(7, not global.player.blocking)


func _on_area_entered(area):
	global.player.get_damage(damage_source)
