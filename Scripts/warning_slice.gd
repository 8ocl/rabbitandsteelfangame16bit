extends Area2D

@export var damage: float = 1.0

func _ready() -> void:
	# Only collide with players (assuming players are on layer 2)
	collision_mask = 1 << 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
