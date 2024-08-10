extends Node2D

@export var bg_node_path: NodePath

var bg: Sprite2D
var tetris_tex: Texture2D = preload("res://bg/tetris_bg.png")
var word_tex: Texture2D = preload("res://bg/word_bg.png")

func _ready():
	bg = get_node(bg_node_path)
	
func _process(delta):
	bg.direction.x = 1 if GameMaster.get_mode() == GameMaster.GameMode.TETRIS else -1
	bg.texture = tetris_tex if GameMaster.get_mode() == GameMaster.GameMode.TETRIS else word_tex
