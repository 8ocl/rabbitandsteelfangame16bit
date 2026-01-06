extends Node

signal health_changed(current_health, max_health)
signal items_changed

var max_health: int = 6
var current_health: int

var player1_items: Array = []
var player2_items: Array = []

const MAX_ITEMS_PER_PLAYER = 5 

var is_damage_effect_running: bool = false
var is_invincible: bool = false
const I_FRAME_DURATION = 0.1 

func _ready() -> void:
	current_health = max_health
	pass

func apply_damage(amount: int) -> void:
	if is_invincible or current_health <= 0:
		return
	
	set_current_health(current_health - amount)
	

	is_invincible = true
	get_tree().create_timer(I_FRAME_DURATION).timeout.connect(func(): is_invincible = false)

	if not is_damage_effect_running:
		trigger_damage_effect()

func heal(amount: int) -> void:
	set_current_health(current_health + amount)

func set_current_health(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	emit_signal("health_changed", current_health, max_health)
	if current_health == 0:
		_start_death_sequence()

func _start_death_sequence() -> void:
	Engine.time_scale = 0.5

	var fade_to_black := ColorRect.new()
	fade_to_black.color = Color(0, 0, 0, 0)
	fade_to_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().current_scene.add_child(fade_to_black)

	var tween := create_tween()
	tween.tween_property(fade_to_black, "color:a", 1.0, 1.0)
	tween.finished.connect(func():
		Engine.time_scale = 1.0
		if get_tree().root.has_meta("player_positions"):
			get_tree().root.remove_meta("player_positions")
		get_tree().change_scene_to_file("res://Scenes/deathscreen/deathscreen.tscn")
	)


func trigger_damage_effect() -> void:
	is_damage_effect_running = true

	var root = get_tree().current_scene
	if root != null:
		var flash := ColorRect.new()
		flash.color = Color(1, 0, 0, 0.4) 
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(flash)
		var tween := get_tree().create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.3)
		tween.finished.connect(flash.queue_free)

	var original_scale := Engine.time_scale
	Engine.time_scale = 0.5
	var timer := get_tree().create_timer(0.3, true) 
	await timer.timeout
	
	if abs(Engine.time_scale - 0.5) < 0.01:
		Engine.time_scale = original_scale
	
	is_damage_effect_running = false

func add_item_to_player(player_num: int, item_data) -> void:
	var items_array = player1_items if player_num == 1 else player2_items
	if items_array.size() < MAX_ITEMS_PER_PLAYER:
		items_array.append(item_data)
		emit_signal("items_changed")

func get_player_items(player_num: int) -> Array:
	return player1_items if player_num == 1 else player2_items

func reset() -> void:
	set_current_health(max_health)
	player1_items.clear()
	player2_items.clear()
	emit_signal("health_changed", current_health, max_health)
	emit_signal("items_changed")
