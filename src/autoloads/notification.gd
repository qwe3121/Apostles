extends CanvasLayer


@onready var text = $Control/NotificationPanel/Text
@onready var notification_panel = $Control/NotificationPanel
@onready var timer = $Control/Timer


var notifications: Array = []

var started = false


func _ready():
	events.scene_is_about_to_be_changed.connect(_on_scene_is_about_to_be_changed)


func add_nt(notification_string: String):
	notifications.push_back(notification_string)
	if !started:
		started = true
		show_nt()
	
	
func show_nt():
	text.text = notifications[0]
	notification_panel.visible = true
	notifications.remove_at(0)
	timer.start()


func _on_timer_timeout():
	next()


func _on_button_pressed():
	next()
	
	
func next():
	timer.stop()
	notification_panel.visible = false
	if notifications.size() > 0:
		show_nt()
	else:
		started = false
		
		
func _on_scene_is_about_to_be_changed():
	timer.stop()
	notification_panel.visible = false
	started = false
	notifications = []
