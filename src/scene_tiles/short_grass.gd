extends Sprite2D


var blooded = false


func _ready():
	$Node2D.modulate.a = randf_range(0.6, 1)


func _on_area_2d_area_entered(area):
	if not blooded:
		blooded = true
		$Node2D/Blood.modulate.a = 1
		$AnimationPlayer.play("anim")


func _on_animation_player_animation_finished(anim_name):
	blooded = false
