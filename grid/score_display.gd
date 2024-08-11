extends RichTextLabel

const TYPING_SPEED = 15

var target_text: String = ""
var deleting = false
var visible_characters_float: float

# Called when the node enters the scene tree for the first time.
func _ready():
	Game.master.score_changed.connect(on_score_changed)
	visible_characters_float = visible_characters
	
	text = "zero points"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if deleting and visible_characters > 0:
		visible_characters_float -= delta * TYPING_SPEED
		visible_characters = floor(visible_characters_float)
	elif deleting and visible_characters == 0:
		text = target_text
		deleting = false
	elif !deleting and visible_characters < get_total_character_count():
		visible_characters_float += delta * TYPING_SPEED * 0.7
		visible_characters = floor(visible_characters_float)

func on_score_changed(new_score):
	var score = Game.master.get_score()
	if score == 1:
		target_text = NumberToWords.to_words(score) + " point"
	else:
		target_text = NumberToWords.to_words(score) + " points"
		
	deleting = true
