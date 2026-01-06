extends "res://Scripts/small_bullet.gd"

var target: Node2D
var homing_delay: float = 1.0
var homing_speed: float = 100.0

func _ready() -> void:
	super._ready()
	set_process(false)
	var timer = get_tree().create_timer(homing_delay)
	timer.timeout.connect(start_homing)

func start_homing() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var direction_to_target = (target.global_position - global_position).normalized()
		velocity = velocity.move_toward(direction_to_target * homing_speed, 200 * delta)
		rotation = velocity.angle()
	else:
		# If the target is gone, just keep moving in the last direction.
		pass
