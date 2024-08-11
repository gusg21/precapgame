extends Button

class_name ShuffleButton

@export var name_label_path: NodePath

@onready var name_label: Label = get_node(name_label_path)

var new_name: String

func _pressed():
	new_name = GameMaster.get_random_weighted_letter() + GameMaster.get_random_weighted_letter() + GameMaster.get_random_weighted_letter()
	name_label.text = new_name[0] + " " + \
					  new_name[1] + " " + \
					  new_name[2]
					
func get_new_name():
	return new_name
