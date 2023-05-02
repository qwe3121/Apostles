extends Node2D


var sprites = []


func _ready():
	sprites.append(get_node("Part1Pered"))
	sprites.append(get_node("Part1Zad"))
	sprites.append(get_node("Part2Pered"))
	sprites.append(get_node("Part2Zad"))
	sprites.append(get_node("Part3Pered"))
	sprites.append(get_node("Part3Zad"))
	
	global.cur_level = self
