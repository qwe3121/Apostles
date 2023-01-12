extends CharacterBody2D


@export var right = 0
@export var left = 0

@export var speed = 300

@onready var right_corner = global_position.x + right
@onready var left_corner = global_position.x - left


func _ready():
	velocity.x = speed


func _physics_process(delta):
	move_and_slide()
	
	if right and left:
		if global_position.x >= right_corner or global_position.x <= left_corner:
				change_dir()
				return
				
	if is_on_wall() or not $RayCast2D.is_colliding():
			change_dir()


func change_dir():
	velocity.x *= -1
	$RayCast2D.position.x *= -1
