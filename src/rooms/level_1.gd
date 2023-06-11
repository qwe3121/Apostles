extends Node2D


var sprites = []


func _ready():
	sprites.append(get_node("Visuals/Part1Pered"))
	sprites.append(get_node("Visuals/Part1Zad"))
	sprites.append(get_node("Visuals/Part2Pered"))
	sprites.append(get_node("Visuals/Part2Zad"))
	sprites.append(get_node("Visuals/Part3Pered"))
	sprites.append(get_node("Visuals/Part3Zad"))
	
	global.cur_level = self
