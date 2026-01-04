extends Damageable

@export_group("Attack")
@export var bullet_scene: PackedScene = preload("res://Scenes/small_bullet.tscn")
@export var idle_time_between_attacks: float = 1.5
@export var windup_duration: float = 0.6
@export var attack_recover_time: float = 0.6
@export var bullets_in_circle: int = 16
@export var bullet_speed: float = 120.0
@export var auto_start_attacking: bool = true

@export_group("Idle Movement")
@export var idle_move_radius: float = 5.0
@export var idle_move_speed: float = 15.0

@export_group("Phase Modifiers")
@export_range(0.0, 1.0, 0.01) var phase2_health_ratio: float = 0.66 # go to phase 2 at 66% HP
@export_range(0.0, 1.0, 0.01) var phase3_health_ratio: float = 0.33 # go to phase 3 at 33% HP
@export var phase2_bullet_multiplier: float = 1.5
@export var phase2_speed_multiplier: float = 1.2
@export var phase3_bullet_multiplier: float = 2.0
@export var phase3_speed_multiplier: float = 1.5

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var bullet_spawn: Node2D = get_node_or_null("BulletSpawnPoint")
@onready var health_bar: TextureProgressBar = get_node_or_null("HealthBar")

enum State { IDLE, WINDUP, ATTACK, RECOVER }
var _state: State = State.IDLE
var _state_timer: float = 0.0
var _idle_center: Vector2
var _idle_target_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	super()
	# Make sure the enemy is in the "enemies" group for auto-aim, etc.
	if not is_in_group("enemies"):
		add_to_group("enemies")
	
	# Setup health bar if present
	if health_bar != null:
		health_bar.min_value = 0.0
		health_bar.max_value = max_health
		_update_health_bar()
	
	# Set up idle hover center
	_idle_center = global_position
	_idle_target_offset = Vector2.ZERO
	
	# Start in idle.
	_set_state(State.IDLE)

func apply_damage(amount: float, is_crit: bool = false) -> void:
	# Let Damageable handle health, damage numbers, retaliation, and death.
	super(amount, is_crit)
	_update_health_bar()

func _process(delta: float) -> void:
	_state_timer += delta
	match _state:
		State.IDLE:
			if auto_start_attacking and _state_timer >= idle_time_between_attacks:
				_set_state(State.WINDUP)
			_update_idle_movement(delta)
		State.WINDUP:
			if _state_timer >= windup_duration:
				_set_state(State.ATTACK)
		State.ATTACK:
			# Fire once on entering ATTACK, then go to RECOVER.
			_perform_circular_attack()
			_set_state(State.RECOVER)
		State.RECOVER:
			if _state_timer >= attack_recover_time:
				_set_state(State.IDLE)
	
	_update_facing_to_players()

func _set_state(new_state: State) -> void:
	_state = new_state
	_state_timer = 0.0
	match _state:
		State.IDLE:
			_play_idle_animation()
		State.WINDUP:
			_play_windup_animation()
		State.ATTACK:
			_play_attack_animation()
		State.RECOVER:
			# After the attack we can go back to idle visuals, or keep attack sprite.
			_play_idle_animation()

func _play_idle_animation() -> void:
	if anim == null:
		return
	if anim.animation != "BossIdle":
		anim.play("BossIdle")

func _play_windup_animation() -> void:
	if anim == null:
		return
	if anim.animation != "BossWindUp":
		anim.play("BossWindUp")

func _play_attack_animation() -> void:
	if anim == null:
		return
	if anim.animation != "BossAttack":
		anim.play("BossAttack")

func _update_idle_movement(delta: float) -> void:
	if idle_move_radius <= 0.0 or idle_move_speed <= 0.0:
		return
	
	# If we somehow lost our center (e.g. scene reparent), reset it
	if _idle_center == Vector2.ZERO:
		_idle_center = global_position
	
	var target: Vector2 = _idle_center + _idle_target_offset
	var to_target: Vector2 = target - global_position
	if to_target.length() < 0.2:
		# Pick a new random offset within the radius
		var angle: float = randf() * TAU
		var dist: float = randf() * idle_move_radius
		_idle_target_offset = Vector2.RIGHT.rotated(angle) * dist
		return
	
	var max_step: float = idle_move_speed * delta
	if to_target.length() <= max_step:
		global_position = target
	else:
		global_position += to_target.normalized() * max_step

func _update_facing_to_players() -> void:
	if anim == null:
		return
	var dir: Vector2 = _get_aim_direction_to_group("players")
	if dir == Vector2.ZERO:
		return
	# Assume default sprite faces right; flip when player is to the left.
	anim.flip_h = dir.x > 0.0

func _get_health_ratio() -> float:
	if max_health <= 0.0:
		return 1.0
	return clamp(current_health / max_health, 0.0, 1.0)

func _update_health_bar() -> void:
	if health_bar == null:
		return
	health_bar.value = clamp(current_health, 0.0, max_health)

func trigger_bullethell_attack_if_above_half() -> void:
	# For Ado we want the pattern itself to stay the same; this helper just
	# triggers whatever _perform_circular_attack() does for the subclass.
	_perform_circular_attack()

func _perform_circular_attack() -> void:
	if bullet_scene == null:
		push_warning("EnemyTemplate has no bullet_scene assigned")
		return
	
	var root := get_tree().current_scene
	if root == null:
		return
	
	var origin: Vector2 = global_position
	if bullet_spawn != null:
		origin = bullet_spawn.global_position
	
	# Choose attack parameters based on current health (phases)
	var health_ratio: float = _get_health_ratio()
	var bullets_for_phase: int = bullets_in_circle
	var speed_for_phase: float = bullet_speed
	if health_ratio <= phase3_health_ratio:
		bullets_for_phase = int(max(1.0, round(bullets_in_circle * phase3_bullet_multiplier)))
		speed_for_phase = bullet_speed * phase3_speed_multiplier
	elif health_ratio <= phase2_health_ratio:
		bullets_for_phase = int(max(1.0, round(bullets_in_circle * phase2_bullet_multiplier)))
		speed_for_phase = bullet_speed * phase2_speed_multiplier
	
	var count: int = max(bullets_for_phase, 1)
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		var dir := Vector2.RIGHT.rotated(angle)
		var bullet := bullet_scene.instantiate()
		root.add_child(bullet)
		if "global_position" in bullet:
			bullet.global_position = origin
		
		# Support the small_bullet.gd API (set_direction) plus generic velocity fields.
		var velocity: Vector2 = dir * speed_for_phase
		if bullet.has_method("set_direction"):
			bullet.set_direction(velocity)
		elif "velocity" in bullet:
			bullet.velocity = velocity
