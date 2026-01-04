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

var _displayed_upgrades: Array = []
var _item_player_chosen: Array = []
var preventaccidentalitem: bool = true

func _ready() -> void:
	randomize()
	item_nodes = items_root.get_children()
	_item_player_chosen.resize(item_nodes.size())
	for i in range(item_nodes.size()):
		_item_player_chosen[i] = ""
	_pick_random_upgrades()
	_refresh_ui()
	call_deferred("_create_pickup_areas")
	get_tree().create_timer(0.2).timeout.connect(
		func() -> void:
			preventaccidentalitem = false
	)

func initialize_from_loot_box(origin: Vector2) -> void:
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
		var item_image: Sprite2D = item.get_node_or_null("ItemImage")
		var player_name = _item_player_chosen[i]
		
		# Short text: name in Name label, description in Description label.
		if name_label != null:
			name_label.text = String(upg.get("name", "Upgrade"))
		if desc_label != null:
			desc_label.text = String(upg.get("description", ""))
			
		# Update item image. A texture_path can be added to the UPGRADES entry.
		if item_image and upg.has("texture_path"):
			item_image.texture = load(upg.get("texture_path"))
			
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
		var area := Area2D.new()
		area.name = "PickupArea"
		area.collision_layer = 0
		area.collision_mask = 1 << 1
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
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
	
	var item_node = item_nodes[item_index]
	if item_node.has_meta("taken") and item_node.get_meta("taken"):
		return

	var player_name = body.name
	var player_num = 1 if player_name == "player1" else 2
	var item_data = _displayed_upgrades[item_index].duplicate()

	if not item_data.has("texture_path"):
		item_data["texture_path"] = "res://icon.svg"
	
	GlobalState.add_item_to_player(player_num, item_data)
	
	item_node.set_meta("taken", true)
	
	_item_player_chosen[item_index] = player_name
	_refresh_ui()

	var pickup_area = item_node.get_node("PickupArea")
	if pickup_area:
		pickup_area.get_node("CollisionShape2D").set_deferred("disabled", true)

func _get_upgrade_color(category: String) -> Color:
	match category:
		"move":
			return Color(0.6, 0.8, 1.0, 1.0)
		"damage":
			return Color(1.0, 0.6, 0.6, 1.0)
		"attack_speed":
			return Color(1.0, 0.9, 0.6, 1.0)
		"cooldown":
			return Color(0.6, 1.0, 0.9, 1.0)
		"crit":
			return Color(0.9, 0.7, 1.0, 1.0)
		"defense":
			return Color(0.7, 1.0, 0.7, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)
