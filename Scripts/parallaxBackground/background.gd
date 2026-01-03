extends ParallaxLayer

@export var scroll_speed := -1.0  # pixels per second
@export var speed_multiplier := 1.0

func _ready() -> void:
	add_to_group("parallax_layers")
	# If a previous scene saved parallax offsets on the tree root, apply them
	var root := get_tree().root
	if root.has_meta("parallax_offsets"):
		var offsets: Dictionary = root.get_meta("parallax_offsets")
		if offsets.has(name):
			motion_offset.x = float(offsets[name])

func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier

func _process(delta: float) -> void:
	motion_offset.x += scroll_speed * speed_multiplier * delta
