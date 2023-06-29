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
	cfg.cfg_data.glitchy_transition_on = value
	cfg.save_data()
		
		
func toggle_undead_mode(value):
	cfg.cfg_data.undead = value
	cfg.save_data()
		
		
func toggle_skylight(value):
	var world = get_parent().get_node_or_null("World")
	if world != null:
		var result = world.get_node_or_null("SkylightViewportContainer")
		if result != null:
			result.visible = value
		result = world.get_node_or_null("BackgroundParallax/SkylightTexture")
		if result != null:
			result.visible = value
	cfg.cfg_data.skylight_on = value
	cfg.save_data()
	
	
func toggle_glow(value):
	pass
#	var main_node = get_parent().get_node_or_null("World")
#	if main_node == null:
#		main_node = get_parent().get_node_or_null("MainMenuOOG")
#	if main_node != null:
#		var world_env = main_node.get_node_or_null("WorldEnvironment")
#		if world_env != null:
#			world_env.environment.glow_enabled = value
#	cfg.cfg_data.glow_on = value
#	cfg.save_data()
	
	
func toggle_show_fps(value):
	var main_node = get_parent().get_node_or_null("World")
	if main_node == null:
		main_node = get_parent().get_node_or_null("MainMenuOOG")
	if main_node != null:
		var fps_label = main_node.get_node_or_null("TechInfoCanvasLayer/TechInfo/fpsLabel")
		if fps_label != null:
			fps_label.visible = value
	cfg.cfg_data.show_fps_on = value
	cfg.save_data()
	
	
func toggle_blood_traces(value):
	cfg.cfg_data.blood_traces_on = value
	cfg.save_data()
	
	
func toggle_lens_flare(value):
	var player_node = get_parent().get_node_or_null("World/Player")
	if player_node != null:
		var lens_flare_node = player_node.get_node("CanvasLayer/LensFlare")
		if lens_flare_node != null:
			lens_flare_node.visible = value
	cfg.cfg_data.sun_lens_on = value
	cfg.save_data()
