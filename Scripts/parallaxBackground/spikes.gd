extends ParallaxLayer

@export var scroll_speed := -3.5  # pixels per second

func _process(delta):
	motion_offset.x += scroll_speed * delta
