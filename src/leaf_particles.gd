extends GPUParticles2D


func _ready():
	texture = load("res://sprites/leaf_particle_%d.png" % randi_range(1, 3))
