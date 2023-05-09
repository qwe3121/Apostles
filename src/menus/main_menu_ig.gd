extends Control


var current_menu = "none" #none, main, saves, settings

@onready var color_rect = $ColorRect
@onready var main_menu = $Main
@onready var saves_menu = $SavesMenu
@onready var settings_menu = $SettingsMenu

@onready var main_menu_focus = $Main/VBoxContainer/ResumeButton
@onready var saves_menu_focus = $SavesMenu/BackToMainMenu
@onready var settings_menu_focus = $SettingsMenu/BackToMainMenu


func _ready():
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	global.cur_menu = self
	
	$SettingsMenu/BackToMainMenu.pressed.connect(load_main_menu)
	$SavesMenu/BackToMainMenu.pressed.connect(load_main_menu)
	
	
func _on_focus_changed(control):
	if control != null:
		match current_menu:
			"main":
				main_menu_focus = control
			"saves":
				saves_menu_focus = control
			"settings":
				settings_menu_focus = control


func _process(delta):
	if Input.is_action_just_pressed("ESCAPE") and not dialog.dialog_is_showed and not global.player.death_screen.visible:
		if current_menu == "none":
			global.player.ui.visible = false
			color_rect.visible = true
			load_main_menu()
		elif current_menu == "main":
			hide_menu()
		else:
			load_main_menu()
			
			
func make_all_menus_invisible():
	main_menu.visible = false
	saves_menu.visible = false
	settings_menu.visible = false


func load_main_menu():
	get_tree().paused = true
	make_all_menus_invisible()
	main_menu.visible = true
	current_menu = "main"
	main_menu_focus.grab_focus()
	
	
func hide_menu():
	if not global.player.death_screen.visible and not dialog.dialog_is_showed: get_tree().paused = false
	color_rect.visible = false
	global.player.ui.visible = true
	make_all_menus_invisible()
	current_menu = "none"
	

func _on_resume_button_pressed():
	hide_menu()


func _on_quit_tmm_button_pressed():
	trans.change_scene("res://src/menus/main_menu_oog.tscn")
	

func _on_quit_oog_button_pressed():
	get_tree().quit()
	

func _on_settings_button_pressed():
	make_all_menus_invisible()
	settings_menu.visible = true
	current_menu = "settings"
	settings_menu_focus.grab_focus()


func _on_saves_button_pressed():
	make_all_menus_invisible()
	saves_menu.update()
	saves_menu.visible = true
	current_menu = "saves"
	saves_menu_focus.grab_focus()
