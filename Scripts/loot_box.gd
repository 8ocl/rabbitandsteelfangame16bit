extends Damageable

@onready var health_bar: TextureProgressBar = get_node_or_null("HealthBar")
@onready var normal_sprite: Node2D = get_node_or_null("Normal")
@onready var broken_piece_1: Node2D = get_node_or_null("BrokenParts/Piece1")
@onready var broken_piece_2: Node2D = get_node_or_null("BrokenParts/Piece2")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

const LOOT_BOX_UI_SCENE: PackedScene = preload("res://Scenes/ui/loot_box_ui.tscn")

var _is_broken: bool = false
var _piece1_velocity: Vector2 = Vector2.ZERO
var _piece2_velocity: Vector2 = Vector2.ZERO
var _gravity: float = 400.0

func _ready() -> void:
	# Initialize Damageable base (health, groups, etc.).
	super()
	# Setup health bar to reflect current health.
	if health_bar != null:
		health_bar.min_value = 0.0
		health_bar.max_value = max_health
		_update_health_bar()

func apply_damage(amount: float, is_crit: bool = false) -> void:
	if _is_broken:
		return
	# Let Damageable handle health, damage numbers, retaliation, death callback.
	super(amount, is_crit)
	_update_health_bar()

func _update_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.value = clamp(current_health, 0.0, max_health)

func _die() -> void:
	# Override Damageable _die so we can play break animation instead of instant queue_free.
	if _is_broken:
		return
	_is_broken = true
	# Disable further collisions and hide health bar / normal sprite.
	if collision_shape != null:
		collision_shape.disabled = true
	if health_bar != null:
		health_bar.visible = false
	if normal_sprite != null:
		normal_sprite.visible = false
	# Show broken pieces and give them an initial "explosion" velocity.
	if broken_piece_1 != null:
		broken_piece_1.visible = true
		_piece1_velocity = Vector2(-80, -220)
	if broken_piece_2 != null:
		broken_piece_2.visible = true
		_piece2_velocity = Vector2(80, -240)
	# Spawn the loot box UI so players can choose upgrades.
	_spawn_loot_box_ui()
	# Clean up the loot box node after pieces have flown off-screen for a bit.
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if not _is_broken:
		return
	# Simple gravity simulation for broken pieces.
	_piece1_velocity.y += _gravity * delta
	_piece2_velocity.y += _gravity * delta
	if broken_piece_1 != null:
		broken_piece_1.position += _piece1_velocity * delta
	if broken_piece_2 != null:
		broken_piece_2.position += _piece2_velocity * delta

func _spawn_loot_box_ui() -> void:
	if LOOT_BOX_UI_SCENE == null:
		return
	var ui := LOOT_BOX_UI_SCENE.instantiate()
	if ui == null:
		return
	# Add the UI to the current scene and position it at the loot box location.
	var root := get_tree().current_scene
	root.add_child(ui)
	if ui is Node2D:
		var node2d := ui as Node2D
		node2d.global_position = global_position
	# Optionally tell the UI that the loot box has spawned it.
	if "initialize_from_loot_box" in ui:
		ui.initialize_from_loot_box(global_position)
