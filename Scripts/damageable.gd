extends CharacterBody2D
class_name Damageable

@export var max_health: float = 100.0
@export var damage_number_scene: PackedScene = preload("res://Scenes/damage_number.tscn")

@export_group("Retaliation")
@export var retaliation_projectile_scene: PackedScene
@export var retaliation_damage: float = 5.0
@export var retaliation_crit_chance: float = 0.0
@export var retaliation_crit_multiplier: float = 1.5
@export var retaliation_cooldown: float = 0.5
@export var retaliation_target_group: String = "players"
@export var retaliation_projectile_layer_index: int = 4
@export var retaliation_target_layer_index: int = 2

var current_health: float
var _can_retaliate: bool = true

func _ready() -> void:
	current_health = max_health
	# Make all damageable entities show up as aim targets for players.
	if not is_in_group("enemies"):
		add_to_group("enemies")

func apply_damage(amount: float, is_crit: bool = false) -> void:
	current_health -= amount
	_show_damage_number(amount, is_crit)
	_retaliate()
	if current_health <= 0.0:
		_die()

func _show_damage_number(amount: float, is_crit: bool) -> void:
	if damage_number_scene == null:
		return

	var num := damage_number_scene.instantiate()
	# Put numbers in the current scene so they render on top cleanly.
	get_tree().current_scene.add_child(num)
	num.global_position = global_position + Vector2(0, -16)

	if num.has_method("show_amount"):
		num.show_amount(amount, is_crit)

func _retaliate() -> void:
	if retaliation_projectile_scene == null:
		return
	if not _can_retaliate:
		return

	var dir := _get_aim_direction_to_group(retaliation_target_group)
	if dir == Vector2.ZERO:
		return

	_can_retaliate = false
	call_deferred("_spawn_retaliation_projectile", dir)

func _spawn_retaliation_projectile(dir: Vector2) -> void:
	var projectile := retaliation_projectile_scene.instantiate()
	var root := get_tree().current_scene
	root.add_child(projectile)
	projectile.global_position = global_position

	if "collision_layer" in projectile and "collision_mask" in projectile:
		var proj_bit: int = 1 << int(max(retaliation_projectile_layer_index - 1, 0))
		var target_bit: int = 1 << int(max(retaliation_target_layer_index - 1, 0))
		projectile.collision_layer = proj_bit
		projectile.collision_mask = target_bit

	if projectile.has_method("initialize"):
		projectile.initialize(dir, retaliation_damage, retaliation_crit_chance, retaliation_crit_multiplier, self)
	else:
		if "direction" in projectile:
			projectile.direction = dir
		if "base_damage" in projectile:
			projectile.base_damage = retaliation_damage
		if "crit_chance" in projectile:
			projectile.crit_chance = retaliation_crit_chance
		if "crit_multiplier" in projectile:
			projectile.crit_multiplier = retaliation_crit_multiplier
		if "shooter" in projectile:
			projectile.shooter = self

	get_tree().create_timer(retaliation_cooldown).timeout.connect(
		func() -> void:
			_can_retaliate = true
	)

func _get_aim_direction_to_group(group_name: String) -> Vector2:
	var candidates := get_tree().get_nodes_in_group(group_name)
	if candidates.is_empty():
		return Vector2.ZERO

	var closest: Node2D = null
	var min_dist := INF

	for c in candidates:
		if not (c is Node2D):
			continue
		var d := global_position.distance_squared_to(c.global_position)
		if d < min_dist:
			min_dist = d
			closest = c

	if closest == null:
		return Vector2.ZERO

	return (closest.global_position - global_position).normalized()

func _die() -> void:
	queue_free()
