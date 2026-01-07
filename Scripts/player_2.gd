extends PlayerBase

@onready var primary_cooldown_ui: TextureProgressBar = $UI/Primary/PrimaryCooldown
@onready var defensive_cooldown_ui: TextureProgressBar = $UI/Defensive/DefensiveCooldown

var primary_cooldown_timer: Timer
var secondary_cooldown_timer: Timer
var special_cooldown_timer: Timer
var defensive_cooldown_timer: Timer

func _ready() -> void:
	input_prefix = "2"
	primary_cooldown_timer = Timer.new()
	add_child(primary_cooldown_timer)
	primary_cooldown_timer.one_shot = true

	secondary_cooldown_timer = Timer.new()
	add_child(secondary_cooldown_timer)
	secondary_cooldown_timer.one_shot = true

	special_cooldown_timer = Timer.new()
	add_child(special_cooldown_timer)
	special_cooldown_timer.one_shot = true

	defensive_cooldown_timer = Timer.new()
	add_child(defensive_cooldown_timer)
	defensive_cooldown_timer.one_shot = true
	
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_cooldown_ui()

func _update_cooldown_ui() -> void:
	if primary_cooldown > 0:
		primary_cooldown_ui.value = primary_cooldown_timer.time_left / primary_cooldown * primary_cooldown_ui.max_value
	if defensive_cooldown > 0:
		defensive_cooldown_ui.value = defensive_cooldown_timer.time_left / defensive_cooldown * defensive_cooldown_ui.max_value

func primary_action() -> void:
	# Shoots a projectile towards the closest enemy in group "enemies".
	if projectile_scene == null:
		push_warning("No projectile_scene assigned on %s" % name)
		return

	SoundManager.play_sfx("res://Music/SFX/8-bit-explosion-95847.mp3")
	can_primary = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

	primary_cooldown_timer.start(primary_cooldown)

	var projectile := projectile_scene.instantiate()
	var root := get_tree().current_scene
	root.add_child(projectile)
	projectile.global_position = global_position

	var dir := _get_aim_direction()
	if dir == Vector2.ZERO:
		# Fallback direction if no enemies are found
		dir = Vector2.RIGHT

	_update_facing_from_vector(dir)

	# Preferred path: projectile has an initialize() method
	if projectile.has_method("initialize"):
		projectile.initialize(dir, base_damage, crit_chance, crit_multiplier, self)
	else:
		# Fallback: try to set common fields directly
		if "direction" in projectile:
			projectile.direction = dir
		if "base_damage" in projectile:
			projectile.base_damage = base_damage
		if "crit_chance" in projectile:
			projectile.crit_chance = crit_chance
		if "crit_multiplier" in projectile:
			projectile.crit_multiplier = crit_multiplier
		if "shooter" in projectile:
			projectile.shooter = self

	get_tree().create_timer(primary_cooldown).timeout.connect(
		func() -> void:
			can_primary = true
			_is_on_cooldown = false
	)

func secondary_action() -> void:
	# Shoots a projectile towards the closest enemy in group "enemies".
	if projectile_scene == null:
		push_warning("No projectile_scene assigned on %s" % name)
		return

	SoundManager.play_sfx("res://Music/SFX/8-bit-explosion-95847.mp3")
	can_secondary = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

	secondary_cooldown_timer.start(secondary_cooldown)

	var projectile := projectile_scene.instantiate()
	var root := get_tree().current_scene
	root.add_child(projectile)
	projectile.global_position = global_position

	var dir := _get_aim_direction()
	if dir == Vector2.ZERO:
		# Fallback direction if no enemies are found
		dir = Vector2.RIGHT

	_update_facing_from_vector(dir)

	# Preferred path: projectile has an initialize() method
	if projectile.has_method("initialize"):
		projectile.initialize(dir, base_damage, crit_chance, crit_multiplier, self)
	else:
		# Fallback: try to set common fields directly
		if "direction" in projectile:
			projectile.direction = dir
		if "base_damage" in projectile:
			projectile.base_damage = base_damage
		if "crit_chance" in projectile:
			projectile.crit_chance = crit_chance
		if "crit_multiplier" in projectile:
			projectile.crit_multiplier = crit_multiplier
		if "shooter" in projectile:
			projectile.shooter = self

	get_tree().create_timer(secondary_cooldown).timeout.connect(
		func() -> void:
			can_secondary = true
			_is_on_cooldown = false
	)

func special_action() -> void:
	# Shoots a projectile towards the closest enemy in group "enemies".
	if projectile_scene == null:
		push_warning("No projectile_scene assigned on %s" % name)
		return

	SoundManager.play_sfx("res://Music/SFX/8-bit-explosion-95847.mp3")
	can_special = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

	special_cooldown_timer.start(special_cooldown)

	var projectile := projectile_scene.instantiate()
	var root := get_tree().current_scene
	root.add_child(projectile)
	projectile.global_position = global_position

	var dir := _get_aim_direction()
	if dir == Vector2.ZERO:
		# Fallback direction if no enemies are found
		dir = Vector2.RIGHT

	_update_facing_from_vector(dir)

	# Preferred path: projectile has an initialize() method
	if projectile.has_method("initialize"):
		projectile.initialize(dir, base_damage, crit_chance, crit_multiplier, self)
	else:
		# Fallback: try to set common fields directly
		if "direction" in projectile:
			projectile.direction = dir
		if "base_damage" in projectile:
			projectile.base_damage = base_damage
		if "crit_chance" in projectile:
			projectile.crit_chance = crit_chance
		if "crit_multiplier" in projectile:
			projectile.crit_multiplier = crit_multiplier
		if "shooter" in projectile:
			projectile.shooter = self

	get_tree().create_timer(special_cooldown).timeout.connect(
		func() -> void:
			can_special = true
			_is_on_cooldown = false
	)

func defensive_action() -> void:
	if not can_defensive:
		return

	can_defensive = false
	defensive_cooldown_timer.start(defensive_cooldown)

	_is_invincible = true
	var tween = create_tween()
	tween.tween_property(anim, "modulate:a", 0.3, 0.2)

	get_tree().create_timer(invincible_duration).timeout.connect(
		func() -> void:
			_is_invincible = false
			var tween_back = create_tween()
			tween_back.tween_property(anim, "modulate:a", 1.0, 0.2)
	)

func end_defensive_action() -> void:
	pass
