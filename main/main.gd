extends Node2D

func _ready():
	AudioMan.open_filter()
	
	GameMaster.start_game.call_deferred()
	$AnimationPlayer.play("reveal")
	
	GameMaster.game_stopped.connect(on_game_stopped)

func on_game_stopped():
	$AnimationPlayer.play("swipe_left")
	await $AnimationPlayer.animation_finished
	GameMaster.end_game()
