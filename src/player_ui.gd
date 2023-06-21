extends Control


@onready var dash_icon_anim = $DashIcon/DashIconAnim


func _on_dash_icon_anim_animation_finished(anim_name):
	if anim_name == "using":
		dash_icon_anim.play("charging")
	elif anim_name == "charging":
		global.player.can_dash = true
