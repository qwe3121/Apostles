extends Control


@onready var text_edit = $ConfirmSaveName/TextEdit
@onready var confirm_save_name = $ConfirmSaveName
@onready var FN_alert = $FNAlert


func _on_button_pressed():
	confirm_save_name.popup_centered()


func _on_confirm_save_name_confirmed():
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

		if (text_edit.text + ".save") in files:
			FN_alert.dialog_text = "save file " + text_edit.text + ".save is already exists, choose another name"
			FN_alert.popup_centered()
			return
			
	snl.save_game(text_edit.text, "save")
	$"../../../BackToMainMenu".grab_focus()
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
	text_edit.text = ""
	confirm_save_name.popup_centered()
