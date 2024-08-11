extends Button

func _pressed():
	AudioMan.play(preload("res://utils/button_pressed.mp3"))
	get_tree().quit()
