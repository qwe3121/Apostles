extends Control


var current_menu = "none" #none, main, load, save, settings


func _ready():
	$SettingsMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$LoadMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$SaveMenu/BackToMainMenu.pressed.connect(load_main_menu)
	events.saves_is_updated.connect(saves_is_updated)


func _process(delta):
	if Input.is_action_just_pressed("QUICK SAVE") and current_menu == "none":
		snl.make_screenshot()
		snl.quicksave()
	
	if Input.is_action_just_pressed("ESCAPE"):
		if current_menu == "none":
			snl.make_screenshot()
			$ColorRect.visible = true
			load_main_menu()
		elif current_menu == "main":
			hide_menu()
		elif current_menu == "load":
			load_main_menu()
		elif current_menu == "save":
			load_main_menu()
		elif current_menu == "settings":
			load_main_menu()
			
			
func make_all_menus_invisible():
	$Main.visible = false
	$LoadMenu.visible = false
	$SaveMenu.visible = false
	$SettingsMenu.visible = false
	

func saves_is_updated():
	$LoadMenu.refresh()
	$SaveMenu.refresh()
	
	
func load_save_menu():
	make_all_menus_invisible()
	$SaveMenu.refresh()
	$SaveMenu.visible = true
	current_menu = "save"


func load_main_menu():
	get_tree().paused = true
	make_all_menus_invisible()
	$Main.visible = true
	current_menu = "main"
	
	
func hide_menu():
	get_tree().paused = false
	$ColorRect.visible = false
	make_all_menus_invisible()
	current_menu = "none"
	
	
func load_load_menu():
	make_all_menus_invisible()
	$LoadMenu.refresh()
	$LoadMenu.visible = true
	current_menu = "load"
	

func _on_load_button_pressed():
	load_load_menu()


func _on_resume_button_pressed():
	hide_menu()


func _on_quit_tmm_button_pressed():
	get_tree().paused = false
	trans.change_scene("res://src/menus/main_menu_oog.tscn")
	

func _on_quit_oog_button_pressed():
	get_tree().quit()


func _on_save_button_pressed():
	load_save_menu()


func _on_autosave_timer_timeout():
		snl.make_screenshot()
		snl.save_game("autosave", "autosave")
		print("autosaved")


func _on_settings_button_pressed():
	load_settings_menu()
	
	
func load_settings_menu():
	make_all_menus_invisible()
	$SettingsMenu.visible = true
	current_menu = "settings"
