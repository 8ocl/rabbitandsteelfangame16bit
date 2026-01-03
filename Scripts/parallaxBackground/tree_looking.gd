extends ParallaxLayer

@export var scroll_speed := -2.0  # pixels per second

func _process(delta):
	motion_offset.x += scroll_speed * delta
