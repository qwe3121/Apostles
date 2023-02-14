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
				
			# also need to add joystick support
			
			cfg.save_data()
			update_button_text(input_event)
			
			on_focus_on_all_buttons()
			action_button.release_focus()
			await get_tree().create_timer(0.001).timeout
			action_button.grab_focus()


func update_button_text(input_event: InputEvent):
	action_button.text = input_event.as_text()


func _on_action_button_toggled(button_pressed):
	if button_pressed:
		action_button.text = "press a key..."
		
		
func off_focus_on_all_buttons():
	var containers = containers_loc.get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node("ActionButton")
			button.focus_mode = FOCUS_NONE
			
			
func on_focus_on_all_buttons():
	var containers = containers_loc.get_children()
	for container in containers:
		if container == self:
			continue
		else:
			var button = container.get_node("ActionButton")
			button.focus_mode = FOCUS_ALL
