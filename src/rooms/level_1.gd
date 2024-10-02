extends Node2D


@onready var level_breaking: Area2D = $LevelBreaking


func _physics_process(delta: float) -> void:
	level_breaking.position.x += 10 * delta

var sprites = []


func _ready():
	sprites.append(get_node("CoreVisuals/Part1Pered"))
	sprites.append(get_node("CoreVisuals/Part1Zad"))
	sprites.append(get_node("CoreVisuals/Part2Pered"))
	sprites.append(get_node("CoreVisuals/Part2Zad"))
	sprites.append(get_node("CoreVisuals/Part3Pered"))
	sprites.append(get_node("CoreVisuals/Part3Zad"))
	
	global.cur_level = self
