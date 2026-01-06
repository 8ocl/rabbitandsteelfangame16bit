extends Area2D

@export_file("*.tscn") var target_scene_path: String = "res://Scenes/spawn.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		# Reset GlobalState
		if GlobalState != null:
			GlobalState.reset()
		
		# Clear player_positions meta if it exists
		if get_tree().root.has_meta("player_positions"):
			get_tree().root.remove_meta("player_positions")
			
		get_tree().change_scene_to_file(target_scene_path)
