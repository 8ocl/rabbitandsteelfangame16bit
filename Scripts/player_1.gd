extends PlayerBase

# Player 1 uses the shared PlayerBase logic.
# Configure in the inspector:
#   - input_prefix = "" (no prefix, uses actions like "move_right")
#   - projectile_scene = your projectile scene (with projectile.gd attached)
#   - base_damage, crit_chance, crit_multiplier as desired

func primary_action() -> void:
	# Shoots a projectile towards the closest enemy in group "enemies".
	if projectile_scene == null:
		push_warning("No projectile_scene assigned on %s" % name)
		return

	can_primary = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

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

	can_secondary = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

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

	can_special = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

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
	# Shoots a projectile towards the closest enemy in group "enemies".
	if projectile_scene == null:
		push_warning("No projectile_scene assigned on %s" % name)
		return

	can_defensive = false
	_trigger_global_cooldown()
	_start_cooldown_ring()

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

	get_tree().create_timer(defensive_cooldown).timeout.connect(
		func() -> void:
			can_defensive = true
			_is_on_cooldown = false
	)

func end_defensive_action() -> void:
	pass
