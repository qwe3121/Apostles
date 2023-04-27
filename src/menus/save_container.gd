extends Control


@onready var save_name = $HBoxContainer/Panel/SaveName
@onready var type_name = $HBoxContainer/Panel/TypeName
@onready var date = $HBoxContainer/Panel/Date
@onready var confirm_overwrite = $ConfirmOverwrite
@onready var text_edit = $ConfirmOverwrite/TextEdit
@onready var confirm_delete = $ConfirmDelete
@onready var FN_alert = $FNAlert


func configurate(file_name: String):
	if !FileAccess.file_exists("user://saves/" + file_name + ".save"):
		print("Can't find the save file " + file_name + ".save while configurating save container")
		return

	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.READ)
	
	var data = file.get_var()
	
	save_name.text = file_name
	type_name.text = data["save_type"]
	date.text = Time.get_datetime_string_from_unix_time(data["unix_time"], true)
	
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
	text_edit.text = save_name.text
	confirm_overwrite.popup_centered()
	
	
func _on_delete_button_pressed():
	confirm_delete.dialog_text = "delete save " + save_name.text + ".save"
	confirm_delete.popup_centered()


func _on_confirm_delete_confirmed():
	snl.delete_save(save_name.text)
	events.emit_signal("saves_is_updated")


func _on_confirm_overwrite_confirmed():
	if text_edit.text == "":
		FN_alert.dialog_text = "You can't give an empty name to the save file"
		FN_alert.popup_centered()
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

		if (text_edit.text + ".save") in files and text_edit.text != save_name.text:
			FN_alert.dialog_text = "save file " + text_edit.text + ".save is already exists, choose other name"
			FN_alert.popup_centered()
			return
			
	snl.delete_save(save_name.text)
	snl.save_game(text_edit.text, "save")
	events.emit_signal("saves_is_updated")


var normal_chars = ['-', '_', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
@onready var previous_text = text_edit.text
@onready var previous_caret_position = text_edit.get_caret_column()

func _on_text_edit_text_changed():
	if len(text_edit.text) > 16:
		text_edit.text = previous_text
		text_edit.set_caret_column(previous_caret_position, false)
		return
	
	for char in text_edit.text:
		if char not in normal_chars:
			text_edit.text = previous_text
			text_edit.set_caret_column(previous_caret_position, false)
			return
	previous_text = text_edit.text
	previous_caret_position = text_edit.get_caret_column()


func _on_fn_alert_confirmed():
	text_edit.text = save_name.text
	confirm_overwrite.popup_centered()
