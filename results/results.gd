extends Node2D

class_name Results

func _enter_tree():
	GameMaster.stop_game()
	$AnimationPlayer.play("reveal")

func unreveal():
	$AnimationPlayer.play_backwards("reveal")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_packed(preload("res://main/main.tscn"))
