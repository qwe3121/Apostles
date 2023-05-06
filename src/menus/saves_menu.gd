extends Control


var deleting_1_loading_2_new_game_3: int

var cur_workaround_save_index

var ig: bool = false


func _ready():
	ig = not get_parent().name == "MainMenuOOG"


func update():
	if !FileAccess.file_exists("user://saves/1.save"):
		$MarginContainer/GridContainer/Save1/TextureRect.texture = load("res://icon.svg")
		$MarginContainer/GridContainer/Save1/Load1.text = "NEW STORY"
		$MarginContainer/GridContainer/Save1/Delete1.disabled = true
	else:
		var file = FileAccess.open("user://saves/1.save", FileAccess.READ)
	
		var data = file.get_var()
		
		$MarginContainer/GridContainer/Save1/Panel/Label.text = Time.get_datetime_string_from_unix_time(data["unix_time"], true) \
		+ "/n" + data["world_name"]
		
		var image = Image.new()
		var err = image.load("user://screenshots/1.png")
		if err != OK:
			print("Image loading is errored while configurating save 1")
			print("Error - " + str(err))
			return
		var texture = ImageTexture.create_from_image(image)
		$MarginContainer/GridContainer/Save1/TextureRect.texture = texture
		
	if !FileAccess.file_exists("user://saves/2.save"):
		$MarginContainer/GridContainer/Save2/TextureRect.texture = load("res://icon.svg")
		$MarginContainer/GridContainer/Save2/Load2.text = "NEW STORY"
		$MarginContainer/GridContainer/Save2/Delete2.disabled = true
	else:
		var file = FileAccess.open("user://saves/2.save", FileAccess.READ)
	
		var data = file.get_var()
		
		$MarginContainer/GridContainer/Save2/Panel/Label.text = Time.get_datetime_string_from_unix_time(data["unix_time"], true) \
		+ "/n" + data["world_name"]
		
		var image = Image.new()
		var err = image.load("user://screenshots/2.png")
		if err != OK:
			print("Image loading is errored while configurating save 2")
			print("Error - " + str(err))
			return
		var texture = ImageTexture.create_from_image(image)
		$MarginContainer/GridContainer/Save2/TextureRect.texture = texture
		
	if !FileAccess.file_exists("user://saves/3.save"):
		$MarginContainer/GridContainer/Save3/TextureRect.texture = load("res://icon.svg")
		$MarginContainer/GridContainer/Save3/Load3.text = "NEW STORY"
		$MarginContainer/GridContainer/Save3/Delete3.disabled = true
	else:
		var file = FileAccess.open("user://saves/3.save", FileAccess.READ)
	
		var data = file.get_var()
		
		$MarginContainer/GridContainer/Save3/Panel/Label.text = Time.get_datetime_string_from_unix_time(data["unix_time"], true) \
		+ "/n" + data["world_name"]
		
		var image = Image.new()
		var err = image.load("user://screenshots/3.png")
		if err != OK:
			print("Image loading is errored while configurating save 3")
			print("Error - " + str(err))
			return
		var texture = ImageTexture.create_from_image(image)
		$MarginContainer/GridContainer/Save3/TextureRect.texture = texture
		
		
func _on_load_1_pressed():
	cur_workaround_save_index = 1
	
	if !FileAccess.file_exists("user://saves/1.save"):
		deleting_1_loading_2_new_game_3 = 3
		if ig:
			$ConfirmationDialog.dialog_text = "You gonna start new game in slot " + str(cur_workaround_save_index) + ". Non saved progress of current save slot will dissapear!"
		else: 
			$ConfirmationDialog.dialog_text = "You gonna start new game in slot " + str(cur_workaround_save_index) + ". Are you sure?" 
		$ConfirmationDialog.popup_centered()
	else:
		deleting_1_loading_2_new_game_3 = 2
		if ig:
			$ConfirmationDialog.dialog_text = "You gonna load save " + str(cur_workaround_save_index) + ". Non saved progress of current save slot will dissapear!" 
		else:
			$ConfirmationDialog.dialog_text = "You gonna load save " + str(cur_workaround_save_index) + ". Are you sure?" 
		$ConfirmationDialog.popup_centered()


func _on_delete_1_pressed():
	cur_workaround_save_index = 1
	
	deleting_1_loading_2_new_game_3 = 1
	
	$ConfirmationDialog.dialog_text = "You gonna delete save " + str(cur_workaround_save_index) + ". Are you sure?" 
	$ConfirmationDialog.popup_centered()


func _on_load_2_pressed():
	cur_workaround_save_index = 2
	
	if !FileAccess.file_exists("user://saves/1.save"):
		deleting_1_loading_2_new_game_3 = 3
		if ig:
			$ConfirmationDialog.dialog_text = "You gonna start new game in slot " + str(cur_workaround_save_index) + ". Non saved progress of current save slot will dissapear!"
		else: 
			$ConfirmationDialog.dialog_text = "You gonna start new game in slot " + str(cur_workaround_save_index) + ". Are you sure?" 
		$ConfirmationDialog.popup_centered()
	else:
		deleting_1_loading_2_new_game_3 = 2
		if ig:
			$ConfirmationDialog.dialog_text = "You gonna load save " + str(cur_workaround_save_index) + ". Non saved progress of current save slot will dissapear!" 
		else:
			$ConfirmationDialog.dialog_text = "You gonna load save " + str(cur_workaround_save_index) + ". Are you sure?" 
		$ConfirmationDialog.popup_centered()


func _on_delete_2_pressed():
	cur_workaround_save_index = 2
	
	deleting_1_loading_2_new_game_3 = 1
	
	$ConfirmationDialog.dialog_text = "You gonna delete save " + str(cur_workaround_save_index) + ". Are you sure?" 
	$ConfirmationDialog.popup_centered()


func _on_load_3_pressed():
	cur_workaround_save_index = 3
	
	if !FileAccess.file_exists("user://saves/1.save"):
		deleting_1_loading_2_new_game_3 = 3
		if ig:
			$ConfirmationDialog.dialog_text = "You gonna start new game in slot " + str(cur_workaround_save_index) + ". Non saved progress of current save slot will dissapear!"
		else: 
			$ConfirmationDialog.dialog_text = "You gonna start new game in slot " + str(cur_workaround_save_index) + ". Are you sure?" 
		$ConfirmationDialog.popup_centered()
	else:
		deleting_1_loading_2_new_game_3 = 2
		if ig:
			$ConfirmationDialog.dialog_text = "You gonna load save " + str(cur_workaround_save_index) + ". Non saved progress of current save slot will dissapear!" 
		else:
			$ConfirmationDialog.dialog_text = "You gonna load save " + str(cur_workaround_save_index) + ". Are you sure?" 
		$ConfirmationDialog.popup_centered()


func _on_delete_3_pressed():
	cur_workaround_save_index = 2
	
	deleting_1_loading_2_new_game_3 = 1
	
	$ConfirmationDialog.dialog_text = "You gonna delete save " + str(cur_workaround_save_index) + ". Are you sure?" 
	$ConfirmationDialog.popup_centered()
	
	
func _on_confirmation_dialog_confirmed():
	if deleting_1_loading_2_new_game_3 == 1:
		snl.delete_save(str(cur_workaround_save_index))
		update()
	elif deleting_1_loading_2_new_game_3 == 2:
		global.save_index = cur_workaround_save_index
		snl.load_game(str(cur_workaround_save_index))
	elif deleting_1_loading_2_new_game_3 == 3:
		#create save here
		global.save_index = cur_workaround_save_index
		trans.change_scene("res://src/world.tscn")
