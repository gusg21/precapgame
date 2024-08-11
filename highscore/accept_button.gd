extends Button

@export var results_path: NodePath
var results: ShuffleButton

func _ready():
	results = get_node(results_path)

func _process(delta):
	disabled = results.get_new_name() == ""

func _pressed():
	AudioMan.play(preload("res://utils/button_pressed.mp3"))
	GameMaster.add_high_score(results.get_new_name(), GameMaster.get_score())
	$"../..".unreveal()
