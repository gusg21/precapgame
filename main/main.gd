extends Node2D

func _ready():
	GameMaster.start_game.call_deferred()
