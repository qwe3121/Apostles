extends Node


func update_display_mode(index):
	if index == 0:
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED and not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED and not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			cfg.cfg_data.display_mode = index
			cfg.save_data()
	elif index == 1:
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			cfg.cfg_data.display_mode = index
			cfg.save_data()
	elif index == 2:
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			cfg.cfg_data.display_mode = index
			cfg.save_data()
			

func toggle_vsync(value):
	if not DisplayServer.window_get_vsync_mode() == (DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
		cfg.cfg_data.vsync_on = value
		cfg.save_data()


func update_master_vol(vol):
	if not AudioServer.get_bus_volume_db(0) == vol:
		AudioServer.set_bus_volume_db(0, vol)
		cfg.cfg_data.master_vol = vol
		cfg.save_data()


func update_music_vol(vol):
	if not AudioServer.get_bus_volume_db(1) == vol:
		AudioServer.set_bus_volume_db(1, vol)
		cfg.cfg_data.music_vol = vol
		cfg.save_data()
	
	
func update_sfx_vol(vol):
	if not AudioServer.get_bus_volume_db(2) == vol:
		AudioServer.set_bus_volume_db(2, vol)
		cfg.cfg_data.sfx_vol = vol
		cfg.save_data()
		
	
func toggle_transition_mode(value):
	if not cfg.cfg_data.glitchy_transition_on == value:
		cfg.cfg_data.glitchy_transition_on = value
		cfg.save_data()
		
		
func toggle_undead_mode(value):
	if not cfg.cfg_data.undead == value:
		cfg.cfg_data.undead = value
		cfg.save_data()
