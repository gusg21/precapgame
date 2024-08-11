extends Button

func _ready():
	$AnimationPlayer.play_backwards("fade_out")

func _pressed():
	$AnimationPlayer.play("fade_out")
	$AnimationPlayer.animation_finished.connect(on_animation_done)
	
func on_animation_done(a):
	get_tree().change_scene_to_packed(preload("res://main/main.tscn"))
	
