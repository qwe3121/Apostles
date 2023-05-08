extends Control


@onready var main_menu = $Main
@onready var settings_menu = $SettingsMenu
@onready var saves_menu = $SavesMenu


func _process(delta):
	if Input.is_action_just_pressed("ESCAPE") and not main_menu.visible:
		load_main_menu()


func _ready():
	get_tree().paused = false
	
	process_mode = Node.PROCESS_MODE_INHERIT
	
	global.cur_menu = self
	
	$SettingsMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$SavesMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$AnimationPlayer.play("birds_flying")
	$Main/VBoxContainer/PlayButton.grab_focus()
	
	
func make_all_menus_invisible():
	main_menu.visible = false
	settings_menu.visible = false
	saves_menu.visible = false
	
	
func load_main_menu():
	make_all_menus_invisible()
	main_menu.visible = true
	$Main/VBoxContainer/PlayButton.grab_focus()


func _on_quit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed():
	make_all_menus_invisible()
	settings_menu.visible = true
	$SettingsMenu/BackToMainMenu.grab_focus()
	
	
func _on_play_button_pressed():
	make_all_menus_invisible()
	saves_menu.update()
	saves_menu.visible = true
	$SavesMenu/BackToMainMenu.grab_focus()
