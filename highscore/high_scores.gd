extends Node2D

@export var show_your_score = true

func _ready():
	$Scores.text = "[center]"
	for high_score in GameMaster.high_scores:
		$Scores.text += (high_score.name + " " + str(high_score.points) + "\n")
	
	if show_your_score:
		$Scores.text += "\nYOUR SCORE\n" + str(GameMaster.get_score())
