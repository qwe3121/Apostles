extends Node


var screenshot


func save_screenshot(file_name: String):
	if !DirAccess.dir_exists_absolute("user://screenshots"):
		DirAccess.make_dir_absolute("user://screenshots")
	screenshot.save_png("user://screenshots/" + file_name + ".png")
	
	
func make_screenshot():
	screenshot = get_viewport().get_texture().get_image()


func save_game(file_name: String):
	if !DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_absolute("user://saves")
		
	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.WRITE)
	
	var data = {}
	
	var unix_time = Time.get_unix_time_from_system()
	unix_time += Time.get_time_zone_from_system()["bias"] * 60
	data["unix_time"] = unix_time
	
	#take data from global variables here
		
	file.store_var(data)
	
	save_screenshot(file_name)
	
	
func load_game(file_name: String):
	if !FileAccess.file_exists("user://saves/" + file_name + ".save"):
		print("There is no save file " + file_name + ".save")
		return
		
	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.READ)
	
	var data = file.get_var()
	
	trans.change_scene(data["world"])
	await events.scene_is_loaded
	
	#load data to global variables here
	
	
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


func new_game_save(file_name: String):
	if !DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_absolute("user://saves")
		
	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.WRITE)
	
	var data = {}
	
	var unix_time = Time.get_unix_time_from_system()
	unix_time += Time.get_time_zone_from_system()["bias"] * 60
	data["unix_time"] = unix_time
	
	#take data from global variables here
		
	file.store_var(data)
	
	save_screenshot(file_name)
