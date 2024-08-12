extends Button

func _pressed():
	AudioMan.play(preload("res://utils/button_pressed.mp3"))
	GameMaster.end_word_search()
	
func _process(delta):
	visible = GameMaster.get_mode() == GameMaster.GameMode.WORDSEARCH and !GameMaster.is_selecting() and !GameMaster.is_bomb_placing()
