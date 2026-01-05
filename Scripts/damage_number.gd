extends Label
class_name DamageNumber

@export var float_distance: float = 24.0
@export var duration: float = 0.6

func show_amount(amount: float, is_crit: bool) -> void:
	text = str(int(round(amount)))
	if is_crit:
		# Make crits stand out
		add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - float_distance, duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)
