extends Node2D

class_name Block # techically a tetromino

const BLOCK_SIZE = 8

@export var block_string: String = ""
@export var block_texture: Texture = null

var block_tile_offsets: Array
var tile_pos: Vector2i
var graphics: Array[Node]
var letter_offsets: Dictionary
var moved: bool = false

signal block_placed

func _ready():
	block_tile_offsets = parse_block_tile_offsets_from_block_string(block_string)
	
	for offset in block_tile_offsets:
		letter_offsets[offset] = GameMaster.get_random_weighted_letter()
	generate_graphics(block_tile_offsets, letter_offsets)
	
	GameMaster.tile_move_down.connect(on_tile_move_down)
	
	tile_pos = Vector2i(
		GameMaster.GRID_WIDTH / 2,
		0
	)
	update_global_position()

func _process(delta):
	if Input.is_action_just_pressed("move_left"):
		if !check_direction_solid(Vector2.LEFT):
			tile_pos.x -= 1
			update_global_position()
	if Input.is_action_just_pressed("move_right"):
		if !check_direction_solid(Vector2.RIGHT):
			tile_pos.x += 1
			update_global_position()
			
	if Input.is_action_just_pressed("move_up"):
		var right_rotated_offsets = rotate_right(block_tile_offsets)
		if !check_offsets_solid(right_rotated_offsets):
			block_tile_offsets = right_rotated_offsets
			letter_offsets = rotate_letters_right(letter_offsets)
			clear_graphics()
			generate_graphics(block_tile_offsets, letter_offsets)

func check_direction_solid(direction: Vector2i) -> bool:
	for offset in block_tile_offsets:
		var off_tile_pos = tile_pos + offset
		#if tile_pos.y == GameMaster.GRID_HEIGHT - 1:
			## hit the bottom
			#place_self()
			
		if GameMaster.is_tile_solid(off_tile_pos + direction):
			return true
			
	return false

func check_offsets_solid(offsets: Array) -> bool:
	for offset in offsets:
		var off_tile_pos = tile_pos + offset
		#if tile_pos.y == GameMaster.GRID_HEIGHT - 1:
			## hit the bottom
			#place_self()
			
		if GameMaster.is_tile_solid(off_tile_pos):
			return true
			
	return false

func rotate_left(offsets):
	var rotated = []
	for offset in offsets:
		rotated.append(Vector2i(offset.y, -offset.x))
	return rotated

func rotate_right(offsets): # hi gus, make the letters apply to the grid visuals :)
	var rotated = []
	for offset in offsets:
		rotated.append(Vector2i(-offset.y, offset.x))
	return rotated

func rotate_letters_right(letters):
	var rotated = {}
	for offset in letters.keys():
		rotated[Vector2i(-offset.y, offset.x)] = letters[offset]
	return rotated

func set_block_string(string):
	block_string = string
	
func set_block_texture(texture):
	block_texture = texture

func update_global_position():
	position = GameMaster.get_global_position_from_tile_pos(tile_pos)
	
func on_tile_move_down():
	try_move_down()
	
func generate_graphics(block_tile_offsets, letter_offsets):
	for offset in block_tile_offsets:
		var sprite = Sprite2D.new()
		sprite.texture = block_texture
		sprite.centered = false
		sprite.position = offset * BLOCK_SIZE
		add_child(sprite)
		graphics.append(sprite)
		
	for letter_offset in letter_offsets.keys():
		var letter_sprite = Sprite2D.new()
		letter_sprite.texture = GameMaster.get_letter_texture(letter_offsets[letter_offset])
		letter_sprite.centered = false
		letter_sprite.position = letter_offset * BLOCK_SIZE
		add_child(letter_sprite)
		graphics.append(letter_sprite)
		
func clear_graphics():
	for sprite in graphics:
		sprite.queue_free()
	graphics.clear()

func parse_block_tile_offsets_from_block_string(string: String):
	var top_left_offset = Vector2i(
		-string[0].to_int(), -string[1].to_int()
	)
	var new_tile_pos = top_left_offset
	var offsets = []
	for character in string.substr(2):
		if character == "@":
			offsets.append(new_tile_pos)
			new_tile_pos.x += 1
		
		elif character == ",":
			new_tile_pos.y += 1
			new_tile_pos.x = top_left_offset.x
		
		elif character == "_":
			new_tile_pos.x += 1
		
		else:
			printerr("Invalid block string char '{}'".format([character]))
		
	return offsets

func try_move_down():
	if check_direction_solid(Vector2i.DOWN):
		place_self()
		if !moved:
			GameMaster.stop_game()
		return
	
	tile_pos.y += 1
	update_global_position()
	moved = true
	
func place_self():
	for offset in block_tile_offsets:
		var tile_pos = tile_pos + offset
		GameMaster.place_tile(tile_pos, {
			solid = true,
			texture = block_texture,
			letter = letter_offsets[offset]
		})
		
	block_placed.emit()
	AudioMan.play_random_pitched(preload("res://block/block_click.mp3"))
	
	queue_free()
