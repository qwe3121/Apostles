extends CharacterBody2D


var flying_apart = true

var x_vel
var y_vel

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 5


func _ready():
	$Drop.texture = load("res://sprites/blood/drops/Kapla_Krovi_%d.png" % randi_range(1, 11))
	$Trace.texture = load("res://sprites/blood/traces/Kryg_Krovi_%d.png" % randi_range(1, 5))
	y_vel = randi_range(-800, 800)


func _physics_process(delta):
	if flying_apart:
		velocity.y = y_vel
		velocity.x = x_vel
	
	velocity.y += gravity * delta

	move_and_slide()


func _on_timer_timeout():
	flying_apart = false


func _on_area_2d_body_entered(body):
	$Trace.visible = true
	$Drop.visible = false
	$AnimationPlayer.play("fades_out")
	process_mode = PROCESS_MODE_DISABLED
	
	
func delete_blood():
	queue_free()
