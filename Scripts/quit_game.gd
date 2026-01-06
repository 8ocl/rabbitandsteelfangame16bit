extends Area2D

@export var required_players: int = 2
@export var quit_delay: float = 0.75
@export var fade_time: float = 0.75
@onready var start_label: Label = $"../Retry/StartText"
@onready var progress_bar: TextureProgressBar = get_node_or_null("StartProgress")

var _players_inside := {}
var _quit_pending: bool = false
var _quit_time: float = 0.0
var _triggered: bool = false

# Fade objects
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_label()
	_create_fade_layer()

	if progress_bar != null:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0
		progress_bar.visible = false

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("players"):
		return

	_players_inside[body.get_instance_id()] = body
	_update_label()

	if _players_inside.size() >= required_players and not _quit_pending:
		_quit_pending = true
		_quit_time = Time.get_ticks_msec() / 1000.0

		if progress_bar != null:
			progress_bar.visible = true
			progress_bar.value = 0.0

		var timer := get_tree().create_timer(quit_delay)
		timer.timeout.connect(_on_quit_delay_timeout)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("players"):
		return

	_players_inside.erase(body.get_instance_id())
	_update_label()

	# Cancel quit if someone steps off
	if _players_inside.size() < required_players:
		_quit_pending = false
		if progress_bar != null:
			progress_bar.visible = false
			progress_bar.value = 0.0

func _process(delta: float) -> void:
	if _quit_pending and progress_bar != null:
		var elapsed := (Time.get_ticks_msec() / 1000.0) - _quit_time
		progress_bar.value = clamp(elapsed / quit_delay, 0.0, 1.0)

func _update_label() -> void:
	if start_label != null:
		start_label.text = "%d/%d" % [_players_inside.size(), required_players]

func _on_quit_delay_timeout() -> void:
	if not _quit_pending or _triggered:
		return

	if _players_inside.size() >= required_players:
		_triggered = true
		_start_fade_and_quit()

	if progress_bar != null:
		progress_bar.visible = false
		progress_bar.value = 0.0

	_quit_pending = false

# =================
# Fade → Quit logic
# =================

func _start_fade_and_quit() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, fade_time)
	tween.finished.connect(_on_fade_finished)

func _on_fade_finished() -> void:
	get_tree().quit()

func _create_fade_layer() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.color.a = 0.0
	_fade_rect.size = get_viewport_rect().size
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_fade_layer.add_child(_fade_rect)
	get_tree().root.add_child(_fade_layer)
