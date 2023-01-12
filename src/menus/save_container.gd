extends Control


func configurate(file_name: String):
	if !FileAccess.file_exists("user://saves/" + file_name + ".save"):
		print("Can't find the save file " + file_name + ".save while configurating save container")
		return

	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.READ)
	
	var data = file.get_var()
	
	$HBoxContainer/Panel/SaveName.text = file_name
	$HBoxContainer/Panel/TypeName.text = data["save_type"]
	$HBoxContainer/Panel/Date.text = Time.get_datetime_string_from_unix_time(data["unix_time"], true)
	
	if !FileAccess.file_exists("user://screenshots/" + file_name + ".png"):
		print("Can't find the screenshot file " + file_name + ".png while configurating save container")
		return
		
	var image = Image.new()
	var err = image.load("user://screenshots/" + file_name + ".png")
	if err != OK:
		print("Image loading is errored while configurating save container")
		print("Error - " + str(err))
		return
	var texture = ImageTexture.create_from_image(image)
	$HBoxContainer/TextureRect.texture = texture


func _on_overwrite_button_pressed():
	$ConfirmOverwrite/TextEdit.text = $HBoxContainer/Panel/SaveName.text
	$ConfirmOverwrite.popup_centered()
	
	
func _on_delete_button_pressed():
	$ConfirmDelete.dialog_text = "delete save " + $HBoxContainer/Panel/SaveName.text + ".save"
	$ConfirmDelete.popup_centered()


func _on_confirm_delete_confirmed():
	snl.delete_save($HBoxContainer/Panel/SaveName.text)
	events.emit_signal("saves_is_updated")


func _on_confirm_overwrite_confirmed():
	if $ConfirmOverwrite/TextEdit.text == "":
		$FNAlert.dialog_text = "You can't give an empty name to the save file"
		$FNAlert.popup_centered()
		return
		
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

		if ($ConfirmOverwrite/TextEdit.text + ".save") in files and $ConfirmOverwrite/TextEdit.text != $HBoxContainer/Panel/SaveName.text:
			$FNAlert.dialog_text = "save file " + $ConfirmOverwrite/TextEdit.text + ".save is already exists, choose other name"
			$FNAlert.popup_centered()
			return
			
	snl.delete_save($HBoxContainer/Panel/SaveName.text)
	snl.save_game($ConfirmOverwrite/TextEdit.text, "save")
	events.emit_signal("saves_is_updated")


var normal_chars = ['-', '_', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
@onready var previous_text = $ConfirmOverwrite/TextEdit.text
@onready var previous_caret_position = $ConfirmOverwrite/TextEdit.get_caret_column()

func _on_text_edit_text_changed():
	for char in $ConfirmOverwrite/TextEdit.text:
		if char not in normal_chars:
			$ConfirmOverwrite/TextEdit.text = previous_text
			$ConfirmOverwrite/TextEdit.set_caret_column(previous_caret_position, false)
			return
	previous_text = $ConfirmOverwrite/TextEdit.text
	previous_caret_position = $ConfirmOverwrite/TextEdit.get_caret_column()


func _on_fn_alert_confirmed():
	$ConfirmOverwrite/TextEdit.text = $HBoxContainer/Panel/SaveName.text
	$ConfirmOverwrite.popup_centered()
