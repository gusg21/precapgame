extends Node

func play(sound):
	var player = AudioStreamPlayer.new()
	player.stream = sound
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
