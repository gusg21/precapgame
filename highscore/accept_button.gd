extends Button

@export var results_path: NodePath
var results: ShuffleButton

func _ready():
	results = get_node(results_path)

func _pressed():
	GameMaster.add_high_score(results.get_new_name(), GameMaster.get_score())
	get_tree().change_scene_to_packed(preload("res://results/results.tscn"))
