extends ScrollContainer


var old_scroll_vertical = 0


func _process(delta):
	if old_scroll_vertical < scroll_vertical:
		scroll_vertical += 15
	elif old_scroll_vertical > scroll_vertical:
		scroll_vertical -= 15
	old_scroll_vertical = scroll_vertical
