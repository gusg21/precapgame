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
	if mouse_over and GameMaster.get_mode() == GameMaster.GameMode.WORDSEARCH:
		if GameMaster.is_bomb_placing():
			if Input.is_action_just_pressed("selection"):
				GameMaster.do_bomb_at(tile_pos)
		else:
			if Input.is_action_just_pressed("selection") and !GameMaster.is_selecting():
				GameMaster.begin_selection(tile_pos)
			elif Input.is_action_pressed("selection") and GameMaster.is_selecting():
				GameMaster.set_selection_end(tile_pos)
	
	$Sprite2D.visible = (mouse_over and !GameMaster.is_selecting()) or \
						(GameMaster.is_selecting() and GameMaster.is_tile_pos_in_selection(tile_pos))
