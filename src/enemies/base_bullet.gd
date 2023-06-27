extends Area2D


@export var can_block: bool = false
@export var speed: int = 600

@export var damage: int = 1

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
	var k_dir
	
	if body.name == "Player":
		if global_position.x > global.player.global_position.x:
			k_dir = -1
			if global.player.anim_dir == 1:
				global.player.bullet_dead_anim_speredi = true
			else:
				global.player.bullet_dead_anim_speredi = false
		else:
			k_dir = 1
			if global.player.anim_dir == 1:
				global.player.bullet_dead_anim_speredi = false
			else:
				global.player.bullet_dead_anim_speredi = true
		global.player.get_damage("bullet", damage, can_block, k_dir, false, null)
		queue_free()
	else:
		particles_manager.create_hit_particles(global_position + Vector2(20 * dir, 0), -dir)
		queue_free()
