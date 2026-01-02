extends PlayerBase

# Player 2 also uses PlayerBase, but forces input_prefix = "2" in code so it
# reads actions like "2move_right", "2primary_action", etc.
# You only need to assign projectile_scene and damage values in the inspector.

func _ready() -> void:
	input_prefix = "2"
	super()
