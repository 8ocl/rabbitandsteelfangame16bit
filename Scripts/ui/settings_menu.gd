extends Control

func _ready():
	# Initialize sliders with current audio bus volumes
	$VBoxContainer/MasterSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	$VBoxContainer/MusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	$VBoxContainer/SFXSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

func _on_master_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)

func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)

func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
