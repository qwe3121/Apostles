extends Area2D


@export_enum("attack", "ulti") var attack_type: String = "attack"


func _on_body_entered(body):
	if attack_type == "attack":
		get_parent().close_en_to_attack = true
	elif attack_type == "ulti":
		get_parent().close_en_to_ulti = true


func _on_body_exited(body):
	if attack_type == "attack":
		get_parent().close_en_to_attack = false
	elif attack_type == "ulti":
		get_parent().close_en_to_ulti = false
