extends Control


func _ready():
	$SettingsMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$LoadMenu/BackToMainMenu.pressed.connect(load_main_menu)
	events.saves_is_updated.connect(saves_is_updated)
	$AnimationPlayer.play("birds_flying")
	
	
func make_all_menus_invisible():
	$Main.visible = false
	$LoadMenu.visible = false
	$SettingsMenu.visible = false


func saves_is_updated():
	$LoadMenu.refresh()


func _on_new_game_button_pressed():
	trans.change_scene("res://src/world.tscn")


func _on_load_button_pressed():
	load_load_menu()
	
	
func load_load_menu():
	make_all_menus_invisible()
	$LoadMenu.refresh()
	$LoadMenu.visible = true
	
	
func load_main_menu():
	make_all_menus_invisible()
	$Main.visible = true


func _on_quit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed():
	make_all_menus_invisible()
	$SettingsMenu.visible = true


func _on_continue_button_pressed():
	if cfg.cfg_data.last_save != null:
		snl.load_game(cfg.cfg_data.last_save)
	else:
		nt.add_nt("Cannot find last save")
