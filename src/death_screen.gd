extends Control


func _ready():
	set_process_input(false)


func _input(event):
	if (event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
		get_tree().reload_current_scene()
