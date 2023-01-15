extends HBoxContainer


@export var action : String


func _ready():
	$ActionLabel.text = action
	events.ready_to_load_keys_containers.connect(_on_ready_to_load_keys_containers)

		
func _on_ready_to_load_keys_containers():
	if InputMap.action_get_events(action)[0]:
		update_button_text(InputMap.action_get_events(action)[0])
	else:
		$ActionButton.text = "There is no key on it"


func _input(input_event: InputEvent):
	if $ActionButton.button_pressed and not input_event is InputEventMouseMotion:
		off_focus_on_all_buttons()
		if not input_event.is_pressed():
			$ActionButton.button_pressed = false
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, input_event)

			if input_event is InputEventMouseButton:
				cfg.cfg_data[action] = [input_event.button_index, "InputEventMouseButton"]
			elif input_event is InputEventKey:
				cfg.cfg_data[action] = [input_event.keycode, "InputEventKey"]
				
			# also need to add joystick support
			
			cfg.save_data()
			update_button_text(input_event)
			
			on_focus_on_all_buttons()
			$ActionButton.release_focus()
			await get_tree().create_timer(0.001).timeout
			$ActionButton.grab_focus()
			


func update_button_text(input_event: InputEvent):
	$ActionButton.text = input_event.as_text()


func _on_action_button_toggled(button_pressed):
	if button_pressed:
		$ActionButton.text = "press a key..."
		
		
func off_focus_on_all_buttons():
	var containers = $"..".get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node("ActionButton")
			button.focus_mode = FOCUS_NONE
			
			
func on_focus_on_all_buttons():
	var containers = $"..".get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node("ActionButton")
			button.focus_mode = FOCUS_ALL
