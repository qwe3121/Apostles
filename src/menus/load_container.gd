extends Control


@onready var type_name = $HBoxContainer/Panel/TypeName
@onready var date = $HBoxContainer/Panel/Date
@onready var save_name = $HBoxContainer/Panel/SaveName
@onready var confirm_load = $ConfirmLoad
@onready var confirm_delete = $ConfirmDelete



func configurate(file_name: String):
	if !FileAccess.file_exists("user://saves/" + file_name + ".save"):
		print("Can't find the save file " + file_name + ".save while configurating load container")
		return

	var file = FileAccess.open("user://saves/" + file_name + ".save", FileAccess.READ)
	
	var data = file.get_var()
	
	save_name.text = file_name
	type_name.text = data["save_type"]
	date.text = Time.get_datetime_string_from_unix_time(data["unix_time"], true)
	
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
	confirm_load.dialog_text = "load save " + save_name.text + ".save"
	confirm_load.popup_centered()


func _on_delete_button_pressed():
	confirm_delete.dialog_text = "delete save " + save_name.text + ".save"
	confirm_delete.popup_centered()


func _on_confirm_load_confirmed():
	snl.load_game(save_name.text)


func _on_confirm_delete_confirmed():
	snl.delete_save(save_name.text)
	events.emit_signal("saves_is_updated")
