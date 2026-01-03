extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var parallax_container: Control = $ParallaxContainer

var is_transitioning := false

func _ready() -> void:
	# Start invisible
	color_rect.visible = false
	parallax_container.visible = false

func transition_to_scene(scene_path: String, transition_duration: float = 1.5) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Show the parallax flying effect
	parallax_container.visible = true
	_animate_parallax(transition_duration)
	
	# Wait for half the transition, then change scene
	await get_tree().create_timer(transition_duration * 0.5).timeout
	
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s with error %d" % [scene_path, err])
		is_transitioning = false
		parallax_container.visible = false
		return
	
	# Wait for the rest of the transition
	await get_tree().create_timer(transition_duration * 0.5).timeout
	
	# Fade out the parallax
	_fade_out_parallax()
	await get_tree().create_timer(0.5).timeout
	
	parallax_container.visible = false
	is_transitioning = false

func _animate_parallax(duration: float) -> void:
	# Speed up all parallax layers during transition
	var parallax_layers = get_tree().get_nodes_in_group("parallax_layers")
	for layer in parallax_layers:
		if layer.has_method("set_transition_speed"):
			layer.set_transition_speed(duration)

func _fade_out_parallax() -> void:
	var tween = create_tween()
	tween.tween_property(parallax_container, "modulate:a", 0.0, 0.5)
	await tween.finished
	parallax_container.modulate.a = 1.0
