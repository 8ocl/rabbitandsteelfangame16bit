extends Node2D

@export var lifespan := 2.0 # How long the slice lasts before disappearing

var _area: Area2D
var _safe_spots: Array[Node2D] = []

func _ready():
	_area = $Area2D

	# Look for SafeSpots in the current arena
	var arena := get_tree().current_scene
	if arena.has_node("SafeSpots"):
		var safe_root := arena.get_node("SafeSpots")
		_safe_spots = safe_root.get_children()

	# Start lifespan timer
	var t = get_tree().create_timer(lifespan)
	t.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Check collision with all safe spots
	for safe in _safe_spots:
		if safe and _area.global_position.distance_to(safe.global_position) < 160.0:
			queue_free()
			return
