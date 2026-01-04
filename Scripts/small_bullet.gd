extends Area2D

@export var velocity: Vector2 = Vector2.ZERO
@export var life_time: float = 4.0
@export var damage: float = 1.0

func _ready() -> void:
	# Auto-despawn after some time
	get_tree().create_timer(life_time).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)


func set_direction(v: Vector2) -> void:
	velocity = v


func _physics_process(delta: float) -> void:
	global_position += velocity * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
	# The bullet is not destroyed, allowing it to pass through.
