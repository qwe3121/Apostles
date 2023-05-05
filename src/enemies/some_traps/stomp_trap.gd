extends Node2D


@export var time_before_start: float = 0
@export var stomp_cooldown: float = 5


var visible_on_screen: bool = false


func _ready():
	if not stomp_cooldown == 0:
		$StompCooldown.wait_time = stomp_cooldown
	if time_before_start == 0:
		$AnimationPlayer.play("default")
	else:
		$TimeBeforeStart.wait_time = time_before_start
		$TimeBeforeStart.start()
	
	
func _on_time_before_start_timeout():
	$AnimationPlayer.play("default")


func _on_animation_player_animation_finished(_anim_name):
	if stomp_cooldown == 0:
		$AnimationPlayer.play("default")
	else: $StompCooldown.start()


func _on_stomp_cooldown_timeout():
	$AnimationPlayer.play("default")


func _on_visible_on_screen_notifier_2d_screen_entered():
	visible_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	visible_on_screen = false
	
	
func shake_screen():
	if visible_on_screen: global.camera.shake(6)
