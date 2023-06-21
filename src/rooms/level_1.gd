extends Node2D


var sprites = []


func _ready():
	sprites.append(get_node("CoreVisuals/Part1Pered"))
	sprites.append(get_node("CoreVisuals/Part1Zad"))
	sprites.append(get_node("CoreVisuals/Part2Pered"))
	sprites.append(get_node("CoreVisuals/Part2Zad"))
	sprites.append(get_node("CoreVisuals/Part3Pered"))
	sprites.append(get_node("CoreVisuals/Part3Zad"))
	
	global.cur_level = self
