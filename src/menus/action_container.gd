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
	if action_button.button_pressed and input_event is InputEventKey and input_event.key_label == KEY_ESCAPE and not input_event.is_pressed():
		action_button.button_pressed = false
		events.emit_signal("ready_to_load_keys_containers")
		on_all_buttons()
		return
	
	if action_button.button_pressed and not input_event is InputEventMouseMotion:
#		off_focus_on_all_buttons()
		if not input_event.is_pressed():
			action_button.button_pressed = false
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, input_event)

			if input_event is InputEventMouseButton:
				cfg.cfg_data[action] = [input_event.button_index, "InputEventMouseButton"]
			elif input_event is InputEventKey:
				cfg.cfg_data[action] = [input_event.keycode, "InputEventKey"]
				
			for cycle_action_name in cfg.default_keys.keys():
				if cycle_action_name == action:
					continue
				if InputMap.action_has_event(cycle_action_name, input_event):
					InputMap.action_erase_event(cycle_action_name, input_event)
					cfg.cfg_data[cycle_action_name] = null
				
			# also need to add joystick support
			
			cfg.save_data()
			
			events.emit_signal("ready_to_load_keys_containers")
			
			on_all_buttons()


func update_button_text(input_event: InputEvent):
	action_button.text = input_event.as_text()


func _on_action_button_toggled(button_pressed):
	if button_pressed:
		global.remapping_action = true
		off_all_buttons()
		action_button.text = "press a key..."
		action_button.disabled = true
	else:
		global.remapping_action = false
		action_button.disabled = false
		
		
func off_all_buttons():
	var containers = containers_loc.get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node_or_null("ActionButton")
			if not button == null: 
				button.focus_mode = FOCUS_NONE
				button.disabled = true
			button = container.get_node_or_null("ActionButton2")
			if not button == null: 
				button.focus_mode = FOCUS_NONE
				button.disabled = true
	$"../../../../../../BackToMainMenu".focus_mode = FOCUS_NONE
	$"../../../../../../BackToMainMenu".disabled = true
	$"../../../../../../BackToDefaults".focus_mode = FOCUS_NONE
	$"../../../../../../BackToDefaults".disabled = true
	for tab_button in $"../../../../../../TabButtonsContainer".get_children():
		tab_button.focus_mode = FOCUS_NONE
		tab_button.disabled = true
			
			
func on_all_buttons():
	var containers = containers_loc.get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node_or_null("ActionButton")
			if not button == null: 
				button.focus_mode = FOCUS_ALL
				button.disabled = false
			button = container.get_node_or_null("ActionButton2")
			if not button == null: 
				button.focus_mode = FOCUS_ALL
#				button.disabled = false
	$"../../../../../../BackToMainMenu".focus_mode = FOCUS_ALL
	$"../../../../../../BackToMainMenu".disabled = false
	$"../../../../../../BackToDefaults".focus_mode = FOCUS_ALL
	$"../../../../../../BackToDefaults".disabled = false
	for tab_button in $"../../../../../../TabButtonsContainer".get_children():
		tab_button.focus_mode = FOCUS_ALL
		tab_button.disabled = false
