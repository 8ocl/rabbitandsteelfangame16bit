extends Area2D

@export var damage: float = 1.0

func _ready() -> void:
	# Temporarily disable collision
	collision_mask = 0
	
	# After 1 second, enable collision to damage players.
	get_tree().create_timer(1.0).timeout.connect(
		func() -> void:
			# Re-enable collision with players (assuming players are on layer 2)
			collision_mask = 1 << 1
	)
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
