extends Control


@onready var main_menu = $Main
@onready var load_menu = $LoadMenu
@onready var settings_menu = $SettingsMenu


func _ready():
	$SettingsMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$LoadMenu/BackToMainMenu.pressed.connect(load_main_menu)
	events.saves_is_updated.connect(saves_is_updated)
	$AnimationPlayer.play("birds_flying")
	
	
func make_all_menus_invisible():
	main_menu.visible = false
	load_menu.visible = false
	settings_menu.visible = false


func saves_is_updated():
	load_menu.refresh()


func _on_new_game_button_pressed():
	trans.change_scene("res://src/world.tscn")


func _on_load_button_pressed():
	load_load_menu()
	
	
func load_load_menu():
	make_all_menus_invisible()
	load_menu.refresh()
	load_menu.visible = true
	
	
func load_main_menu():
	make_all_menus_invisible()
	main_menu.visible = true


func _on_quit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed():
	make_all_menus_invisible()
	settings_menu.visible = true


func _on_continue_button_pressed():
	if cfg.cfg_data.last_save != null:
		snl.load_game(cfg.cfg_data.last_save)
	else:
		nt.add_nt("Cannot find last save")
