extends Area2D

@export var required_players: int = 2
@export_file("*.tscn") var next_scene_path: String = "res://Scenes/tutorial.tscn"

@onready var start_label: Label = $StartText

var _players_inside := {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_label()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	_players_inside[body.get_instance_id()] = body
	_update_label()
	print("StartGame: body_entered", body.name, "players_inside=", _players_inside.size())
	if _players_inside.size() >= required_players:
		_start_game()

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	_players_inside.erase(body.get_instance_id())
	_update_label()

func _update_label() -> void:
	if start_label != null:
		start_label.text = "%d/%d" % [_players_inside.size(), required_players]

func _start_game() -> void:
	if next_scene_path == "":
		print("StartGame: both players in area, but next_scene_path is NOT assigned in inspector")
		return
	print("StartGame: attempting scene change to", next_scene_path)
	var err := get_tree().change_scene_to_file(next_scene_path)
	if err != OK:
		print("StartGame: change_scene_to_file FAILED with code", err, "path=", next_scene_path)
