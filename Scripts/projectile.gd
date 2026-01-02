extends Area2D

@export var speed: float = 800.0
@export var lifetime: float = 2.0

var _direction: Vector2 = Vector2.RIGHT
var _base_damage: float = 10.0
var _crit_chance: float = 0.10
var _crit_multiplier: float = 2.0
var _shooter: Node = null

func _ready() -> void:
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func initialize(direction: Vector2, base_damage: float, crit_chance: float, crit_multiplier: float, shooter: Node) -> void:
	_direction = direction.normalized()
	_base_damage = base_damage
	_crit_chance = crit_chance
	_crit_multiplier = crit_multiplier
	_shooter = shooter

func _physics_process(_delta: float) -> void:
	position += _direction * speed * _delta

func _on_body_entered(body: Node) -> void:
	# Ignore the shooter so you don't shoot yourself.
	if body == _shooter:
		return

	if not body.has_method("apply_damage"):
		return

	var is_crit := randf() < _crit_chance
	var damage := _base_damage * (_crit_multiplier if is_crit else 1.0)

	# Body is expected to implement apply_damage(damage: float, is_crit: bool).
	body.apply_damage(damage, is_crit)
	queue_free()
