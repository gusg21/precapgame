extends Button

func _pressed():
	Game.master.skip_word_search()
	
func _process(delta):
	visible = Game.master.get_mode() == GameMaster.GameMode.WORDSEARCH and !Game.master.is_selecting() and !Game.master.is_bomb_placing()
