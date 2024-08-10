extends Node2D

var mouse_over: bool = false
var tile_pos: Vector2i

func set_tile_pos(pos: Vector2i):
	tile_pos = pos

func _on_area_2d_mouse_entered():
	if GameMaster.get_mode() == GameMaster.GameMode.WORDSEARCH:
		mouse_over = true


func _on_area_2d_mouse_exited():
	if GameMaster.get_mode() == GameMaster.GameMode.WORDSEARCH:
		mouse_over = false

func _process(delta):
	if mouse_over and GameMaster.get_mode() == GameMaster.GameMode.WORDSEARCH and Input.is_action_just_pressed("selection") and !GameMaster.is_selecting():
		GameMaster.begin_selection(tile_pos)
	
	$Sprite2D.visible = mouse_over or (GameMaster.is_selecting() and GameMaster.is_tile_pos_in_selection(tile_pos))
