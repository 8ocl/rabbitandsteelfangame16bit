extends Camera2D

func _ready() -> void:
	var root := get_tree().root
	if root.has_meta("camera_position"):
		global_position = root.get_meta("camera_position")
