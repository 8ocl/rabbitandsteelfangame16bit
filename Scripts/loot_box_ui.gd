extends Node2D

# Data structure for one upgrade.
# Fields:
#   id:           unique string id
#   name:         short name
#   description:  multi-line description for the label
#   category:     e.g. "move", "damage", "attack_speed", "cooldown", "crit", "defense"
#   value:        numeric magnitude (for later when you actually apply stats)

const UPGRADES: Array = [
	# Movement speed
	{
		"id": "move_speed_10",
		"name": "Red Haired Shoes",
		"description": "+10% movement",
		"category": "move",
		"value": 0.10,
	},
	{
		"id": "move_speed_20",
		"name": "Red Socked Laces",
		"description": "+20% movement",
		"category": "move",
		"value": 0.20,
	},
	{
		"id": "move_speed_30",
		"name": "Blue Candy",
		"description": "+30% movement speed",
		"category": "move",
		"value": 0.30,
	},
	{
		"id": "accel_boost",
		"name": "Rocket Soles",
		"description": "+25% acceleration",
		"category": "move",
		"value": 0.25,
	},

	# Base damage
	{
		"id": "damage_10",
		"name": "Broken Cellphone",
		"description": "+10% base damage",
		"category": "damage",
		"value": 0.10,
	},
	{
		"id": "damage_20",
		"name": "Red Swan",
		"description": "+20% base damage",
		"category": "damage",
		"value": 0.20,
	},
	{
		"id": "damage_30",
		"name": "Ego Day",
		"description": "+30% base damage",
		"category": "damage",
		"value": 0.30,
	},
	{
		"id": "aoe_splash",
		"name": "Splash Rounds",
		"description": "Slight splash on hit (for later)",
		"category": "damage",
		"value": 1.0,
	},

	# Attack speed / cooldown
	{
		"id": "primary_cd_10",
		"name": "Quick Trigger",
		"description": "-10% primary cooldown",
		"category": "attack_speed",
		"value": 0.10,
	},
	{
		"id": "primary_cd_20",
		"name": "Trigger on Trigger",
		"description": "-20% primary cooldown",
		"category": "attack_speed",
		"value": 0.20,
	},
	{
		"id": "primary_cd_30",
		"name": "Bullet Storm",
		"description": "-30% primary cooldown",
		"category": "attack_speed",
		"value": 0.30,
	},
	{
		"id": "global_cd_15",
		"name": "Battle Dancer",
		"description": "-15% global cooldown",
		"category": "cooldown",
		"value": 0.15,
	},

	# Crit
	{
		"id": "crit_chance_5",
		"name": "Lucky Charm",
		"description": "+5% crit chance",
		"category": "crit",
		"value": 0.05,
	},
	{
		"id": "crit_chance_10",
		"name": "Four-Leaf Clover",
		"description": "+10% crit chance",
		"category": "crit",
		"value": 0.10,
	},
	{
		"id": "crit_mult_25",
		"name": "Fatal Edge",
		"description": "+25% crit damage",
		"category": "crit",
		"value": 0.25,
	},
	{
		"id": "crit_mult_50",
		"name": "Executioner",
		"description": "+50% crit damage",
		"category": "crit",
		"value": 0.50,
	},

	# Defense / health
	{
		"id": "max_hp_1",
		"name": "Extra Heart",
		"description": "+1 max health",
		"category": "defense",
		"value": 1.0,
	},
	{
		"id": "max_hp_2",
		"name": "Big Heart",
		"description": "+2 max health",
		"category": "defense",
		"value": 2.0,
	},
	{
		"id": "invuln_05",
		"name": "Thin Shield",
		"description": "+0.5s invulnerability on orb",
		"category": "defense",
		"value": 0.5,
	},
	{
		"id": "invuln_10",
		"name": "Thick Shield",
		"description": "+1.0s invulnerability on orb",
		"category": "defense",
		"value": 1.0,
	},
]

@onready var items_root: Node2D = $Items
@onready var item_nodes: Array = []

var _displayed_upgrades: Array = []          # chosen upgrades (one per item)
var _item_player_chosen: Array = []          # index -> player name who stepped on it
var _player_choices: Dictionary = {}         # player name -> upgrade Dictionary
var preventaccidentalitem: bool = true

func _ready() -> void:
	randomize()
	item_nodes = items_root.get_children()
	_item_player_chosen.resize(item_nodes.size())
	for i in range(item_nodes.size()):
		_item_player_chosen[i] = ""
	_pick_random_upgrades()
	_refresh_ui()
	# Defer pickup area creation so we don't modify physics state while queries are flushing.
	call_deferred("_create_pickup_areas")
	_store_choices_to_root() # store initial empty state
	# Small delay before enabling picks so overlapping players don't auto-pick.
	get_tree().create_timer(0.2).timeout.connect(
		func() -> void:
			preventaccidentalitem = false
	)
