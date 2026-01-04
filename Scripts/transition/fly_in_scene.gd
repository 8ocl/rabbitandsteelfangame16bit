extends Node2D

@export var fly_in_time: float = 1.0
@export var fly_in_offset: Vector2 = Vector2(-200, 0)

# Outgoing transition settings (tutorial -> firstlevel, etc.).
@export_file("*.tscn") var next_scene_path: String = "res://Scenes/firstlevel.tscn"
@export var fly_time_out: float = 1.5
@export var fly_offset_out: Vector2 = Vector2(1024, 0)
@export var parallax_speed_multiplier_during_fly: float = 3.0
@export var player_target_x: float = 200.0

@onready var camera: Camera2D = $Camera2D

var _flying_out: bool = false

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

# Fly players and camera out to the next scene (tutorial -> firstlevel).
func go_to_next_scene() -> void:
	if _flying_out:
		return
	if next_scene_path == "":
		get_tree().change_scene_to_file("res://Scenes/firstlevel.tscn")
		return
	_flying_out = true

	var players := get_tree().get_nodes_in_group("players")

	# Freeze player controls during the fly animation so they can't move/shoot.
	for p in players:
		if "set_controls_enabled" in p:
			p.set_controls_enabled(false)

	# Speed up parallax background layers to enhance the feeling of flying.
	for layer in get_tree().get_nodes_in_group("parallax_layers"):
		if "set_speed_multiplier" in layer:
			layer.set_speed_multiplier(parallax_speed_multiplier_during_fly)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Move camera; parallax background scripts will make it look like flying.
	var target_camera_pos := camera.global_position + fly_offset_out
	tween.tween_property(
		camera,
		"global_position",
		target_camera_pos,
		fly_time_out
	)

	# Move all players horizontally only. Capture their current Y and only change X.
	for p in players:
		if p is Node2D:
			var node2d := p as Node2D
			var start_pos: Vector2 = node2d.global_position
			var player_target: Vector2 = Vector2(player_target_x, start_pos.y)
			# Run these tweens in parallel with the camera tween.
			tween.parallel().tween_property(node2d, "global_position", player_target, fly_time_out)

	tween.finished.connect(_on_fly_out_finished)

func _on_fly_out_finished() -> void:
	# Before changing scene, save current parallax offsets, camera position,
	# and final player positions onto the tree root so the next scene can restore them.
	var offsets: Dictionary = {}
	for layer in get_tree().get_nodes_in_group("parallax_layers"):
		offsets[layer.name] = layer.motion_offset.x
	var root := get_tree().root
	root.set_meta("parallax_offsets", offsets)
	root.set_meta("camera_position", camera.global_position)
	
	var player_positions: Dictionary = {}
	for p in get_tree().get_nodes_in_group("players"):
		if p is Node2D:
			var node2d := p as Node2D
			player_positions[node2d.name] = node2d.global_position
	root.set_meta("player_positions", player_positions)
	
	get_tree().change_scene_to_file(next_scene_path)
