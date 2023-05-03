extends HBoxContainer


@export var action : String

@onready var action_label = $ActionLabel
@onready var action_button = $ActionButton
@onready var control = $Control
@onready var containers_loc = $".."


func _ready():
	action_label.text = action
	events.ready_to_load_keys_containers.connect(_on_ready_to_load_keys_containers)

		
func _on_ready_to_load_keys_containers():
	if not len(InputMap.action_get_events(action)) > 0:
		action_button.text = "There is no key on it"
		return
	
	if InputMap.action_get_events(action)[0]:
		update_button_text(InputMap.action_get_events(action)[0])
	else:
		action_button.text = "There is no key on it"


func _input(input_event: InputEvent):
	if action_button.button_pressed and not input_event is InputEventMouseMotion:
		off_focus_on_all_buttons()
		if not input_event.is_pressed():
			action_button.button_pressed = false
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, input_event)

			if input_event is InputEventMouseButton:
				cfg.cfg_data[action] = [input_event.button_index, "InputEventMouseButton"]
			elif input_event is InputEventKey:
				cfg.cfg_data[action] = [input_event.keycode, "InputEventKey"]
				
			for cycle_action_name in InputMap.get_actions():
				if cycle_action_name == action:
					continue
				if InputMap.action_has_event(cycle_action_name, input_event):
					InputMap.action_erase_event(cycle_action_name, input_event)
					cfg.cfg_data[cycle_action_name] = null
				
			# also need to add joystick support
			
			cfg.save_data()
			
			events.emit_signal("ready_to_load_keys_containers")
			
			on_focus_on_all_buttons()
			
			$"../../../../../..".some_action_button_toggled = false


func update_button_text(input_event: InputEvent):
	action_button.text = input_event.as_text()


func _on_action_button_toggled(button_pressed):
	if button_pressed:
		action_button.text = "press a key..."
		$"../../../../../..".some_action_button_toggled = true
		
		
func off_focus_on_all_buttons():
	var containers = containers_loc.get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node("ActionButton")
			button.focus_mode = FOCUS_NONE
	$"../../../../../../BackToMainMenu".focus_mode = FOCUS_NONE
	$"../../../../../../BackToDefaults".focus_mode = FOCUS_NONE
			
			
func on_focus_on_all_buttons():
	var containers = containers_loc.get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node("ActionButton")
			button.focus_mode = FOCUS_ALL
	$"../../../../../../BackToMainMenu".focus_mode = FOCUS_ALL
	$"../../../../../../BackToDefaults".focus_mode = FOCUS_ALL
