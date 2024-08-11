extends Node2D

func _enter_tree():
	$AnimationPlayer.play("RESET")

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioMan.close_filter()
	AudioMan.play(preload("res://grid/fanfare.mp3"))
	$AnimationPlayer.play("reveal")

func unreveal():
	$AnimationPlayer.play_backwards("reveal")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_packed(preload("res://results/results.tscn"))
