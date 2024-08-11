extends Node

enum GameMode {
	TETRIS, WORDSEARCH
}

enum Direction {
	VERTICAL, HORIZONTAL, DIAGONAL
}

enum BombType {
	NORMAL, SUPER, ULTRA, MASTER
}

const GRID_WIDTH = 10
const GRID_HEIGHT = 20
const TILE_MOVE_DOWN_SECS: float = 1
const MAX_TETRIS_TURN_COUNT = 5
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
var camera: Camera

var grid: Dictionary
var tile_move_down_timer: Timer # block move down timer. bad name :(
var falling_block: Block = null
var last_down_press_time = 0
var turn_counter = 0
var mode: GameMode = GameMode.TETRIS
var selecting: bool = false
var selection_begin: Vector2i = Vector2i.ZERO
var selection_end: Vector2i = Vector2i.ZERO
var selection_direction: Direction = Direction.VERTICAL
var words: Array = []
var bomb_count: Dictionary = {
	BombType.NORMAL: 3,
	BombType.SUPER: 3,
	BombType.ULTRA: 3,
	BombType.MASTER: 3
}
var bomb_placing: bool = false
var bomb_placing_type: BombType = BombType.NORMAL
var score: int = 0


signal tile_move_down
signal grid_changed(tile_pos: Vector2i)
signal mode_changed(mode: GameMode)
signal score_changed(score: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	var words_file = FileAccess.open("res://utils/words_alpha.txt", FileAccess.READ)
	words = words_file.get_as_text().split("\n")
	
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
	
	
func get_score() -> int:
	return score
	
func add_score(points: int):
	score += points
	score_changed.emit(score)

func get_turn_counter() -> int:
	return turn_counter

func get_random_weighted_letter() -> String:
	var custom_weights = LETTER_FREQUENCIES
	
	var existence_discount_coefficient = 0.9
	for tile in grid.values():
		if tile.solid:
			var new_weight = custom_weights[tile.letter] * existence_discount_coefficient
			custom_weights[tile.letter] = max(new_weight, 0)
	
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

func begin_bomb_placing(bomb_type: BombType):
	bomb_placing = true
	bomb_placing_type = bomb_type

func is_bomb_placing() -> bool:
	return bomb_placing

func cancel_bomb():
	bomb_placing = false

func get_bomb_size():
	var size = 3
	if bomb_placing_type == BombType.NORMAL:
		size = 3
	elif bomb_placing_type == BombType.SUPER:
		size = 5
	elif bomb_placing_type == BombType.ULTRA:
		size = 7
	elif bomb_placing_type == BombType.MASTER:
		size = 9
	return size

func do_bomb_at(tile_pos: Vector2):
	var size = get_bomb_size()
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2i(
				tile_pos.x + x - size / 2,
				tile_pos.y + y - size / 2
			)
			grid[pos] = {
				solid = false,
				texture = null,
				letter = null
			}
			grid_changed.emit(pos)
	
	camera.shake(0.1 * size)
	
	bomb_count[bomb_placing_type] -= 1
	bomb_placing = false

func on_block_placed():
	falling_block.block_placed.disconnect(on_block_placed)
	last_down_press_time = 0 # "hack" to make sure next block doesn't come careening down
	
	add_score(10)
	
	var solid_row_streak = 0
	var block_rows = []
	for offset in falling_block.block_tile_offsets:
		var row = falling_block.tile_pos.y + offset.y
		if row not in block_rows:
			block_rows.append(row)
	for row in block_rows:
		var solid_row = true
		for col in range(GRID_WIDTH):
			if !grid[Vector2i(col, row)].solid:
				solid_row = false
				break
		if solid_row:
			solid_row_streak += 1
		else:
			if solid_row_streak == 1:
				bomb_count[BombType.NORMAL] += 1
			elif solid_row_streak == 2:
				bomb_count[BombType.SUPER] += 1
			elif solid_row_streak == 3:
				bomb_count[BombType.ULTRA] += 1
			elif solid_row_streak == 4:
				bomb_count[BombType.MASTER] += 1
			
			solid_row_streak = 0
			
	if solid_row_streak == 1:
		bomb_count[BombType.NORMAL] += 1
	elif solid_row_streak == 2:
		bomb_count[BombType.SUPER] += 1
	elif solid_row_streak == 3:
		bomb_count[BombType.ULTRA] += 1
	elif solid_row_streak == 4:
		bomb_count[BombType.MASTER] += 1

	decrement_turn_counter()
	if turn_counter > 0 and mode == GameMode.TETRIS:
		falling_block = block_spawner.spawn_random_block()
		falling_block.block_placed.connect(on_block_placed)
	
func decrement_turn_counter():
	turn_counter -= 1
	
	if turn_counter == 0:
		if mode == GameMode.TETRIS:
			mode = GameMode.WORDSEARCH
			turn_counter = MAX_WORDSEARCH_TURN_COUNT
		else:
			mode = GameMode.TETRIS
			turn_counter = MAX_TETRIS_TURN_COUNT
			falling_block = block_spawner.spawn_random_block()
			falling_block.block_placed.connect(on_block_placed)
			
			selecting = false
			selection_begin = Vector2.ZERO
			selection_end = Vector2.ZERO
		
		mode_changed.emit(mode)

func skip_word_search():
	mode = GameMode.TETRIS
	turn_counter = MAX_TETRIS_TURN_COUNT
	falling_block = block_spawner.spawn_random_block()
	falling_block.block_placed.connect(on_block_placed)
	
	mode_changed.emit(mode)

func get_mode() -> GameMode:
	return mode

func is_word(word: String):
	if word.length() < 3:
		return false
	return word.to_lower() in words

func begin_selection(begin_pos: Vector2i):
	selecting = true
	selection_begin = begin_pos
	selection_end = begin_pos

func is_selecting() -> bool:
	return selecting
	
func set_selection_end(end_pos: Vector2i):
	selection_end = end_pos
	
	var divisor: float = abs(selection_end.y - selection_begin.y)
	var ratio: float = 0.0
	if divisor != 0:
		ratio = abs(selection_end.x - selection_begin.x) / divisor
	#print(ratio)
	if ratio > 0.5 and ratio < 2:
		selection_direction = Direction.DIAGONAL
	elif abs(selection_end.x - selection_begin.x) > abs(selection_end.y - selection_begin.y):
		selection_direction = Direction.HORIZONTAL
	else:
		selection_direction = Direction.VERTICAL
	
func end_selection():
	var selected_words = get_selected_words()
	if is_word(selected_words[0]) or is_word(selected_words[1]):
		destroy_selection()
		camera.shake(0.5)
		grid_changed.emit()
		decrement_turn_counter()
	
	selecting = false
	selection_begin = Vector2i.ZERO
	selection_end = Vector2i.ZERO

func destroy_selection():
	if selection_direction == Direction.VERTICAL:
		var x = selection_begin.x
		var top = min(selection_begin.y, selection_end.y)
		var bottom = max(selection_begin.y, selection_end.y)
		for i in range(bottom - top + 1):
			var pos = Vector2i(
				x,
				top + i
			)
			if grid[pos].letter != null:
				grid[pos] = {
					solid = false,
					texture = null,
					letter = null
				}
				grid_changed.emit(pos)
	elif selection_direction == Direction.HORIZONTAL:
		var y = selection_begin.y
		var left = min(selection_begin.x, selection_end.x)
		var right = max(selection_begin.x, selection_end.x)
		for i in range(right - left + 1):
			var pos = Vector2i(
				left + i,
				y
			)
			if grid[pos].letter != null:
				grid[pos] = {
					solid = false,
					texture = null,
					letter = null
				}
				grid_changed.emit(pos)
	elif selection_direction == Direction.DIAGONAL:
		var diff = selection_end - selection_begin
		var length = min(abs(diff.x), abs(diff.y))
		var direction = Vector2i(
			1 if selection_end.x > selection_begin.x else -1,
			1 if selection_end.y > selection_begin.y else -1
		)
		for i in range(length + 1):
			var pos = selection_begin + direction * i
			if grid[pos].letter != null:
				grid[pos] = {
					solid = false,
					texture = null,
					letter = null
				}
				grid_changed.emit(pos)

func get_selected_words() -> Array[String]:
	if selection_direction == Direction.VERTICAL:
		var x = selection_begin.x
		var top = min(selection_begin.y, selection_end.y)
		var bottom = max(selection_begin.y, selection_end.y)
		var word = ""
		for i in range(bottom - top + 1):
			var pos = Vector2i(
				x,
				top + i
			)
			if !grid[pos].solid or grid[pos].letter == null:
				break
			word += grid[pos].letter
		return [word,word.reverse()]
	elif selection_direction == Direction.HORIZONTAL:
		var y = selection_begin.y
		var left = min(selection_begin.x, selection_end.x)
		var right = max(selection_begin.x, selection_end.x)
		var word = ""
		for i in range(right - left + 1):
			var pos = Vector2i(
				left + i,
				y
			)
			if !grid[pos].solid or grid[pos].letter == null:
				break
			word += grid[pos].letter
		return [word,word.reverse()]
	elif selection_direction == Direction.DIAGONAL:
		var diff = selection_end - selection_begin
		var length = min(abs(diff.x), abs(diff.y))
		var direction = Vector2i(
			1 if selection_end.x > selection_begin.x else -1,
			1 if selection_end.y > selection_begin.y else -1
		)
		var word = ""
		for i in range(length + 1):
			var pos = selection_begin + direction * i
			if !grid[pos].solid or grid[pos].letter == null:
				break
			word += grid[pos].letter
		return [word,word.reverse()]
		
	return ["",""]

func is_tile_pos_in_selection(tile_pos: Vector2i) -> bool:
	if selection_direction == Direction.VERTICAL:
		var x = selection_begin.x
		var top = min(selection_begin.y, selection_end.y)
		var bottom = max(selection_begin.y, selection_end.y)
		if tile_pos.x == x and tile_pos.y >= top and tile_pos.y <= bottom:
			return true
		return false
	elif selection_direction == Direction.HORIZONTAL:
		var y = selection_begin.y
		var left = min(selection_begin.x, selection_end.x)
		var right = max(selection_begin.x, selection_end.x)
		if tile_pos.y == y and tile_pos.x >= left and tile_pos.x <= right:
			return true
		return false
	elif selection_direction == Direction.DIAGONAL:
		var diff = selection_end - selection_begin
		var length = min(abs(diff.x) + 1, abs(diff.y) + 1)
		var direction = Vector2i(
			1 if selection_end.x > selection_begin.x else -1,
			1 if selection_end.y > selection_begin.y else -1
		)
		for i in range(length):
			if tile_pos == selection_begin + direction * i:
				return true
		
		return false
		
	return false

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
	
	if Input.is_action_just_released("selection"):
		end_selection()
