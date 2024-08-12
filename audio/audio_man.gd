extends Node

var music
var target_hz = 0.0
var low_hz = 0.0
var high_hz = 20000.0
var target_wet = 0.0
var low_wet = 0.0
var high_wet = 0.27

var speed = 0.004

func _ready():
	low_hz = (AudioServer.get_bus_effect(AudioServer.get_bus_index(&"Music"), 0) as AudioEffectLowPassFilter).cutoff_hz
	target_hz = low_hz
	
	target_wet = high_wet
	
	music = AudioStreamPlayer.new()
	music.stream = preload("res://audio/Caving_80.ogg")
	music.bus = &"Music"
	music.volume_db = linear_to_db(0.5)
	add_child(music)
	music.play()

func play(sound):
	var player = AudioStreamPlayer.new()
	player.stream = sound
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	
func play_quieter(sound):
	var player = AudioStreamPlayer.new()
	player.stream = sound
	player.volume_db = linear_to_db(0.5)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_louder(sound):
	var player = AudioStreamPlayer.new()
	player.stream = sound
	player.volume_db = linear_to_db(2)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func play_random_pitched(sound):
	var player = AudioStreamPlayer.new()
	player.stream = sound
	player.pitch_scale = randf_range(0.8, 1.3)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _physics_process(delta):
	var lp_filter = AudioServer.get_bus_effect(AudioServer.get_bus_index(&"Music"), 0) as AudioEffectLowPassFilter
	lp_filter.cutoff_hz = lerp(lp_filter.cutoff_hz, target_hz, speed)
	
	var verb = AudioServer.get_bus_effect(AudioServer.get_bus_index(&"Music"), 1) as AudioEffectReverb
	verb.wet = lerp(verb.wet, target_wet, speed)

func open_filter():
	target_hz = high_hz
	target_wet = low_wet
	speed = 0.004

func close_filter():
	target_hz = low_hz
	target_wet = high_wet
	speed = 0.01
