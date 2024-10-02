extends Area2D


@export var look_into_player_for_damage: bool = false
@export var damage: int = 1
@export var hit_once: bool = false


var targets_dictionary = {}


func _process(delta):
	if len(targets_dictionary.keys()) > 0:
		for target in targets_dictionary.keys():
			if targets_dictionary[target] and hit_once: 
				return
			if look_into_player_for_damage:
				damage = global.player.current_attack_damage
			if global.player.global_position.x > target.global_position.x:
				target.get_damage(damage, -1, null)
			else:
				target.get_damage(damage, 1, null)
			targets_dictionary[target] = true


func _on_body_entered(body):
	targets_dictionary[body] = false


func _on_body_exited(body):
	targets_dictionary.erase(body)
