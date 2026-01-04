extends CharacterBody2D
class_name PlayerBase

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var shadow: AnimatedSprite2D = get_node_or_null("AnimatedSprite2DShadow")
@onready var directional_arrow: Sprite2D = get_node_or_null("DirectionalArrow")
@onready var attack_ring_cooldown: AnimatedSprite2D = get_node_or_null("AttackRingCooldown")

@export var normal_speed: float = 100.0
@export var slow_speed: float = 50.0
@export var acceleration: float = 600.0
@export var deceleration: float = 800.0
@export var turn_speed: float = 8.0 # higher = faster turning

@export var primary_cooldown: float = 0.2
@export var secondary_cooldown: float = 1.0
@export var special_cooldown: float = 3.0
@export var defensive_cooldown: float = 2.0
@export var global_cooldown: float = 0.15

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

@export_group("Directional Arrow")
@export var arrow_orbit_radius: float = 12.0

@export_group("Attack Ring Cooldown")
@export var ring_fade_start: float = 0.85 # Start fading at 85% of cooldown
@export var ring_total_frames: int = 15 # Frame 0 to 14

@export_group("Defensive")
@export var invincible_orb_scene: PackedScene
@export var invincible_duration: float = 1.0

var controls_enabled: bool = true
var current_speed: float
var can_primary := true
var can_secondary := true
var can_special := true
var can_defensive := true
var can_cast := true # Global cooldown
var current_health: float

var _facing: float = 1.0
var _target_facing: float = 1.0

var _cooldown_start_time: float = 0.0
var _is_on_cooldown: bool = false

var _is_invincible: bool = false
var _invincible_orb_instance: Node2D = null

func _ready() -> void:
	randomize()
	current_speed = normal_speed
	current_health = max_health
	if not is_in_group("players"):
		add_to_group("players")
	_setup_collision()
	
	# Initialize attack ring as hidden
	if attack_ring_cooldown != null:
		attack_ring_cooldown.visible = false

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if controls_enabled:
		_handle_movement(delta)
		_handle_actions()
	
	# Face closest enemy, if any. If there are no enemies, keep current facing.
	var aim_dir := _get_aim_direction()
	if aim_dir != Vector2.ZERO:
		_update_facing_from_vector(aim_dir)

	# Smoothly turn towards target facing
	var t = clamp(turn_speed * delta, 0.0, 1.0)
	_facing = lerp(_facing, _target_facing, t)
	var should_flip = _facing < 0.0
	if anim != null:
		anim.flip_h = should_flip
	if shadow != null:
		shadow.flip_h = should_flip

	# Update directional arrow to orbit around player toward target
	if directional_arrow != null and aim_dir != Vector2.ZERO:
		var orbit_position = aim_dir * arrow_orbit_radius
		directional_arrow.position = orbit_position
		directional_arrow.rotation = aim_dir.angle()

	# Update attack ring cooldown animation
	_update_attack_ring(delta)

	_update_animation()

func _handle_movement(delta: float) -> void:
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
	
	var desired_velocity := direction * current_speed
	var accel := acceleration if direction != Vector2.ZERO else deceleration
	velocity = velocity.move_toward(desired_velocity, accel * delta)
	move_and_slide()

func _handle_actions() -> void:
	var prefix := input_prefix

	# Primary action - rapid fire projectiles
	if Input.is_action_pressed(prefix + "primary_action") and can_primary and can_cast:
		primary_action()

	# Secondary action - placeholder
	if Input.is_action_just_pressed(prefix + "secondary_action") and can_secondary and can_cast:
		secondary_action()

	# Special action - placeholder
	if Input.is_action_just_pressed(prefix + "special_action") and can_special and can_cast:
		special_action()

	# Defensive action - hold to keep active
	if Input.is_action_pressed(prefix + "defensive_action") and can_defensive and can_cast:
		defensive_action()
	elif Input.is_action_just_released(prefix + "defensive_action"):
		end_defensive_action()

func primary_action() -> void:
	# Shoots a projectile towards the closest enemy in group "enemies".
	if projectile_scene == null:
		push_warning("No projectile_scene assigned on %s" % name)
		return

	can_primary = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

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
			_is_on_cooldown = false
	)

func secondary_action() -> void:
	# Example: charged shot or melee attack hook
	can_secondary = false
	_trigger_global_cooldown()
	get_tree().create_timer(secondary_cooldown).timeout.connect(
		func() -> void:
			can_secondary = true
	)

func special_action() -> void:
	# Example: powerful ability hook
	can_special = false
	_trigger_global_cooldown()
	get_tree().create_timer(special_cooldown).timeout.connect(
		func() -> void:
			can_special = true
	)

