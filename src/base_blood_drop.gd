extends CharacterBody2D


var flying_apart = true

var blocked = false

var x_vel
var y_vel

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	x_vel = randi_range(-480, 480)
	y_vel = randi_range(-800, 800)


func _physics_process(delta):
	if flying_apart:
		velocity.y = y_vel
		velocity.x = x_vel
	
	velocity.y += gravity * delta

	move_and_slide()


func _on_timer_timeout():
	flying_apart = false


func _on_left_col_body_entered(body):
	if not blocked:
		blocked = true
		$Drop.visible = false
		$Left.visible = true
		process_mode = Node.PROCESS_MODE_DISABLED


func _on_right_col_body_entered(body):
	if not blocked:
		blocked = true
		$Drop.visible = false
		$Right.visible = true
		process_mode = Node.PROCESS_MODE_DISABLED


func _on_up_col_body_entered(body):
	if not blocked:
		blocked = true
		$Drop.visible = false
		$Up.visible = true
		process_mode = Node.PROCESS_MODE_DISABLED


func _on_down_col_body_entered(body):
	if not blocked:
		blocked = true
		$Drop.visible = false
		$Down.visible = true
		process_mode = Node.PROCESS_MODE_DISABLED
