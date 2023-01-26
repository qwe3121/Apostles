extends Camera2D


var shake_power = 2
var shake_time = 0.4
var isShake = false
var curPos
var elapsedtime = 0


func _ready():
	global.camera = self
	curPos = offset


func _physics_process(delta):
	position = round(position)
	
	if isShake:
		shaking(delta)    
		

func shake(power_value = 2, time_value = 0.4):
	if isShake: return
	shake_power = power_value
	shake_time = time_value
	elapsedtime = 0
	isShake = true


func shaking(delta):
	if elapsedtime<shake_time:
		offset =  Vector2(randf(), randf()) * shake_power
		elapsedtime += delta
	else:
		isShake = false
		elapsedtime = 0
		offset = curPos  
