extends "res://Scripts/enemy_template.gd"

@export var move_delay: float = 2.0
@export var position_move_time: float = 1.0
@export var time_between_positions: float = 1.0
@export var small_bullet_scene: PackedScene = preload("res://Scenes/small_bullet.tscn")

var _positions: Array = []
var _current_index: int = 0
var _is_dying: bool = false
var _shadow: Sprite2D
const _gravity: float = 400.0

func _perform_circular_attack() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return

	var random_player = players[randi() % players.size()]
	
	var original_modulate = random_player.modulate
	random_player.modulate = Color(0.629, 0.003, 0.937, 1.0)

	var player_pos = random_player.global_position

	var bullets = []
	for i in range(8):
		var angle = i * PI / 4
		var spawn_pos = player_pos + Vector2(100, 0).rotated(angle)
		
		var bullet = small_bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = spawn_pos
		bullets.append(bullet)

	await get_tree().create_timer(1).timeout
 
	if is_instance_valid(random_player):
		random_player.modulate = original_modulate

	if not is_instance_valid(random_player):
		for bullet in bullets:
			if is_instance_valid(bullet):
				bullet.queue_free()
		return

	var target_pos = player_pos
	
	var health_ratio = _get_health_ratio()
	var speed_multiplier = 0.8 + (1.0 - health_ratio) * 2.0
	var bullet_speed = 200.0 * speed_multiplier

	for bullet in bullets:
		if is_instance_valid(bullet):
			var direction = (target_pos - bullet.global_position).normalized()
			bullet.velocity = direction * bullet_speed
			bullet.rotation = direction.angle()


func _ready() -> void:
	# Initialize base enemy behaviour (health, groups, etc.).
	super()
	# We will manually trigger attacks from the pattern; keep base auto loop off.
	auto_start_attacking = false
	_shadow = get_tree().current_scene.get_node_or_null("Shadow")
	if _shadow != null:
		_shadow.visible = true
		_shadow.modulate.a = 0.0
	call_deferred("_init_and_start_pattern")
	_hide_go_to_level_two_gate()

func _init_and_start_pattern() -> void:
	if anim != null:
		anim.play("BossIdle")
	var level := get_tree().current_scene
	if level == null:
		return
	var pos_root := level.get_node_or_null("SanchoPositionNodes")
	_positions.clear()
	if pos_root != null:
		for child in pos_root.get_children():
			if child is Node2D:
				_positions.append(child)
		# Sort by name so Position1, Position2, Position3 are in order.
		_positions.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	if _positions.is_empty():
		print("[SanchoBoss] No SanchoPositionNodes found in level, skipping pattern")
		return
	# Small delay so players finish flying in before the pattern starts.
	await get_tree().create_timer(move_delay).timeout
	if _shadow != null:
		var tween := create_tween()
		tween.tween_property(_shadow, "modulate:a", 0.9, 1.0)
	await _pattern_loop()

func _pattern_loop() -> void:
	while is_instance_valid(self) and not _is_dying:
		# Move to the next position.
		var pos_node: Node2D = _positions[_current_index]
		var target: Vector2 = pos_node.global_position
		print("[SanchoBoss] Moving to", pos_node.name, target)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "global_position", target, position_move_time)
		await tween.finished
		print("[SanchoBoss] Reached", pos_node.name)
		# After reaching a position, do the bullet attack
		_perform_circular_attack()
		# Advance index and wait a bit before the next move.
		_current_index = (_current_index + 1) % _positions.size()
		await get_tree().create_timer(time_between_positions).timeout

func _die() -> void:
	if _is_dying:
		return
	_is_dying = true

	# --- Physics Part ---
	# Disable collisions.
	collision_layer = 0
	collision_mask = 0

	# Hide health bar.
	if health_bar != null:
		health_bar.visible = false

	# A stronger upward "jump" to make the effect more visible.
	velocity.y = -300

	# After 3 seconds, the instance is removed from the scene.
	get_tree().create_timer(3.0).timeout.connect(queue_free)

	# --- Cinematic Part ---
	if _shadow != null:
		var tween := create_tween()
		tween.tween_property(_shadow, "modulate:a", 0.0, 1.0)
	# Screen Flash and Time Slowdown.
	_show_go_to_level_two_gate()
	var root := get_tree().current_scene
	if root != null:
		var flash := ColorRect.new()
		flash.color = Color(1, 1, 1, 0.8)
		flash.size = get_viewport().size * 10
		flash.position = Vector2(0, -100)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(flash)
		var tween := get_tree().create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.5)
		tween.finished.connect(flash.queue_free)

	var original_scale := Engine.time_scale
	Engine.time_scale = 0.5
	# This timer will be affected by time_scale unless configured otherwise.
	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = original_scale

func _physics_process(delta: float) -> void:
	if _is_dying:
		velocity.y += _gravity * delta
		move_and_slide()

func _hide_go_to_level_two_gate() -> void:
	var gate := get_tree().current_scene.get_node_or_null("GoToLevelFour")
	if gate != null:
		gate.visible = false
		var collision_shape = gate.get_node_or_null("CollisionShape2D")
		if collision_shape != null:
			collision_shape.set_deferred("disabled", true)

func _show_go_to_level_two_gate() -> void:
	var gate := get_tree().current_scene.get_node_or_null("GoToLevelFour")
	if gate != null:
		gate.visible = true
		var collision_shape = gate.get_node_or_null("CollisionShape2D")
		if collision_shape != null:
			collision_shape.set_deferred("disabled", false)
