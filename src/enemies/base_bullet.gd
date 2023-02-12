extends Area2D


@export var can_block: bool = false
@export var speed = 600

var dir = 1


func _physics_process(delta):
	move_local_x(delta * speed * dir)


func _on_timer_timeout():
	queue_free()


func _on_body_entered(body):
	if body.name == "Player":
		if can_block and global.player.blocking:
			queue_free()
			return
		global.player.get_damage()
	else:
		queue_free()
	
