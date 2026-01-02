extends CharacterBody2D
class_name PlayerBase

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

@export var normal_speed: float = 100.0
@export var slow_speed: float = 50.0

@export var primary_cooldown: float = 0.2
@export var secondary_cooldown: float = 1.0
@export var special_cooldown: float = 3.0
@export var defensive_cooldown: float = 2.0

@export_group("Input")
@export var input_prefix: String = "" # "" for player 1, "2" for player 2

@export_group("Combat")
@export var projectile_scene: PackedScene
@export var base_damage: float = 10.0
@export var crit_chance: float = 0.10 # 10% base crit chance
@export var crit_multiplier: float = 2.0

@export_group("Collision Layers (optional)")
# Configure these to match your project physics layers so players/bosses
# pass through each other but are still hit by projectiles.
@export var character_layer: int = 2
@export var environment_layer: int = 1
@export var enemy_projectile_layer: int = 4

@export_group("Health")
@export var max_health: float = 5.0 # 5 hearts

var current_speed: float
var can_primary := true
var can_secondary := true
var can_special := true
var can_defensive := true
var current_health: float

func _ready() -> void:
	randomize()
	current_speed = normal_speed
	current_health = max_health
	if not is_in_group("players"):
		add_to_group("players")
	_setup_collision()

func _physics_process(_delta: float) -> void:
	_handle_movement()
	_handle_actions()

func _handle_movement() -> void:
	var prefix := input_prefix
	# Shift for slow movement
	if Input.is_action_pressed(prefix + "sprint_slow"):
		current_speed = slow_speed
	else:
		current_speed = normal_speed

	var direction := Vector2.ZERO

	if Input.is_action_pressed(prefix + "move_right"):
		direction.x += 1
	if Input.is_action_pressed(prefix + "move_left"):
		direction.x -= 1
	if Input.is_action_pressed(prefix + "move_down"):
		direction.y += 1
	if Input.is_action_pressed(prefix + "move_up"):
		direction.y -= 1

	if direction.length() > 0.0:
		direction = direction.normalized()
		_update_facing_from_vector(direction)

	velocity = direction * current_speed
	move_and_slide()

func _handle_actions() -> void:
	var prefix := input_prefix

	# Primary action - rapid fire projectiles
	if Input.is_action_pressed(prefix + "primary_action") and can_primary:
		primary_action()

	# Secondary action - placeholder
	if Input.is_action_just_pressed(prefix + "secondary_action") and can_secondary:
		secondary_action()

	# Special action - placeholder
	if Input.is_action_just_pressed(prefix + "special_action") and can_special:
		special_action()

	# Defensive action - hold to keep active
	if Input.is_action_pressed(prefix + "defensive_action") and can_defensive:
		defensive_action()
	elif Input.is_action_just_released(prefix + "defensive_action"):
		end_defensive_action()

func primary_action() -> void:
	# Shoots a projectile towards the closest enemy in group "enemies".
	if projectile_scene == null:
		push_warning("No projectile_scene assigned on %s" % name)
		return

	can_primary = false

	var projectile := projectile_scene.instantiate()
	var root := get_tree().current_scene
	root.add_child(projectile)
	projectile.global_position = global_position

	var dir := _get_aim_direction()
	if dir == Vector2.ZERO:
		# Fallback direction if no enemies are found
		dir = Vector2.RIGHT

	_update_facing_from_vector(dir)

	# Preferred path: projectile has an initialize() method
	if projectile.has_method("initialize"):
		projectile.initialize(dir, base_damage, crit_chance, crit_multiplier, self)
	else:
		# Fallback: try to set common fields directly
		if "direction" in projectile:
			projectile.direction = dir
		if "base_damage" in projectile:
			projectile.base_damage = base_damage
		if "crit_chance" in projectile:
			projectile.crit_chance = crit_chance
		if "crit_multiplier" in projectile:
			projectile.crit_multiplier = crit_multiplier
		if "shooter" in projectile:
			projectile.shooter = self

	get_tree().create_timer(primary_cooldown).timeout.connect(
		func() -> void:
			can_primary = true
	)

func secondary_action() -> void:
	# Example: charged shot or melee attack hook
	can_secondary = false
	get_tree().create_timer(secondary_cooldown).timeout.connect(
		func() -> void:
			can_secondary = true
	)

func special_action() -> void:
	# Example: powerful ability hook
	can_special = false
	get_tree().create_timer(special_cooldown).timeout.connect(
		func() -> void:
			can_special = true
	)

func defensive_action() -> void:
	# Example: shield, damage reduction, etc.
	# Implement your defensive behavior here if needed.
	pass

func end_defensive_action() -> void:
	can_defensive = false
	get_tree().create_timer(defensive_cooldown).timeout.connect(
		func() -> void:
			can_defensive = true
	)

func apply_damage(amount: float, _is_crit: bool = false) -> void:
	current_health -= amount
	# TODO: hook up player-specific damage feedback (flash, sound, UI) here.
	if current_health <= 0.0:
		_die()

func _die() -> void:
	print("dead")
	# Later you can add respawn or game over logic here.

func _update_facing_from_vector(v: Vector2) -> void:
	if sprite == null:
		return
	if abs(v.x) < 0.01:
		return

	# Assume default sprite faces right; flip horizontally when aiming left.
	sprite.flip_h = v.x < 0.0

func _get_aim_direction() -> Vector2:
	# Aim towards the closest enemy in group "enemies".
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return Vector2.ZERO

	var closest: Node2D = null
	var min_dist := INF

	for e in enemies:
		if not (e is Node2D):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			closest = e

	if closest == null:
		return Vector2.ZERO

	return (closest.global_position - global_position).normalized()

func _layer_bit(index: int) -> int:
	return 1 << (index - 1)

func _setup_collision() -> void:
	# Optional: put all characters (players & bosses) on the same layer so they
	# pass through each other, but still collide with environment and enemy projectiles.
	if character_layer <= 0 or environment_layer <= 0 or enemy_projectile_layer <= 0:
		return

	collision_layer = _layer_bit(character_layer)
	collision_mask = _layer_bit(environment_layer) | _layer_bit(enemy_projectile_layer)
