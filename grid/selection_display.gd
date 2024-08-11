extends Label


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Game.master.is_selecting() and Game.master.get_mode() == GameMaster.GameMode.WORDSEARCH:
		var words = Game.master.get_selected_words()
		if words[0] != words[1]:
			text = words[0] + "\n" + words[1]
		else:
			text = words[0]
		$ValidWord.visible = text.length() > 0
		if Game.master.is_word(words[0]) or Game.master.is_word(words[1]):
			$ValidWord.texture = preload("res://grid/check.png")
		else:
			$ValidWord.texture = preload("res://grid/x.png")
	else:
		$ValidWord.visible = false
		text = ""
