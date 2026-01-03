extends Node2D

@export var fly_in_time: float = 1.0
@export var fly_in_offset: Vector2 = Vector2(-200, 0)

func _ready() -> void:
	# Defer setup so that player nodes have had a chance to join the "players" group.
	call_deferred("_init_players")

func _init_players() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return

	var root := get_tree().root
	# If previous scene stored exact player positions, restore them and skip fly-in.
	if root.has_meta("player_positions"):
		var stored: Dictionary = root.get_meta("player_positions")
		for p in players:
			if p is Node2D and stored.has(p.name):
				var node2d := p as Node2D
				node2d.global_position = stored[p.name]
			if "set_controls_enabled" in p:
				p.set_controls_enabled(true)
		return

	# Fallback: original fly-in behaviour if no stored positions exist.
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for p in players:
		if "set_controls_enabled" in p:
			p.set_controls_enabled(false)
		var node2d := p as Node2D
		var target_pos: Vector2 = node2d.global_position
		var start_pos: Vector2 = target_pos + fly_in_offset
		node2d.global_position = start_pos
		tween.tween_property(node2d, "global_position", target_pos, fly_in_time)

	tween.finished.connect(_on_fly_in_finished)

func _on_fly_in_finished() -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if "set_controls_enabled" in p:
			p.set_controls_enabled(true)
