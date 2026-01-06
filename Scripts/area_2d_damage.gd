extends Area2D

@export var damage := 1

func _ready():
	connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()  # Slice disappears after hitting
