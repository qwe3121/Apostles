extends Control


func configurate(file_name: String):
	if !FileAccess.file_exists("user://saves/" + file_name + ".save"):
		print("Can't find the save file " + file_name + ".save while configurating load container")
		return

	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.READ)
	
	var data = file.get_var()
	
	$HBoxContainer/Panel/SaveName.text = file_name
	$HBoxContainer/Panel/TypeName.text = data["save_type"]
	$HBoxContainer/Panel/Date.text = Time.get_datetime_string_from_unix_time(data["unix_time"], true)
	
	if !FileAccess.file_exists("user://screenshots/" + file_name + ".png"):
		print("Can't find the screenshot file " + file_name + ".png while configurating load container")
		return
		
	var image = Image.new()
	var err = image.load("user://screenshots/" + file_name + ".png")
	if err != OK:
		print("Image loading is errored while configurating load container")
		print("Error - " + str(err))
		return
	var texture = ImageTexture.create_from_image(image)
	$HBoxContainer/TextureRect.texture = texture


func _on_load_button_pressed():
	$ConfirmLoad.dialog_text = "load save " + $HBoxContainer/Panel/SaveName.text + ".save"
	$ConfirmLoad.popup_centered()


func _on_delete_button_pressed():
	$ConfirmDelete.dialog_text = "delete save " + $HBoxContainer/Panel/SaveName.text + ".save"
	$ConfirmDelete.popup_centered()


func _on_confirm_load_confirmed():
	snl.load_game($HBoxContainer/Panel/SaveName.text)


func _on_confirm_delete_confirmed():
	snl.delete_save($HBoxContainer/Panel/SaveName.text)
	events.emit_signal("saves_is_updated")
