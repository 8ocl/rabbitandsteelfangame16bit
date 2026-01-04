extends "res://Scripts/small_bullet.gd"

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("Earth")

func _ready() -> void:
	super()
	if animated_sprite != null:
		animated_sprite.play("default")
