extends CharacterBody2D


@onready var trace = $Trace
@onready var drop = $Drop


var flying_apart = true

var x_vel
var y_vel

var rand_modulate

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 5


func configurate():
	rand_modulate = randf_range(0.5, 1.0)
	trace.modulate.a = rand_modulate
	drop.modulate.a = rand_modulate
	drop.texture = load("res://sprites/blood/drops/%d.png" % randi_range(1, 10))
	trace.texture = load("res://sprites/blood/traces/%d.png" % randi_range(1, 5))
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
	trace.visible = true
	drop.visible = false
	$AnimationPlayer.play("fades_out")
	call_deferred("set_process_mode", PROCESS_MODE_DISABLED)
	
	
func delete_blood():
	queue_free()
