extends CharacterBody2D


var flying_apart = true

var x_vel
var y_vel

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	x_vel = randi_range(-480, 480)
	y_vel = randi_range(-200, 200)


func _physics_process(delta):
	if flying_apart:
		velocity.y = y_vel
		velocity.x = x_vel
	
	velocity.y += gravity * delta

	move_and_slide()


func _on_area_2d_body_entered(body):
	set_process(false)
	set_physics_process(false)


func _on_timer_timeout():
	flying_apart = false
