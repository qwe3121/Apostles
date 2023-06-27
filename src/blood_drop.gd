extends CharacterBody2D


@onready var drop = $Drop


var flying_apart = true

var x_vel
var y_vel

#var rand_modulate

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 5


func configurate():
#	rand_modulate = randf_range(0.5, 1.0)
#	drop.modulate.a = rand_modulate
	drop.texture = load("res://sprites/blood/drops/%d.png" % randi_range(1, 10))
	y_vel = randi_range(-800, 800)


func _physics_process(delta):
	if flying_apart:
		velocity.y = y_vel
		velocity.x = x_vel
	
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, -1000, 1000)

	move_and_slide()


func _on_timer_timeout():
	flying_apart = false


func _on_area_2d_body_entered(body):
	blood_manager.create_blood_traces(global_position)
	queue_free()
