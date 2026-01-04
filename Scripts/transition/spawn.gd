extends Node2D

# Scene we will fly to (the tutorial level)
@export_file("*.tscn") var tutorial_scene_path: String = "res://Scenes/tutorial.tscn"

# How long and how far the camera flies before changing scenes
@export var fly_time: float = 1.5
@export var fly_offset: Vector2 = Vector2(1024, 0) # how far to "fly" (to the right)
@export var parallax_speed_multiplier_during_fly: float = 3.0

# Target X position for players at the end of the fly. Their Y is taken
# from wherever they are standing when the transition starts.
@export var player_target_x: float = 200.0

# In this scene the Camera2D is a direct child of the root
@onready var camera: Camera2D = $Camera2D

var _flying_to_tutorial: bool = false

func _ready() -> void:
	# Match viewport clear color to the game background to avoid grey flashes
	# when switching between scenes.
	RenderingServer.set_default_clear_color(Color(0.8804394, 0.832393, 0.8549745, 1.0))

func go_to_tutorial() -> void:
	if _flying_to_tutorial:
		return
	_flying_to_tutorial = true

	# Collect players once so we can both freeze and tween them.
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
	var target_camera_pos := camera.global_position + fly_offset
	tween.tween_property(
		camera,
		"global_position",
		target_camera_pos,
		fly_time
	)

	# Move all players horizontally only. We capture their current Y at the
	# moment the fly starts, and only change X so their vertical position
	# feels natural.
	for p in players:
		if p is Node2D:
			var node2d := p as Node2D
			var start_pos: Vector2 = node2d.global_position
			var player_target: Vector2 = Vector2(player_target_x, start_pos.y)
			# Run these tweens in parallel with the camera tween.
			tween.parallel().tween_property(node2d, "global_position", player_target, fly_time)

	tween.finished.connect(_on_fly_finished)

func _on_fly_finished() -> void:
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
	
	get_tree().change_scene_to_file(tutorial_scene_path)
