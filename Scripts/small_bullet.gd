extends Area2D

@export var velocity: Vector2 = Vector2.ZERO
@export var life_time: float = 4.0

func _ready() -> void:
	# Auto-despawn after some time
	await get_tree().create_timer(life_time).timeout
	queue_free()


func set_direction(v: Vector2) -> void:
	velocity = v


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
