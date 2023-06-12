extends Sprite2D


@export var noise : FastNoiseLite
@export var speed = 20.0
var pos = 0

@onready var orig_scale = scale


func _ready():
	pos = randi_range(0, 512)
	
	
func _process(delta):
	pos += delta * speed
	scale = orig_scale * (1 + noise.get_noise_1d(pos) * 0.2)
