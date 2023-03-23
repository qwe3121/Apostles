extends Area2D


@export var can_block: bool = false
@export var speed = 600

var dir = 1 : set = set_dir

func set_dir(value):
	$Sprite2D.flip_h = true if value == 1 else false
	$CollisionShape2D.scale.x = -1 if value == 1 else 1
	dir = value
	

func _physics_process(delta):
	move_local_x(delta * speed * dir)


func _on_timer_timeout():
	queue_free()


func _on_body_entered(body):
	if body.name == "Player":
		if can_block and global.player.blocking:
			queue_free()
			return
		if global.player.state != 25:
			global.player.bullet_knockback = true
			if global.player.anim_dir == 1 and dir == -1 or global.player.anim_dir == -1 and dir == 1:
				global.player.bullet_dead_anim_speredi = true
			else:
				global.player.bullet_dead_anim_speredi = false
			global.player.bullet_knockback_dir = dir
			global.player.get_damage("bullet")
		queue_free()
	else:
		queue_free()
	
