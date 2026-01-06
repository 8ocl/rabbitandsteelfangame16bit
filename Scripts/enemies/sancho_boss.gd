extends "res://Scripts/enemy_template.gd"

@export var move_delay: float = 2.0
@export var position_move_time: float = 1.0
@export var time_between_positions: float = 1.0
@export var homing_bullet_scene: PackedScene = preload("res://Scenes/homing_bullet.tscn")

var _positions: Array = []
var _current_index: int = 0

func _perform_circular_attack() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return

	var random_player = players[randi() % players.size()]

	for i in range(8):
		var angle = i * PI / 4
		var spawn_pos = random_player.global_position + Vector2(100, 0).rotated(angle)
		
		var bullet = homing_bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = spawn_pos
		bullet.rotation = (global_position - bullet.global_position).angle()
		bullet.target = random_player


func _ready() -> void:
	# Initialize base enemy behaviour (health, groups, etc.).
	super()
	# We will manually trigger attacks from the pattern; keep base auto loop off.
	auto_start_attacking = false
	call_deferred("_init_and_start_pattern")

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
