extends Node2D


var rand=RandomNumberGenerator.new()


var preloaded_rooms = {
	1: preload("res://src/generation/rooms/1.tscn"),
	2: preload("res://src/generation/rooms/2.tscn"),
	3: preload("res://src/generation/rooms/3.tscn"),
	4: preload("res://src/generation/rooms/4.tscn"),
	5: preload("res://src/generation/rooms/5.tscn")
}

@export var x_count: int = 2
@export var y_count: int = 2

@export var x_size: int = 1152
@export var y_size: int = 648

var current_direction = 1
var x: int
var y: int

var left = []
var up = []
var right = []
var down = []


func _ready():
	rand.randomize()
	$Left.position = Vector2(-x_size/2, y_size/2)
	$Up.position = Vector2(x_size/2, -y_size/2)
	$Right.position = Vector2(x_size*1.5, y_size/2)
	$Down.position = Vector2(x_size/2, y_size*1.5)
	x = x_count
	y = y_count
	spawn_room()


func intersect(array1, array2):
	if array1 == []:
		return array2
	elif array2 == []:
		return array1
	var intersection = []
	for item in array1:
		if array2.has(item):
			intersection.append(item)
	return intersection


func spawn_room():
	var intersection = intersect(left, up)
	intersection = intersect(intersection, right)
	intersection = intersect(intersection, down)
	
	var room_number
	if intersection == []:
		room_number = rand.randi_range(1, len(preloaded_rooms))
	else:
		room_number = intersection[rand.randi_range(0, len(intersection) - 1)]
		
	var room_ins = preloaded_rooms[room_number].instantiate()
	room_ins.global_position = global_position
	get_tree().get_root().get_node("GenerationTest").add_child.call_deferred(room_ins)
	x -= 1
	if x == 0:
		y -= 1
		if y > 0:
			current_direction *= -1
			x = x_count
			move_down()
			spawn_room()
		else:
			queue_free()
	else:
		next_pos()
		spawn_room()
	

func move_down():
	global_position.y += y_size


func next_pos():
	global_position.x += x_size * current_direction


func _on_left_area_entered(area):
	left = area.get_parent().rooms


func _on_left_area_exited(area):
	left = []


func _on_up_area_entered(area):
	up = area.get_parent().rooms


func _on_up_area_exited(area):
	up = []


func _on_right_area_entered(area):
	right = area.get_parent().rooms


func _on_right_area_exited(area):
	right = []


func _on_down_area_entered(area):
	down = area.get_parent().rooms


func _on_down_area_exited(area):
	down = []
