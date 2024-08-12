extends Node2D

func _process(delta):
	for i in range(get_child_count()):
		var child = get_child(i)
		if child is Sprite2D:
			child.texture = preload("res://turntimer/turn_timer_pip.png") \
						if GameMaster.get_mode() == GameMaster.GameMode.TETRIS \
						else preload("res://turntimer/turn_timer_pip_wordsearch.png")
			if i >= GameMaster.turn_counter:
				child.modulate.a = 0.2
			else:
				child.modulate.a = 1
