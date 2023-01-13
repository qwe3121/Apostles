extends Node


var screenshot


func save_screenshot(file_name: String):
	if !DirAccess.dir_exists_absolute("user://screenshots"):
		DirAccess.make_dir_absolute("user://screenshots")
	screenshot.save_png("user://screenshots/" + file_name + ".png")
	
	
func make_screenshot():
	screenshot = get_viewport().get_texture().get_image()


#save_types - quicksave, autosave, save
func save_game(file_name: String, save_type: String):
	if !DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_absolute("user://saves")
		
	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.WRITE)
	
	var data = {}
	data["save_type"] = save_type
	var unix_time = Time.get_unix_time_from_system()
	unix_time += Time.get_time_zone_from_system()["bias"] * 60
	data["unix_time"] = unix_time
	
	var snl_nodes = get_tree().get_nodes_in_group("snl")
	for node in snl_nodes:
		if !node.has_method("save_data"):
			print(str(node.name) + " is missing a save_data() function... skipped")
			continue
			
		data[node.name] = node.call("save_data")
		
	var snl_world = get_tree().get_nodes_in_group("snl_world")
	for world in snl_world:
		if !world.has_method("save_world"):
			print(str(world.name) + " is missing a save_world() function... skipped")
			continue
			
		data["world"] = world.call("save_world")
		
	file.store_var(data)
	
	save_screenshot(file_name)
	
	cfg.cfg_data.last_save = file_name
	cfg.save_data()
	

func quicksave():
	var index = 1
	while true:
		if !FileAccess.file_exists("user://saves/quicksave-" + str(index) + ".save"):
			save_game("quicksave-" + str(index), "quicksave")
			break
		index += 1
	
	
func load_game(file_name: String):
	if !FileAccess.file_exists("user://saves/" + file_name + ".save"):
		print("There is no save file " + file_name + ".save")
		return
		
	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.READ)
	
	var data = file.get_var()
	
	trans.change_scene(data["world"])
	await events.scene_is_loaded
	
	var snl_nodes = get_tree().get_nodes_in_group("snl")
	for node in snl_nodes:
		if !node.has_method("load_data"):
			print(str(node.name) + " is missing a load_data() function... skipped")
			continue
			
		node.call("load_data", data[node.name])
		
	print("Loaded data from " + file_name + ".save - " + data)
	
	
func delete_save(file_name: String):
	if !FileAccess.file_exists("user://saves/" + file_name + ".save"):
		print("There is no save file " + file_name + ".save")
		return
		
	var err = DirAccess.remove_absolute("user://saves/" + file_name + ".save")
	if err != OK:
		print("Error deleting save file " + file_name + ".save")
		print("Error - " + str(err))
		
	if !FileAccess.file_exists("user://screenshots/" + file_name + ".png"):
		print("There is no save screenshot " + file_name + ".png")
		return
		
	var err2 = DirAccess.remove_absolute("user://screenshots/" + file_name + ".png")
	if err2 != OK:
		print("Error deleting save screenshot " + file_name + ".png")
		print("Error - " + str(err2))
		
	if file_name == cfg.cfg_data.last_save:
		var saves_n_time: Array
			
		if DirAccess.dir_exists_absolute("user://saves"):
			var files = []
			var dir = DirAccess.open("user://saves")
			dir.list_dir_begin()

			while true:
				var file = dir.get_next()
				if file == "":
					break
				elif not file.begins_with("."):
					files.append(file)

			dir.list_dir_end()
			
			if len(files) == 0:
				cfg.cfg_data.last_save = null
				cfg.save_data()
				return
			
			for file_namee in files:
				var file = FileAccess.open("user://saves/" + file_namee, FileAccess.READ)
				var save_data = file.get_var()
				var unix_time = save_data["unix_time"]
				saves_n_time.append([file_namee, unix_time])
				
			saves_n_time.sort_custom(sort)
			
			var save_name = saves_n_time[0][0]
			save_name = save_name.left(save_name.length() - 5)
			
			cfg.cfg_data.last_save = save_name
			cfg.save_data()
		
		
func sort(a, b):
	return a[1] > b[1]
		
