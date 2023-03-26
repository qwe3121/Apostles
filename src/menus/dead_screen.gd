extends Control


func _ready():
	get_tree().paused = false


func _on_to_main_menu_button_pressed():
	get_tree().paused = false
	trans.change_scene("res://src/menus/main_menu_oog.tscn")


func _on_load_last_save_button_pressed():
	if cfg.cfg_data.last_save != null:
		snl.load_game(cfg.cfg_data.last_save)
	else:
		nt.add_nt("Cannot find last save")
