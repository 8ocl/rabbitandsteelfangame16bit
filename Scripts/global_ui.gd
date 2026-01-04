extends Node2D

@onready var health_sprites_container = $PlayerHealth
@onready var p1_item_slots_container = $PlayerPickups/Miku
@onready var p2_item_slots_container = $PlayerPickups/Teto

var health_sprites: Array
var p1_item_slots: Array
var p2_item_slots: Array

func _ready() -> void:
	# Collect child nodes into arrays
	health_sprites = health_sprites_container.get_children()
	p1_item_slots = p1_item_slots_container.get_children()
	p2_item_slots = p2_item_slots_container.get_children()

	GlobalState.health_changed.connect(_on_health_changed)
	GlobalState.items_changed.connect(_on_items_changed)
	
	# Initialize UI with current state from the singleton
	_on_health_changed(GlobalState.current_health, GlobalState.max_health)
	_on_items_changed()

func _on_health_changed(current_health: int, max_health: int) -> void:
	for i in range(health_sprites.size()):
		health_sprites[i].visible = (i < current_health)

func _on_items_changed() -> void:
	var p1_items = GlobalState.get_player_items(1)
	for i in range(p1_item_slots.size()):
		if i < p1_items.size() and p1_items[i].has("texture_path"):
			var item_texture = load(p1_items[i].texture_path)
			p1_item_slots[i].texture = item_texture
			p1_item_slots[i].visible = true
		else:
			p1_item_slots[i].visible = false

	var p2_items = GlobalState.get_player_items(2)
	for i in range(p2_item_slots.size()):
		if i < p2_items.size() and p2_items[i].has("texture_path"):
			var item_texture = load(p2_items[i].texture_path)
			p2_item_slots[i].texture = item_texture
			p2_item_slots[i].visible = true
		else:
			p2_item_slots[i].visible = false
