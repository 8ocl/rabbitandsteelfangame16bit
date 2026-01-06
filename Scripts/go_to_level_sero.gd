extends Area2D

@export var required_players: int = 2
@export_file("*.tscn") var next_scene_path: String = "res://Scenes/tutorial.tscn"
@export var start_delay: float = 0.75 # seconds both players must stay before starting

@onready var start_label: Label = $StartText
@onready var progress_bar: TextureProgressBar = get_node_or_null("StartProgress")

var _players_inside := {}
var _start_pending: bool = false
var _start_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_label()
	if progress_bar != null:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0
		progress_bar.visible = false

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	_players_inside[body.get_instance_id()] = body
	_update_label()
	print("StartGame: body_entered", body.name, "players_inside=", _players_inside.size())
	if _players_inside.size() >= required_players and not _start_pending:
		_start_pending = true
		_start_time = Time.get_ticks_msec() / 1000.0
		if progress_bar != null:
			progress_bar.visible = true
			progress_bar.value = 0.0
		var timer: SceneTreeTimer = get_tree().create_timer(start_delay)
		timer.timeout.connect(_on_start_delay_timeout)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	_players_inside.erase(body.get_instance_id())
	_update_label()
	# If one player steps out, cancel any pending start and hide the bar.
	if _players_inside.size() < required_players:
		_start_pending = false
		if progress_bar != null:
			progress_bar.visible = false
			progress_bar.value = 0.0

func _update_label() -> void:
	if start_label != null:
		start_label.text = "%d/%d" % [_players_inside.size(), required_players]

func _process(delta: float) -> void:
	if _start_pending and progress_bar != null:
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _start_time
		var t: float = clamp(elapsed / start_delay, 0.0, 1.0)
		progress_bar.value = t

func _start_game() -> void:
	_award_loot_box_choices_if_any()
	if next_scene_path == "":
		print("StartGame: both players in area, but next_scene_path is NOT assigned in inspector")
		return
	print("StartGame: attempting scene change to", next_scene_path)
	var err := get_tree().change_scene_to_file(next_scene_path)
	if err != OK:
		print("StartGame: change_scene_to_file FAILED with code", err, "path=", next_scene_path)

func _award_loot_box_choices_if_any() -> void:
	# This logic is now handled by the loot_box_ui script, which directly
	# updates the GlobalState singleton when an item is picked up.
	pass

# In the spawn scene we want to play the fly animation on the root node script
# (spawn.gd). If that method is missing, fall back to direct scene change.
func _can_progress_to_next_stage() -> bool:
	# Block progression if Ado is still alive in this scene.
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.name == "Ado" and "current_health" in e and e.current_health > 0.0:
			return false
	return true

func _start_fly_to_tutorial() -> void:
	if not _can_progress_to_next_stage():
		print("GoToLevelOne: Ado is still alive, cannot go to next stage yet.")
		return
	_award_loot_box_choices_if_any()
	var root := get_tree().current_scene
	if root != null:
		if root.has_method("go_to_tutorial"):
			root.go_to_tutorial()
			return
		if root.has_method("go_to_next_scene"):
			root.go_to_next_scene()
			return
	_start_game()

func _on_start_delay_timeout() -> void:
	# Only start if the countdown is still active and we still have enough players.
	if not _start_pending:
		return
	if _players_inside.size() >= required_players:
		_start_fly_to_tutorial()
	if progress_bar != null:
		progress_bar.visible = false
		progress_bar.value = 0.0
	_start_pending = false
