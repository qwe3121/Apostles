extends Area2D


@export_enum("attack", "ulti") var attack_type: String = "attack"
@export var prefire: bool = false
@export var fake: bool = false


func _on_body_entered(body):
	if fake:
		if attack_type == "attack":
			get_parent().fake_close_en_to_attack = true
		elif attack_type == "ulti":
			get_parent().fake_close_en_to_ulti = true
	elif prefire:
		if attack_type == "attack":
			get_parent().close_en_to_prefire_attack = true
		elif attack_type == "ulti":
			get_parent().close_en_to_prefire_ulti = true
	else:
		if attack_type == "attack":
			get_parent().close_en_to_attack = true
		elif attack_type == "ulti":
			get_parent().close_en_to_ulti = true


func _on_body_exited(body):
	if fake:
		if attack_type == "attack":
			get_parent().fake_close_en_to_attack = false
		elif attack_type == "ulti":
			get_parent().fake_close_en_to_ulti = false
	elif prefire:
		if attack_type == "attack":
			get_parent().close_en_to_prefire_attack = false
		elif attack_type == "ulti":
			get_parent().close_en_to_prefire_ulti = false
	else:
		if attack_type == "attack":
			get_parent().close_en_to_attack = false
		elif attack_type == "ulti":
			get_parent().close_en_to_ulti = false
