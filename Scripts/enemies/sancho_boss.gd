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
	var arena := get_tree().current_scene
	var start_pos: Node2D = arena.get_node("StartingPositionForTransform")
	var move_nodes_parent = arena.get_node("Phase2MovementNodes")

	# Play transition animation when moving to start
	if anim:
		anim.play("BossTransition")

	await _tween_to(start_pos.global_position, 0.8)
	await get_tree().create_timer(1.0).timeout

	# Switch to looping Phase 2 animation
	if anim:
		anim.play("BossDidIt")

	while is_instance_valid(self) and not _is_dying:
		# Fly up
		await _tween_to(global_position + Vector2(0, -700), 0.6)
		await get_tree().create_timer(1.0).timeout

		# Spawn slices **await the coroutine**
		var warnings = await _spawn_warning_rectangles()

		# Randomize and dash through slices
		var move_nodes = move_nodes_parent.get_children()
		move_nodes.shuffle()
		for n in move_nodes:
			await _tween_to(n.global_position, 0.06)

		# Flash screen red to indicate the slash
		_flash_screen_red()

		# Now, apply damage to players within the slices
		for w in warnings:
			if not is_instance_valid(w):
				continue
			var area: Area2D = w
			for body in area.get_overlapping_bodies():
				if body.is_in_group("players") and body.has_method("apply_damage"):
					body.apply_damage(1.0)

		# Return to start
		await _tween_to(start_pos.global_position, 0.8)
		await get_tree().create_timer(2.0).timeout




func _spawn_warning_rectangles() -> Array:
	if not warning_slice_scene:
		warning_slice_scene = preload("res://Scenes/enemies/Sancho/warning_slice.tscn")

	var warnings: Array = []
	_active_warning_areas.clear()

	var viewport := get_viewport().get_visible_rect()
	var safe_spots := get_tree().current_scene.get_node("SafeSpots").get_children()
	var slice_count := 100

	# Use the shadow sprite as the spawning area
	var shadow_sprite := get_tree().current_scene.get_node_or_null("Shadow")
	if not shadow_sprite:
		push_error("Could not find Shadow sprite to define spawn area!")
		return []
	
	var shadow_size: Vector2 = shadow_sprite.texture.get_size() * shadow_sprite.scale
	var shadow_top_left: Vector2 = shadow_sprite.global_position - shadow_size / 2
	var spawn_rect := Rect2(shadow_top_left, shadow_size)


	for i in range(slice_count):
		var slice = warning_slice_scene.instantiate()
		
		# Get AnimatedSprite2D
		var sprite: AnimatedSprite2D = slice.get_node_or_null("AnimatedSprite2D")
		if not sprite:
			push_error("WarningSlice has no AnimatedSprite2D!")
			continue

		var area: Area2D = slice
		if not area:
			push_error("WarningSlice root is not an Area2D!")
			continue

		var shape_node := area.get_node_or_null("CollisionShape2D")
		if not shape_node:
			push_error("WarningSlice has no CollisionShape2D!")
			slice.queue_free()
			continue
		var shape: RectangleShape2D = shape_node.shape

		# Make slices long and skinny
		var thickness := randf_range(2.0, 5.0)
		var length: float = get_viewport().get_visible_rect().size.length() * 1.2
		var frame_texture = sprite.sprite_frames.get_frame_texture("default", 0)
		if frame_texture:
			sprite.scale = Vector2(length / frame_texture.get_width(), thickness / frame_texture.get_height())
		else:
			push_error("WarningSlice default animation has no texture!")
			slice.queue_free()
			continue
		shape.size = Vector2(length, thickness)

		# Random rotation
		slice.rotation = randf_range(0, TAU)

		# Random position within the shadow sprite
		var pos := Vector2(
			randf_range(spawn_rect.position.x, spawn_rect.end.x),
			randf_range(spawn_rect.position.y, spawn_rect.end.y)
		)
		slice.global_position = pos

		# Skip slice if too close to a safe spot
		var safe := false
		for s in safe_spots:
			if slice.global_position.distance_to(s.global_position) < 100:
				safe = true
				break
		if safe:
			slice.queue_free()
			continue

		get_tree().current_scene.add_child(slice)
		warnings.append(slice)
		_active_warning_areas.append(area)

		# Fade in animation, wait, and fade out
		sprite.modulate.a = 0.0
		var life_tween := create_tween()
		life_tween.tween_property(sprite, "modulate:a", 0.7, 0.25)
		life_tween.tween_interval(1.5) # Time for player to react
		life_tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
		life_tween.tween_callback(slice.queue_free)

	# Wait a bit before boss slices through
	await get_tree().create_timer(1.0).timeout

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


func _physics_process(delta: float) -> void:
	if _is_dying:
		velocity.y += _gravity * delta
		move_and_slide()


func _flash_screen_red():
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().current_scene.add_child(layer)

	var rect := ColorRect.new()
	rect.color = Color(1, 0, 0, 0.0)
	rect.size = get_viewport().size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)

	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.6, 0.5)
	tween.tween_property(rect, "modulate:a", 0.0, 0.5)

	tween.finished.connect(func():
		layer.queue_free()
	)
