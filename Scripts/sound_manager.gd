# sound_manager.gd
extends Node

var sfx_player = AudioStreamPlayer.new()
var music_player = AudioStreamPlayer.new()

func _ready():
	add_child(sfx_player)
	add_child(music_player)

func play_sfx(sound_path, volume_db = 0.0):
	var sound = load(sound_path)
	sfx_player.stream = sound
	sfx_player.volume_db = volume_db
	sfx_player.play()

func play_music(music_path, volume_db = 0.0):
	var music = load(music_path)
	music_player.stream = music
	music_player.volume_db = volume_db
	music_player.play()

func stop_music():
	music_player.stop()

func fade_out_music(duration):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	stop_music()
	music_player.volume_db = 0

func fade_in_music(music_path, duration, volume_db = 0.0):
	var music = load(music_path)
	music_player.stream = music
	music_player.volume_db = -80
	music_player.play()
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", volume_db, duration).set_trans(Tween.TRANS_LINEAR)
