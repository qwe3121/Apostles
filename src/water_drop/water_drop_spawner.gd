extends Node2D


@export var cooldown: int = 5
var water_drop = preload("res://src/water_drop/water_drop.tscn")


func _ready():
	$Timer.wait_time = cooldown
	$Timer.start()


func _on_timer_timeout():
	var water_drop_ins = water_drop.instantiate()
	get_parent().add_child(water_drop_ins)
	water_drop_ins.global_position = global_position
