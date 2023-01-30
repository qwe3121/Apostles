extends Control


var color = Color.WHITE


@onready var x_size = size.x
@onready var y_size = size.y


func _draw():
	for _i in range(10):
		var center = Vector2(randi_range(0, x_size), randi_range(0, y_size))
		var radius = randi_range(2, 40)
		draw_circle(center, radius, color)
