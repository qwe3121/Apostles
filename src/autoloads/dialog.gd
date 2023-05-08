extends Node


var dialog_is_showed: bool = false


func _ready():
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS


func start(path: String):
	dialog_is_showed = true
	
	global.player.ui.visible = false
	
	Dialogic.start(path).process_mode = Node.PROCESS_MODE_ALWAYS
	Dialogic.timeline_ended.connect(_on_the_end_of_dialog)
	
	get_tree().paused = true


func _on_the_end_of_dialog():
	dialog_is_showed = false
	
	global.player.ui.visible = true
	
	await get_tree().create_timer(0.2).timeout

	get_tree().paused = false
