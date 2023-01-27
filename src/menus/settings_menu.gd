extends Control


func _ready():
	$TabContainer/Video/MarginContainer/VBoxContainer/DisplayModeContainer/DisplayModeOptionButton.select(cfg.cfg_data.display_mode)
	global_settings.update_display_mode(cfg.cfg_data.display_mode)
	$TabContainer/Video/MarginContainer/VBoxContainer/VsyncContainer/VsyncCheckButton.button_pressed = cfg.cfg_data.vsync_on
	global_settings.toggle_vsync($TabContainer/Video/MarginContainer/VBoxContainer/VsyncContainer/VsyncCheckButton.button_pressed)
	$TabContainer/Audio/MarginContainer/VBoxContainer/MasterVolumeContainer/MasterVolumeHSlider.value = cfg.cfg_data.master_vol
	$TabContainer/Audio/MarginContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeHSlider.value = cfg.cfg_data.music_vol
	$TabContainer/Audio/MarginContainer/VBoxContainer/SFXVolumeContainer/SFXVolumeHSlider.value = cfg.cfg_data.sfx_vol
	$TabContainer/Game/MarginContainer/VBoxContainer/TransitionModeContainer/TransitionModeOptionButton.select(0 if cfg.cfg_data.glitchy_transition_on else 1)
	global_settings.toggle_transition_mode(cfg.cfg_data.glitchy_transition_on)
	update_action_event("QUICK SAVE")
	update_action_event("ROLL")
	update_action_event("DASH")
	update_action_event("RMB ATTACK")
	update_action_event("RIGHT")
	update_action_event("LEFT")
	update_action_event("DOWN")
	update_action_event("JUMP")
	update_action_event("LMB ATTACK")
	update_action_event("BLOCK")
	events.emit_signal("ready_to_load_keys_containers")
	
	
func update_action_event(action: String, defaults = false):
	var data
	
	if defaults:
		data = cfg.default_keys
	else:
		data = cfg.cfg_data
		
	var event = null
	var action_array = data[action]
	if action_array[1] == "InputEventKey":
		event = InputEventKey.new()
		event.keycode = action_array[0]
	elif action_array[1] == "InputEventMouseButton":
		event = InputEventMouseButton.new()
		event.button_index = action_array[0]
	
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	if defaults:
		if event is InputEventMouseButton:
			cfg.cfg_data[action] = [event.button_index, "InputEventMouseButton"]
		elif event is InputEventKey:
			cfg.cfg_data[action] = [event.keycode, "InputEventKey"]
			
		# also need to add joystick support
		
		cfg.save_data()


func _on_display_mode_option_button_item_selected(index):
	global_settings.update_display_mode(index)


func _on_vsync_check_button_toggled(button_pressed):
	global_settings.toggle_vsync(button_pressed)
	

func _on_master_volume_h_slider_value_changed(value):
	global_settings.update_master_vol(value)


func _on_music_volume_h_slider_value_changed(value):
	global_settings.update_music_vol(value)


func _on_sfx_volume_h_slider_value_changed(value):
	global_settings.update_sfx_vol(value)


func _on_transition_mode_option_button_item_selected(index):
	global_settings.toggle_transition_mode(true if index == 0 else false)


func _on_back_to_defaults_pressed():
	match $TabContainer.current_tab:
		0: #video
			$TabContainer/Video/MarginContainer/VBoxContainer/DisplayModeContainer/DisplayModeOptionButton.select(2)
			global_settings.update_display_mode(2)
			$TabContainer/Video/MarginContainer/VBoxContainer/VsyncContainer/VsyncCheckButton.button_pressed = true
			global_settings.toggle_vsync(true)
		1: #audio
			$TabContainer/Audio/MarginContainer/VBoxContainer/MasterVolumeContainer/MasterVolumeHSlider.value = -10
			$TabContainer/Audio/MarginContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeHSlider.value = -10
			$TabContainer/Audio/MarginContainer/VBoxContainer/SFXVolumeContainer/SFXVolumeHSlider.value = -10
		2: #game
			$TabContainer/Game/MarginContainer/VBoxContainer/TransitionModeContainer/TransitionModeOptionButton.select(0)
			global_settings.toggle_transition_mode(true)
		3: #actions
			update_action_event("QUICK SAVE", true)
			update_action_event("ROLL", true)
			update_action_event("DASH", true)
			update_action_event("RMB ATTACK", true)
			update_action_event("RIGHT", true)
			update_action_event("LEFT", true)
			update_action_event("DOWN", true)
			update_action_event("JUMP", true)
			update_action_event("LMB ATTACK", true)
			update_action_event("BLOCK", true)
			events.emit_signal("ready_to_load_keys_containers")
