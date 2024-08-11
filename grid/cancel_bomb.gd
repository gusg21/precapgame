extends Button

func _pressed():
	AudioMan.play(preload("res://utils/button_pressed.mp3"))
	GameMaster.cancel_bomb()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	visible = GameMaster.is_bomb_placing()
