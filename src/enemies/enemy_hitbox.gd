extends Area2D


@export var can_block: bool = false
@export_enum("hit", "fire", "bullet", "cut") var damage_source: String = "hit"
@export var damage: int = 1
@export var respect_col_pos: bool = false #if respect then check this

@export var hit_once: bool = false
var hitted_once: bool = false


var player_is_inside_damage_area = false

var attacking_entity


func _ready():
	if respect_col_pos:
		attacking_entity = get_node_or_null("CollisionShape2D")
		if attacking_entity == null:
			attacking_entity = get_node_or_null("CollisionPolygon2D")
			if attacking_entity == null:
				attacking_entity = get_node_or_null("Col")
				if attacking_entity == null:
					assert(false, "enemy hitbox of " + str(get_parent().name) + " can't find collision node")
	else:
		attacking_entity = get_parent()


func _process(delta):
	if hitted_once:
		return
	
	if player_is_inside_damage_area:
		if attacking_entity.global_position.x > global.player.global_position.x:
			global.player.get_damage(damage_source, damage, can_block, -1, true, null)
		else:
			global.player.get_damage(damage_source, damage, can_block, 1, true, null)


func _on_body_entered(body):
	player_is_inside_damage_area = true


func _on_body_exited(body):
	hitted_once = false
	player_is_inside_damage_area = false
