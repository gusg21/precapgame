extends Control

@export var enabled_mode: GameMaster.GameMode


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	visible = Game.master.get_mode() == enabled_mode
