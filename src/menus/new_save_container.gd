extends Control


func _on_button_pressed():
	$ConfirmSaveName.popup_centered()


func _on_confirm_save_name_confirmed():
	if $ConfirmSaveName/TextEdit.text == "":
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

		if ($ConfirmSaveName/TextEdit.text + ".save") in files:
			$FNAlert.dialog_text = "save file " + $ConfirmSaveName/TextEdit.text + ".save is already exists, choose other name"
			$FNAlert.popup_centered()
			return
			
	snl.save_game($ConfirmSaveName/TextEdit.text, "save")
	events.emit_signal("saves_is_updated")


var normal_chars = ['-', '_', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
@onready var previous_text = $ConfirmSaveName/TextEdit.text
@onready var previous_caret_position = $ConfirmSaveName/TextEdit.get_caret_column()

func _on_text_edit_text_changed():
	for char in $ConfirmSaveName/TextEdit.text:
		if char not in normal_chars:
			$ConfirmSaveName/TextEdit.text = previous_text
			$ConfirmSaveName/TextEdit.set_caret_column(previous_caret_position, false)
			return
	previous_text = $ConfirmSaveName/TextEdit.text
	previous_caret_position = $ConfirmSaveName/TextEdit.get_caret_column()


func _on_fn_alert_confirmed():
	$ConfirmSaveName/TextEdit.text = ""
	$ConfirmSaveName.popup_centered()
