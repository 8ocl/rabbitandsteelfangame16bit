extends Label

# Simple debug HUD that prints out live info about players and enemies.
# Attach this to the DebugText Label in firstlevel.

func _process(_delta: float) -> void:
	var lines: Array[String] = []
	_update_player_lines(lines)
	_update_enemy_lines(lines)
	text = "\n".join(lines)

func _update_player_lines(lines: Array[String]) -> void:
	var players := get_tree().get_nodes_in_group("players")
	lines.append("PLAYERS:")
	if players.is_empty():
		lines.append("  (none)")
		return
	for p in players:
		if not (p is Node):
			continue
		var name_str := String(p.name)
		var hp_line := "  %s" % name_str
		if "current_health" in p and "max_health" in p:
			var cur_hp := float(p.current_health)
			var max_hp := float(p.max_health)
			hp_line += " HP %.1f/%.1f" % [cur_hp, max_hp]
		if "controls_enabled" in p:
			hp_line += "  ctrl=%s" % ("ON" if p.controls_enabled else "OFF")
		lines.append(hp_line)
		# Spell / cooldown state
		var spells_line := "    Spells: "
		if "can_primary" in p and "primary_cooldown" in p:
			spells_line += "P[%s cd=%.2fs]  " % ["READY" if p.can_primary else "CD", float(p.primary_cooldown)]
		if "can_secondary" in p and "secondary_cooldown" in p:
			spells_line += "S[%s cd=%.2fs]  " % ["READY" if p.can_secondary else "CD", float(p.secondary_cooldown)]
		if "can_special" in p and "special_cooldown" in p:
			spells_line += "X[%s cd=%.2fs]  " % ["READY" if p.can_special else "CD", float(p.special_cooldown)]
		if "can_defensive" in p and "defensive_cooldown" in p:
			spells_line += "D[%s cd=%.2fs]  " % ["READY" if p.can_defensive else "CD", float(p.defensive_cooldown)]
		if "can_cast" in p and "global_cooldown" in p:
			spells_line += "GCD[%s cd=%.2fs]" % ["READY" if p.can_cast else "CD", float(p.global_cooldown)]
		lines.append(spells_line)
		var move_line := "    Move: "
		if "current_speed" in p and "normal_speed" in p and "slow_speed" in p:
			move_line += "cur=%.1f norm=%.1f slow=%.1f" % [float(p.current_speed), float(p.normal_speed), float(p.slow_speed)]
		lines.append(move_line)

func _update_enemy_lines(lines: Array[String]) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	lines.append("")
	lines.append("ENEMIES:")
	if enemies.is_empty():
		lines.append("  (none)")
		return
	for e in enemies:
		if not (e is Node):
			continue
		# Skip players if they also happen to be in this group.
		if e.is_in_group("players"):
			continue
		var name_str := String(e.name)
		var line := "  %s" % name_str
		if "current_health" in e and "max_health" in e:
			line += " HP %.1f/%.1f" % [float(e.current_health), float(e.max_health)]
		lines.append(line)
