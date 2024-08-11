extends Node2D

var mouse_over: bool = false
var tile_pos: Vector2i

var selection_textures = {
	GameMaster.BombType.NORMAL: preload("res://grid/selection-normal.png"),
	GameMaster.BombType.SUPER: preload("res://grid/selection-super.png"),
	GameMaster.BombType.ULTRA: preload("res://grid/selection-ultra.png"),
	GameMaster.BombType.MASTER: preload("res://grid/selection-master.png"), 
}

func set_tile_pos(pos: Vector2i):
	tile_pos = pos

func _on_area_2d_mouse_entered():
	if Game.master.get_mode() == GameMaster.GameMode.WORDSEARCH:
		mouse_over = true


func _on_area_2d_mouse_exited():
	if Game.master.get_mode() == GameMaster.GameMode.WORDSEARCH:
		mouse_over = false

func can_click():
	return Game.master.get_mode() == GameMaster.GameMode.WORDSEARCH

func _process(delta):
	if Game.master.is_bomb_placing():
		$Sprite2D.texture = selection_textures[Game.master.bomb_placing_type]
	else:
		$Sprite2D.texture = preload("res://grid/selection.png")
	
	if mouse_over and Game.master.get_mode() == GameMaster.GameMode.WORDSEARCH and can_click():
		if Game.master.is_bomb_placing():
			if Input.is_action_just_pressed("selection"):
				Game.master.do_bomb_at(tile_pos)
		else:
			if Input.is_action_just_pressed("selection") and !Game.master.is_selecting():
				Game.master.begin_selection(tile_pos)
			elif Input.is_action_pressed("selection") and Game.master.is_selecting():
				Game.master.set_selection_end(tile_pos)
	
	$Sprite2D.visible = ((mouse_over and !Game.master.is_selecting()) or \
						(Game.master.is_selecting() and Game.master.is_tile_pos_in_selection(tile_pos))) and can_click()
