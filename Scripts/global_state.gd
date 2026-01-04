extends Node

signal health_changed(current_health, max_health)
signal items_changed

var max_health: int = 6
var current_health: int = max_health:
	set(value):
		current_health = clamp(value, 0, max_health)
		emit_signal("health_changed", current_health, max_health)
		if current_health == 0:
			# Handle game over logic
			print("Game Over")


var player1_items: Array = []
var player2_items: Array = []

const MAX_ITEMS_PER_PLAYER = 5 # Assuming 5 slots per player

func _ready() -> void:
	# This singleton persists across scene changes.
	pass

func apply_damage(amount: int) -> void:
	self.current_health -= amount

func heal(amount: int) -> void:
	self.current_health += amount

func add_item_to_player(player_num: int, item_data) -> void:
	var items_array = player1_items if player_num == 1 else player2_items
	if items_array.size() < MAX_ITEMS_PER_PLAYER:
		items_array.append(item_data)
		emit_signal("items_changed")

func get_player_items(player_num: int) -> Array:
	return player1_items if player_num == 1 else player2_items

func reset() -> void:
	self.current_health = max_health
	player1_items.clear()
	player2_items.clear()
	emit_signal("health_changed", current_health, max_health)
	emit_signal("items_changed")
