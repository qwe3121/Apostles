extends Control


@onready var main_menu = $Main
@onready var settings_menu = $SettingsMenu
@onready var saves_menu = $SavesMenu


@onready var main_menu_focus = $Main/VBoxContainer/PlayButton
@onready var saves_menu_focus = $SavesMenu/BackToMainMenu
@onready var settings_menu_focus = $SettingsMenu/BackToMainMenu


func _process(delta):
	if Input.is_action_just_pressed("ESCAPE") and not main_menu.visible:
		load_main_menu()


func _ready():
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	get_tree().paused = false
	
	process_mode = Node.PROCESS_MODE_INHERIT
	
	global.cur_menu = self
	global.is_in_world = false
	
	$SettingsMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$SavesMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$AnimationPlayer.play("birds_flying")
	main_menu_focus.grab_focus()
	
	
func _on_focus_changed(control):
	if control != null:
		if main_menu.visible:
			main_menu_focus = control
		elif saves_menu.visible:
			saves_menu_focus = control
		elif settings_menu.visible:
			settings_menu_focus = control
	
	
func make_all_menus_invisible():
	main_menu.visible = false
	settings_menu.visible = false
	saves_menu.visible = false
	
	
func load_main_menu():
	make_all_menus_invisible()
	main_menu.visible = true
	main_menu_focus.grab_focus()


func _on_quit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed():
	make_all_menus_invisible()
	settings_menu.visible = true
	settings_menu_focus.grab_focus()
	
	
func _on_play_button_pressed():
	make_all_menus_invisible()
	saves_menu.update()
	saves_menu.visible = true
	saves_menu_focus.grab_focus()
