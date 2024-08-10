extends Node

enum GameMode {
	TETRIS, WORDSEARCH
}

const GRID_WIDTH = 10
const GRID_HEIGHT = 20
const TILE_MOVE_DOWN_SECS: float = 1
const MAX_TETRIS_TURN_COUNT = 2
const MAX_WORDSEARCH_TURN_COUNT = 5

var LETTER_FREQUENCIES: Dictionary = {
	"A" = 7.8,
	"B" = 2.0,
	"C" = 4.0,
	"D" = 3.8,
	"E" = 11.0,
	"F" = 1.4,
	"G" = 3.0,
	"H" = 2.3,
	"I" = 8.6,
	"J" = 0.2,
	"K" = 0.9,
	"L" = 5.3,
	"M" = 2.7,
	"N" = 7.2,
	"O" = 6.1,
	"P" = 2.8,
	"Q" = 0.2,
	"R" = 7.3,
	"S" = 8.7,
	"T" = 6.7,
	"U" = 3.3,
	"V" = 1.0,
	"W" = 0.9,
	"X" = 0.3,
	"Y" = 1.6,
	"Z" = 0.4
}

var grid_object: Grid
var block_spawner: BlockSpawner

var grid: Dictionary
var tile_move_down_timer: Timer # block move down timer. bad name :(
var falling_block: Block = null
var last_down_press_time = 0
var turn_counter = 0
var mode: GameMode = GameMode.TETRIS
var selecting: bool = false
var selection_begin: Vector2i = Vector2i.ZERO
var selection_end: Vector2i = Vector2i.ZERO

signal tile_move_down
signal grid_changed(tile_pos: Vector2i)
signal mode_changed(mode: GameMode)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	for letter in LETTER_FREQUENCIES.keys():
		LETTER_FREQUENCIES[letter] = pow(LETTER_FREQUENCIES[letter], 1.5)
	
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			grid[Vector2i(x, y)] = {
				solid = false,
				texture = null,
				letter = null
			}
			grid_changed.emit(Vector2i(x, y))
			
	tile_move_down_timer = Timer.new()
	tile_move_down_timer.wait_time = TILE_MOVE_DOWN_SECS
	tile_move_down_timer.one_shot = false
	tile_move_down_timer.timeout.connect(on_tile_move_down_timer_timeout)
	add_child(tile_move_down_timer)
	tile_move_down_timer.start()
	
	falling_block = block_spawner.spawn_random_block()
	falling_block.block_placed.connect(on_block_placed)
	
	turn_counter = MAX_TETRIS_TURN_COUNT
	
func get_turn_counter() -> int:
	return turn_counter

func get_random_weighted_letter() -> String:
	var weight_sum = 0 
	for weight in LETTER_FREQUENCIES.values():
		weight_sum += weight
	var random_index = randf_range(0, weight_sum)
	for letter in LETTER_FREQUENCIES.keys():
		if random_index < LETTER_FREQUENCIES[letter]:
			return letter
		random_index -= LETTER_FREQUENCIES[letter]
	printerr("Random letter algo error, returning E")
	return "E"

func on_block_placed():
	turn_counter -= 1
	falling_block.block_placed.disconnect(on_block_placed)
	last_down_press_time = 0 # "hack" to make sure next block doesn't come careening down
	
	if turn_counter > 0:
		falling_block = block_spawner.spawn_random_block()
		falling_block.block_placed.connect(on_block_placed)
	else:
		if mode == GameMode.TETRIS:
			mode = GameMode.WORDSEARCH
			turn_counter = MAX_WORDSEARCH_TURN_COUNT
		else:
			mode == GameMode.TETRIS
			turn_counter = MAX_TETRIS_TURN_COUNT
		
		mode_changed.emit(mode)
	
func get_mode() -> GameMode:
	return mode

func begin_selection(begin_pos: Vector2i):
	selecting = true
	selection_begin = begin_pos
	selection_end = begin_pos

func is_selecting() -> bool:
	return selecting
	
func is_tile_pos_in_selection(tile_pos: Vector2i) -> bool:
	return tile_pos.x <= selection_end.x and tile_pos.x >= selection_begin.x and \
		   tile_pos.y <= selection_end.y and tile_pos.y >= selection_begin.y

func on_tile_move_down_timer_timeout():
	tile_move_down.emit()

func is_tile_pos_valid(tile_pos: Vector2i) -> bool:
	return tile_pos.x >= 0 and tile_pos.x < GRID_WIDTH and \
		   tile_pos.y >= 0 and tile_pos.y < GRID_HEIGHT

func is_tile_solid(tile_pos: Vector2i) -> bool:
	if !is_tile_pos_valid(tile_pos):
		#printerr("Invalid solid check on tile pos {},{}".format([tile_pos.x, tile_pos.y]))
		return true
		
	return grid[tile_pos].solid

func get_global_position_from_tile_pos(tile_pos: Vector2i) -> Vector2:
	return grid_object.get_global_position_from_tile_pos(tile_pos)

func place_tile(tile_pos, tile_info):
	if is_tile_pos_valid(tile_pos):
		grid[tile_pos] = tile_info
		grid_changed.emit(tile_pos)

func get_tile_at(tile_pos):
	if is_tile_pos_valid(tile_pos):
		return grid[tile_pos]
	else:
		return null
		
func get_letter_texture(letter: String) -> Texture2D:
	var texture = AtlasTexture.new()
	texture.atlas = preload("res://block/letters.png")
	var letter_index = letter.to_upper().to_ascii_buffer()[0] - "A".to_ascii_buffer()[0]
	texture.region = Rect2((letter_index % 8) * 8, (letter_index / 8) * 8, 8, 8)
	return texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	last_down_press_time += delta
	
	if Input.is_action_just_pressed("move_down"):
		last_down_press_time = 0
		tile_move_down_timer.start()
		on_tile_move_down_timer_timeout()
	
	if last_down_press_time > 0.5 and Input.is_action_pressed("move_down"):
		tile_move_down_timer.start()
		on_tile_move_down_timer_timeout()
