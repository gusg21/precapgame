extends Button

func _pressed():
	GameMaster.cancel_bomb()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	visible = GameMaster.is_bomb_placing()
