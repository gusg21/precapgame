extends Button

func _pressed():
	Game.master.cancel_bomb()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	visible = Game.master.is_bomb_placing()
