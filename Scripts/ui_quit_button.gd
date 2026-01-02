extends Button

@onready var background: Sprite2D = $"../QuitGameBackground"

var _default_modulate: Color = Color(1, 1, 1, 1)
var _hover_modulate: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	if background != null:
		_default_modulate = background.modulate
		# Stronger glow
		_hover_modulate = _default_modulate.lightened(0.8)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	if background != null:
		background.modulate = _hover_modulate

func _on_mouse_exited() -> void:
	if background != null:
		background.modulate = _default_modulate

func _on_pressed() -> void:
	get_tree().quit()
