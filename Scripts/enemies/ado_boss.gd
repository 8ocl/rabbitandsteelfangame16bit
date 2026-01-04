extends "res://Scripts/enemy_template.gd"

@export var ado_move_delay: float = 2.0
@export var ado_position_move_time: float = 1.0
@export var ado_time_between_positions: float = 1.0
@export var ado_bullethell_chance: float = 0.4
@export var big_planet_scene: PackedScene = preload("res://Scenes/enemies/Ado/big_planet.tscn")
@export var warning_duration: float = 0.5
@export var big_planet_travel_time: float = 2.0
@export var warning_texture: Texture2D

var _positions: Array = []
var _current_index: int = 0
var _pattern_running: bool = false

var _is_dying: bool = false
const _gravity: float = 400.0

func _ready() -> void:
	# Initialize base enemy behaviour (health, groups, etc.).
	super()
	# We will manually trigger attacks from the pattern; keep base auto loop off.
	auto_start_attacking = false
	call_deferred("_init_and_start_pattern")

func _init_and_start_pattern() -> void:
	_hide_go_to_level_two_gate()
	var level := get_tree().current_scene
	if level == null:
		return
	var pos_root := level.get_node_or_null("AdoPositionNodes")
	_positions.clear()
	if pos_root != null:
		for child in pos_root.get_children():
			if child is Node2D:
				_positions.append(child)
		# Sort by name so Position1, Position2, Position3 are in order.
		_positions.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	if _positions.is_empty():
		print("[AdoBoss] No AdoPositionNodes found in level, skipping pattern")
		return
	if _pattern_running:
		return
	_pattern_running = true
	# Small delay so players finish flying in before the pattern starts.
	await get_tree().create_timer(ado_move_delay).timeout
	await _pattern_loop()
	_pattern_running = false

func _pattern_loop() -> void:
	while is_instance_valid(self) and not _is_dying:
		# Keep this looping for the whole fight for now; later you can branch
		# on health ratio for different phases.
		var ratio := _get_health_ratio()
		# Move to the next position.
		var pos_node: Node2D = _positions[_current_index]
		var target: Vector2 = pos_node.global_position
		print("[AdoBoss] Moving to", pos_node.name, target)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "global_position", target, ado_position_move_time)
		await tween.finished
		print("[AdoBoss] Reached", pos_node.name)
		# Cast earth (BigPlanet) at this index.
		await _do_big_planet_for_index(_current_index)
		# After earth spell, occasionally do a bullethell attack while above 50%.
		if randf() <= ado_bullethell_chance:
			print("[AdoBoss] Triggering bullethell after BigPlanet at index", _current_index)
			trigger_bullethell_attack_if_above_half()
		# Advance index and wait a bit before the next move.
		_current_index = (_current_index + 1) % _positions.size()
		await get_tree().create_timer(ado_time_between_positions).timeout

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
	var gate := get_tree().current_scene.get_node_or_null("GoToLevelTwo")
	if gate != null:
		gate.visible = false
		var collision_shape = gate.get_node_or_null("CollisionShape2D")
		if collision_shape != null:
			collision_shape.set_deferred("disabled", true)

func _show_go_to_level_two_gate() -> void:
	var gate := get_tree().current_scene.get_node_or_null("GoToLevelTwo")
	if gate != null:
		gate.visible = true
		var collision_shape = gate.get_node_or_null("CollisionShape2D")
		if collision_shape != null:
			collision_shape.set_deferred("disabled", false)

# Override the base circular attack so Ado's bullethell pattern stays the same
# (same number of bullets), but moves more slowly and only speeds up a bit near
# death.
func _perform_circular_attack() -> void:
	if bullet_scene == null:
		push_warning("AdoBoss has no bullet_scene assigned")
		return
	var root := get_tree().current_scene
	if root == null:
		return
	var origin: Vector2 = global_position
	if bullet_spawn != null:
		origin = bullet_spawn.global_position
	var count: int = max(bullets_in_circle, 1)
	var base_speed: float = bullet_speed
	var ratio := _get_health_ratio()
	# Base: quite slow. When near death (<30% HP), speed up a bit but keep the
	# same circular pattern.
	var speed_factor: float = 0.6
	if ratio <= 0.3:
		speed_factor = 0.9
	var speed_for_phase: float = base_speed * speed_factor
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		var dir := Vector2.RIGHT.rotated(angle)
		var bullet := bullet_scene.instantiate()
		root.add_child(bullet)
		if "global_position" in bullet:
			bullet.global_position = origin
		var velocity: Vector2 = dir * speed_for_phase
		if bullet.has_method("set_direction"):
			bullet.set_direction(velocity)
		elif "velocity" in bullet:
			bullet.velocity = velocity

func _do_big_planet_for_index(index: int) -> void:
	if big_planet_scene == null:
		print("[AdoBoss] big_planet_scene is null, cannot perform BigPlanet attack")
		return
	# Choose a player and aim the earth to land where they are standing when the
	# warning appears.
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var target_player: Node2D = null
	var min_dist := INF
	for p in players:
		if p is Node2D:
			var d := global_position.distance_squared_to(p.global_position)
			if d < min_dist:
				min_dist = d
				target_player = p
	if target_player == null:
		return
	var target_pos: Vector2 = target_player.global_position
	print("[AdoBoss] BigPlanet aimed at", target_player.name, target_pos)

	var origin: Vector2 = global_position
	if bullet_spawn != null:
		origin = bullet_spawn.global_position

	# New warning indicator using a "sprite" (ColorRect) that extends off-screen.
	var dir := (target_pos - origin).normalized()
	# A large distance to ensure the path goes off-screen.
	var off_screen_endpoint := origin + dir * 2000

	var path_length := (off_screen_endpoint - origin).length()
	var path_width := 20.0 # Reduced width as requested

	var warning_sprite := ColorRect.new()
	warning_sprite.color = Color(1, 0, 0, 0.5) # Red, semi-transparent
	warning_sprite.size = Vector2(path_width, path_length)
	# Set pivot to the middle of the top edge, so it rotates from Ado's center.
	warning_sprite.pivot_offset = Vector2(path_width / 2, 0)
	warning_sprite.global_position = origin
	# Align the rect with the direction vector. The angle is adjusted by PI/2
	# because a Control node's default "forward" is down.
	warning_sprite.rotation = dir.angle() - PI / 2.0
	warning_sprite.z_index = -2 # Set z_index below Ado
	get_tree().current_scene.add_child(warning_sprite)


	await get_tree().create_timer(warning_duration).timeout
	warning_sprite.queue_free()

	# Spawn BigPlanet at Ado (or her bullet spawn) and move it toward the target.
	var root := get_tree().current_scene
	if root == null:
		return
	
	var big_planet := big_planet_scene.instantiate()
	root.add_child(big_planet)
	big_planet.global_position = origin
	var velocity: Vector2 = (target_pos - origin) / max(big_planet_travel_time, 0.01)
	if big_planet.has_method("set_direction"):
		big_planet.set_direction(velocity)
	elif "velocity" in big_planet:
		big_planet.velocity = velocity
