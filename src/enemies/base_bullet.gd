extends Area2D


@export var can_block: bool = false
@export var speed = 600

var dir = 1


func _ready():
	if can_block:
		set_collision_mask_value(7, not global.player.blocking)
		events.player_blocking.connect(_on_player_blocking)
		
		
func _on_player_blocking():
	set_collision_mask_value(7, not global.player.blocking)
	
	
func _physics_process(delta):
	move_local_x(delta * speed * dir)


func _on_timer_timeout():
	queue_free()


func _on_body_entered(body):
	queue_free()


func _on_area_entered(area):
	global.player.get_damage()
	queue_free()