func initialize_from_loot_box(origin: Vector2) -> void:
	# Allow the loot box to optionally reposition the UI.
	global_position = origin

func _pick_random_upgrades() -> void:
	_displayed_upgrades.clear()
	var indices = []
	for i in range(UPGRADES.size()):
		indices.append(i)
	indices.shuffle()
	var count = min(item_nodes.size(), indices.size())
	for i in range(count):
		_displayed_upgrades.append(UPGRADES[indices[i]])

func _refresh_ui() -> void:
	for i in range(item_nodes.size()):
		var item = item_nodes[i]
		if i >= _displayed_upgrades.size():
			continue
		var upg: Dictionary = _displayed_upgrades[i]
		var name_label: Label = item.get_node_or_null("Name")
		var desc_label: Label = item.get_node_or_null("Name/Description")
		var face: AnimatedSprite2D = item.get_node_or_null("AnimatedSprite2D")
		var player_name = _item_player_chosen[i]
		# Short text: name in Name label, description in Description label.
		if name_label != null:
			name_label.text = String(upg.get("name", "Upgrade"))
		if desc_label != null:
			desc_label.text = String(upg.get("description", ""))
		# Text color based on upgrade category.
		var cat = String(upg.get("category", ""))
		var col = _get_upgrade_color(cat)
		if name_label != null:
			name_label.add_theme_color_override("font_color", col)
		if desc_label != null:
			desc_label.add_theme_color_override("font_color", col)
		# Update face animation based on who chose this item.
		if face != null:
			var anim_name = "noone"
			if player_name == "player1":
				anim_name = "tetoface"
			elif player_name == "player2":
				anim_name = "mikuface"
			face.play(anim_name)

func _create_pickup_areas() -> void:
	for i in range(item_nodes.size()):
		var item = item_nodes[i]
		# Create an Area2D on each item so players can walk over them.
		var area := Area2D.new()
		area.name = "PickupArea"
		# Only listen for collisions with players (character layer = 2 -> bit 2).
		# This way bullets and other areas pass through without interacting.
		area.collision_layer = 0
		area.collision_mask = 1 << 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.extents = Vector2(20, 20)
		shape.shape = rect
		area.add_child(shape)
		item.add_child(area)
		area.body_entered.connect(_on_item_body_entered.bind(i))

func _on_item_body_entered(body: Node, item_index: int) -> void:
	if not body.is_in_group("players"):
		return
	if item_index < 0 or item_index >= _displayed_upgrades.size():
		return
	if preventaccidentalitem:
		return
	var player_name = body.name
	# Each player can only have one item at a time, but they can change it.
	for i in range(_item_player_chosen.size()):
		if _item_player_chosen[i] == player_name:
			_item_player_chosen[i] = ""
	# Assign this item to the player (last touch wins for the item).
	_item_player_chosen[item_index] = player_name
	_rebuild_player_choices_from_items()
	_refresh_ui()
	_store_choices_to_root()

func _store_choices_to_root() -> void:
	# Persist choices on the SceneTree root so GoToLevelOne / future scenes can read them.
	var root := get_tree().root
	var per_item: Dictionary = {}
	for i in range(_item_player_chosen.size()):
		var player_name = _item_player_chosen[i]
		if player_name == "":
			continue
		per_item[i] = {
			"player": player_name,
			"upgrade": _displayed_upgrades[i],
		}
	var per_player: Dictionary = {}
	for player_name in _player_choices.keys():
		per_player[player_name] = _player_choices[player_name]
	var payload := {
		"per_item": per_item,
		"per_player": per_player,
	}
	root.set_meta("loot_box_choices", payload)

func _rebuild_player_choices_from_items() -> void:
	_player_choices.clear()
	for i in range(_item_player_chosen.size()):
		var player_name = _item_player_chosen[i]
		if player_name == "":
			continue
		if i >= 0 and i < _displayed_upgrades.size():
			_player_choices[player_name] = _displayed_upgrades[i]

func debug_print_choices() -> void:
	# Helper you can call from the console if needed.
	print("LootBoxUI choices per player:")
	for player_name in _player_choices.keys():
		var upg: Dictionary = _player_choices[player_name]
		print("  ", player_name, "->", upg.get("name", upg.get("id", "?")))

func _get_upgrade_color(category: String) -> Color:
	match category:
		"move":
			return Color(0.6, 0.8, 1.0, 1.0)      # light blue
		"damage":
			return Color(1.0, 0.6, 0.6, 1.0)      # light red
		"attack_speed":
			return Color(1.0, 0.9, 0.6, 1.0)      # light yellow
		"cooldown":
			return Color(0.6, 1.0, 0.9, 1.0)      # teal
		"crit":
			return Color(0.9, 0.7, 1.0, 1.0)      # purple
		"defense":
			return Color(0.7, 1.0, 0.7, 1.0)      # green
		_:
			return Color(1.0, 1.0, 1.0, 1.0)
