extends Node2D

@onready var teto_sprite: Sprite2D = $Teto

var time_passed: float = 0.0
var initial_y: float = 0.0

func _ready() -> void:
	if teto_sprite:
		initial_y = teto_sprite.position.y

func _process(delta: float) -> void:
	time_passed += delta
	if teto_sprite:
		# Smoothly move Teto sprite up and down using a sine wave
		teto_sprite.position.y = initial_y + sin(time_passed * 2.0) * 2.0
