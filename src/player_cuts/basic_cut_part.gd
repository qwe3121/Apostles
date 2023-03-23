extends CharacterBody2D


var flying_apart = true

var x_vel
var y_vel

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 5


func _ready():
	y_vel = randi_range(-800, -200)
	x_vel = randi_range(-800, 800)


func _physics_process(delta):
	if is_on_floor():
		velocity.y = 0
		velocity.x = 0
	else:
		if flying_apart:
			velocity.y = y_vel
			velocity.x = x_vel

		velocity.y += gravity * delta
		velocity.y = clamp(velocity.y, -1000, 1000)

	move_and_slide()


func _on_timer_timeout():
	flying_apart = false