func defensive_action() -> void:
	if invincible_orb_scene == null:
		return
	
	_trigger_global_cooldown()
	
	# Spawn invincible orb in the world, not attached to player
	if _invincible_orb_instance == null:
		_invincible_orb_instance = invincible_orb_scene.instantiate()
		var root = get_tree().current_scene
		root.add_child(_invincible_orb_instance)
		_invincible_orb_instance.global_position = global_position
		
		# Connect orb to affect players
		if _invincible_orb_instance.has_signal("body_entered"):
			_invincible_orb_instance.body_entered.connect(_on_orb_body_entered)
	
	# Enable invincibility
	_is_invincible = true
	
	# White out the player sprite more noticeably (add brightness)
	if anim != null:
		anim.modulate = Color(3, 3, 3, 1) # Bright white glow
	
	# Set timer to remove invincibility
	get_tree().create_timer(invincible_duration).timeout.connect(
		func() -> void:
			_is_invincible = false
			if _invincible_orb_instance != null:
				_invincible_orb_instance.queue_free()
				_invincible_orb_instance = null
			if anim != null:
				anim.modulate = Color(1, 1, 1, 1) # Reset to normal
	)

func end_defensive_action() -> void:
	can_defensive = false
	get_tree().create_timer(defensive_cooldown).timeout.connect(
		func() -> void:
			can_defensive = true
	)

func apply_damage(amount: float, _is_crit: bool = false) -> void:
	# Ignore damage if invincible
	if _is_invincible:
		return
	
	current_health -= amount
	# TODO: hook up player-specific damage feedback (flash, sound, UI) here.

	# Become invincible for 1 second after taking damage.
	_is_invincible = true
	# A simple visual feedback for invincibility.
	if anim != null:
		anim.modulate.a = 0.5
	get_tree().create_timer(1.0).timeout.connect(func():
		_is_invincible = false
		if anim != null:
			anim.modulate.a = 1.0
	)

	if current_health <= 0.0:
		_die()

func _die() -> void:
	print("dead")
	# Later you can add respawn or game over logic here.

func _update_facing_from_vector(v: Vector2) -> void:
	if abs(v.x) < 0.01:
		return
	# Assume default sprite faces right; facing = +1 for right, -1 for left.
	_target_facing = -1.0 if v.x < 0.0 else 1.0

func _update_animation() -> void:
	if anim == null:
		return
	var moving := velocity.length_squared() > 1.0
	var target_anim := "TetoFly" if moving else "TetoIdle"
	if anim.animation != target_anim:
		anim.play(target_anim)
	
	# Sync shadow with main sprite
	if shadow != null:
		if shadow.animation != target_anim:
			shadow.animation = target_anim
			shadow.play(target_anim)
		shadow.frame = anim.frame

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

func _start_cooldown_ring() -> void:
	_cooldown_start_time = Time.get_ticks_msec() / 1000.0
	_is_on_cooldown = true
	if attack_ring_cooldown != null:
		attack_ring_cooldown.visible = true
		attack_ring_cooldown.frame = 0
		attack_ring_cooldown.modulate.a = 0.50980395 # Reset to original alpha

func _update_attack_ring(delta: float) -> void:
	if attack_ring_cooldown == null or not _is_on_cooldown:
		return
	
	var elapsed = (Time.get_ticks_msec() / 1000.0) - _cooldown_start_time
	var progress = clamp(elapsed / primary_cooldown, 0.0, 1.0)
	
	# Ease in cubic for smooth acceleration
	var eased_progress = pow(progress, 3.0)
	
	# Calculate frame (0 = max circle, 14 = character)
	var target_frame = int(eased_progress * (ring_total_frames - 1))
	attack_ring_cooldown.frame = target_frame
	
	# Fade out near the end
	if progress >= ring_fade_start:
		var fade_progress = (progress - ring_fade_start) / (1.0 - ring_fade_start)
		var base_alpha = 0.50980395 # Original alpha from scene
		attack_ring_cooldown.modulate.a = lerp(base_alpha, 0.0, fade_progress)
	
	# Hide when complete
	if progress >= 1.0:
		attack_ring_cooldown.visible = false

func _trigger_global_cooldown() -> void:
	can_cast = false
	get_tree().create_timer(global_cooldown).timeout.connect(
		func() -> void:
			can_cast = true
	)

func _on_orb_body_entered(body: Node) -> void:
	if body is PlayerBase and body != self:
		body._is_invincible = true
		if body.anim != null:
			body.anim.modulate = Color(3, 3, 3, 1)
		
		# Remove invincibility after orb duration
		get_tree().create_timer(invincible_duration).timeout.connect(
			func() -> void:
				if body.anim != null:
					body.anim.modulate = Color(1, 1, 1, 1)
				body._is_invincible = false
		)
