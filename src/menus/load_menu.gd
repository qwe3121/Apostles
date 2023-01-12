extends Control


var load_container_scene = preload("res://src/menus/load_container.tscn")
var control_for_container_bug_fix = preload("res://src/menus/control_for_container_bug_fix.tscn")


func refresh():
	var saves_n_time: Array
		
	for child in $ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
		
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
		
		for file_name in files:
			var file = FileAccess.open("user://saves/" + file_name, FileAccess.READ)
			var save_data = file.get_var()
			var unix_time = save_data["unix_time"]
			saves_n_time.append([file_name, unix_time])
			
		saves_n_time.sort_custom(sort)
		print(saves_n_time)
		
		for save in saves_n_time:
			var file_name = save[0]
			var load_container_instance = load_container_scene.instantiate()
			load_container_instance.configurate(file_name.left(file_name.length() - 5))
			$ScrollContainer/VBoxContainer.add_child(load_container_instance)

		var control_for_container_bug_fix_instance = control_for_container_bug_fix.instantiate()
		$ScrollContainer/VBoxContainer.add_child(control_for_container_bug_fix_instance)
		
		
func sort(a, b):
	if a[1] > b[1]:
		return true
	return false
