extends "res://Scripts/enemy_template.gd"

@export var move_delay: float = 2.0
@export var position_move_time: float = 1.0
@export var time_between_positions: float = 1.0
@export var phase_two_health_ratio := 0.5

@export var small_bullet_scene: PackedScene = preload("res://Scenes/small_bullet.tscn")
@export var warning_slice_scene: PackedScene = preload("res://Scenes/enemies/Sancho/warning_slice.tscn")

var _active_warning_areas: Array[Area2D] = []

var _positions: Array[Node2D] = []
var _current_index := 0
var _is_dying := false

var in_phase_two := false
var _phase_two_running := false

var _shadow: Sprite2D
const _gravity := 400.0

func _ready() -> void:
	super()
	auto_start_attacking = false

	_shadow = get_tree().current_scene.get_node_or_null("Shadow")
	if _shadow:
		_shadow.visible = true
		_shadow.modulate.a = 0.0

	call_deferred("_init_and_start_pattern")
	_hide_go_to_level_two_gate()


func _process(delta: float) -> void:
	if not in_phase_two and _get_health_ratio() <= phase_two_health_ratio:
		in_phase_two = true
		_start_phase_two()


func _init_and_start_pattern() -> void:
	if anim:
		anim.play("BossIdle")

	var level := get_tree().current_scene
	var pos_root := level.get_node_or_null("SanchoPositionNodes")

	if pos_root:
		for c in pos_root.get_children():
			if c is Node2D:
				_positions.append(c)
		_positions.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)

	if _positions.is_empty():
		return

	await get_tree().create_timer(move_delay).timeout

	if _shadow:
		create_tween().tween_property(_shadow, "modulate:a", 0.9, 1.0)

	await _pattern_loop()


func _pattern_loop() -> void:
	while is_instance_valid(self) and not _is_dying and not in_phase_two:
		var pos := _positions[_current_index]
		await _tween_to(pos.global_position, position_move_time)
		_perform_circular_attack()
		_current_index = (_current_index + 1) % _positions.size()
		await get_tree().create_timer(time_between_positions).timeout


func _perform_circular_attack() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return

	var player = players.pick_random()
	var original_modulate = player.modulate
	player.modulate = Color(0.629, 0.003, 0.937)

	var bullets := []
	for i in range(8):
		var angle := i * TAU / 8
		var bullet = small_bullet_scene.instantiate()
		bullet.global_position = player.global_position + Vector2(100, 0).rotated(angle)
		get_tree().current_scene.add_child(bullet)
		bullets.append(bullet)

	await get_tree().create_timer(1.0).timeout

	if not is_instance_valid(player):
		for b in bullets:
			b.queue_free()
		return

	player.modulate = original_modulate

	var speed := 200.0 * (0.8 + (1.0 - _get_health_ratio()) * 2.0)
	for b in bullets:
		var dir: Vector2 = (player.global_position - b.global_position).normalized()
		b.velocity = dir * speed
		b.rotation = dir.angle()


func _start_phase_two() -> void:
	if _phase_two_running:
		return
	_phase_two_running = true
	await _phase_two_loop()


func _phase_two_loop() -> void:
	var level := get_tree().current_scene

	var start_pos: Node2D = level.get_node("StartingPositionForTransform")
	var move_root: Node2D = level.get_node("Phase2MovementNodes")
	var safe_root: Node2D = level.get_node("SafeSpots")

	var move_nodes := move_root.get_children()
	var safe_spots := safe_root.get_children()

	while is_instance_valid(self) and not _is_dying:
		await _tween_to(start_pos.global_position, 0.8)
		await get_tree().create_timer(1.0).timeout

		await _tween_to(global_position + Vector2(0, -700), 0.6)
		await get_tree().create_timer(1.0).timeout

		var safe_spot: Node2D = safe_spots.pick_random()

		var warnings := _spawn_warning_rectangles(safe_spot)
		await get_tree().create_timer(1.0).timeout

		_apply_slice_damage()
		_flash_screen_red()

		for w in warnings:
			w.queue_free()

		for n in move_nodes:
			await _tween_to(n.global_position, 0.06)

		await _tween_to(start_pos.global_position, 0.8)
		await get_tree().create_timer(2.0).timeout


func _spawn_warning_rectangles(safe_spot: Node2D) -> Array:
	var warnings: Array = []
	_active_warning_areas.clear()

	var viewport := get_viewport().get_visible_rect()
	var safe_radius := 160.0
	var safe_center := safe_spot.global_position

	# Grid size for spawning slices
	var cols := 8
	var rows := 3
	var x_step := viewport.size.x / cols
	var y_step := viewport.size.y / rows

	for i in range(cols):
		for j in range(rows):
			var slice := warning_slice_scene.instantiate()
			var sprite: Sprite2D = slice.get_node("Sprite2D")
			var area: Area2D = slice.get_node("Area2D")
			var shape: RectangleShape2D = area.get_node("CollisionShape2D").shape

			var thickness := randf_range(6.0, 12.0)
			var length := viewport.size.length() * 1.2
			sprite.scale = Vector2(length, thickness)
			sprite.modulate = Color(1, 0, 0, 0.7)
			shape.size = Vector2(length, thickness)

			# Position slice with small random offset within the grid cell
			var pos_x := i * x_step + randf_range(-x_step * 0.4, x_step * 0.4)
			var pos_y := j * y_step + randf_range(-y_step * 0.4, y_step * 0.4)
			slice.global_position = Vector2(pos_x, pos_y)

			# Random rotation
			slice.rotation = randf_range(0, TAU)

			# Skip slice if it intersects safe spot
			if slice.global_position.distance_to(safe_center) < safe_radius:
				continue

			get_tree().current_scene.add_child(slice)
			warnings.append(slice)
			_active_warning_areas.append(area)

			# Fade in
			sprite.modulate.a = 0.0
			create_tween().tween_property(sprite, "modulate:a", 0.7, 0.2)

	return warnings


func _tween_to(pos: Vector2, time: float) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "global_position", pos, time)
	await t.finished


func _die() -> void:
	if _is_dying:
		return
	_is_dying = true

	collision_layer = 0
	collision_mask = 0

	if health_bar:
		health_bar.visible = false

	velocity.y = -300
	get_tree().create_timer(3.0).timeout.connect(queue_free)

	if _shadow:
		create_tween().tween_property(_shadow, "modulate:a", 0.0, 1.0)

	_show_go_to_level_two_gate()


func _physics_process(delta: float) -> void:
	if _is_dying:
		velocity.y += _gravity * delta
		move_and_slide()


func _hide_go_to_level_two_gate() -> void:
	var gate := get_tree().current_scene.get_node_or_null("GoToLevelFour")
	if gate:
		gate.visible = false
		gate.get_node("CollisionShape2D").disabled = true


func _show_go_to_level_two_gate() -> void:
	var gate := get_tree().current_scene.get_node_or_null("GoToLevelFour")
	if gate:
		gate.visible = true
		gate.get_node("CollisionShape2D").disabled = false


func _apply_slice_damage():
	var players := get_tree().get_nodes_in_group("players")
	for area in _active_warning_areas:
		for body in area.get_overlapping_bodies():
			if body in players:
				if body.has_method("take_damage"):
					body.take_damage(1)


func _flash_screen_red():
	var layer := CanvasLayer.new()
	layer.layer = 100  # Always on top
	get_tree().current_scene.add_child(layer)

	var rect := ColorRect.new()
	rect.color = Color(1, 0, 0, 0.0)
	rect.size = get_viewport().size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)

	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.45, 0.25)
	tween.tween_property(rect, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func(): layer.queue_free())
