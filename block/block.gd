extends Node2D

class_name Block # techically a tetromino

const BLOCK_SIZE = 8

@export var block_string: String = ""
@export var block_texture: Texture = null

var block_tile_offsets: Array
var tile_pos: Vector2i

signal block_placed

func _ready():
	block_tile_offsets = parse_block_tile_offsets_from_block_string(block_string)
	
	generate_graphics(block_tile_offsets)
	
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

func check_direction_solid(direction: Vector2i) -> bool:
	for offset in block_tile_offsets:
		var off_tile_pos = tile_pos + offset
		#if tile_pos.y == GameMaster.GRID_HEIGHT - 1:
			## hit the bottom
			#place_self()
			
		if GameMaster.is_tile_solid(off_tile_pos + direction):
			return true
			
	return false

func set_block_string(string):
	block_string = string

func update_global_position():
	global_position = GameMaster.get_global_position_from_tile_pos(tile_pos)
	
func on_tile_move_down():
	try_move_down()
	
func generate_graphics(block_tile_offsets):
	for offset in block_tile_offsets:
		var sprite = Sprite2D.new()
		sprite.texture = block_texture
		sprite.centered = false
		sprite.position = offset * BLOCK_SIZE
		add_child(sprite)

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
		return
	
	tile_pos.y += 1
	update_global_position()
	
func place_self():
	for offset in block_tile_offsets:
		var tile_pos = tile_pos + offset
		GameMaster.place_tile(tile_pos, {
			solid = true,
			texture = block_texture,
			letter = null
		})
		
	block_placed.emit()
	
	queue_free()
