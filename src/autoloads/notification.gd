extends CanvasLayer


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
	$Control/NotificationPanel/Text.text = notifications[0]
	$Control/NotificationPanel.visible = true
	notifications.remove_at(0)
	$Control/Timer.start()


func _on_timer_timeout():
	next()


func _on_button_pressed():
	next()
	
	
func next():
	$Control/Timer.stop()
	$Control/NotificationPanel.visible = false
	if notifications.size() > 0:
		show_nt()
	else:
		started = false
		
		
func _on_scene_is_about_to_be_changed():
	$Control/Timer.stop()
	$Control/NotificationPanel.visible = false
	started = false
	notifications = []
