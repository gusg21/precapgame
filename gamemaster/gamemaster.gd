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
const MAX_WORDSEARCH_TURN_COUNT = 3

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
var text_pop_host: Node2D

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
var _bomb_count: Dictionary = {
	BombType.NORMAL: 0,
	BombType.SUPER: 0,
	BombType.ULTRA: 0,
	BombType.MASTER: 0
}
var bomb_placing: bool = false
var bomb_placing_type: BombType = BombType.NORMAL
var score: int = 190000
var game_over = false
var high_scores = []
var rounds = 0


signal tile_move_down
signal grid_changed(tile_pos: Vector2i)
signal mode_changed(mode: GameMode)
signal score_changed(score: int)
signal bomb_count_update(bomb_type: BombType, count: int)
signal game_stopped

# Called when the node enters the scene tree for the first time.
func _ready():
	print("initializing gamemaster")
	
	randomize()
	
	var high_score_file = FileAccess.open("user://data.boom", FileAccess.READ)
	var load_default_scores = false
	if high_score_file == null:
		load_default_scores = true
	else:
		var high_scores_from_file = JSON.parse_string(high_score_file.get_as_text())
		if high_scores_from_file == null:
			load_default_scores = true
		else:
			if high_scores_from_file is Array:
				high_scores_from_file.sort_custom(high_score_sort)
				high_scores = high_scores_from_file
			else:
				load_default_scores = true
				
	if load_default_scores:
		high_scores = [
			{
				name = "GUS",
				points = 5000
			},
			{
				name = "SEA",
				points = 4000
			},
			{
				name = "XAV",
				points = 3000
			},
			{
				name = "DUC",
				points = 2000
			},
			{
				name = "DAV",
				points = 1000
			},
		]
		save_high_scores()
	
	var words_file = FileAccess.open("res://utils/words_alpha.txt", FileAccess.READ)
	words = words_file.get_as_text().split("\n")
	
	for letter in LETTER_FREQUENCIES.keys():
		LETTER_FREQUENCIES[letter] = pow(LETTER_FREQUENCIES[letter], 1.5)
	
	tile_move_down_timer = Timer.new()
	tile_move_down_timer.wait_time = TILE_MOVE_DOWN_SECS
	tile_move_down_timer.one_shot = false
	tile_move_down_timer.timeout.connect(on_tile_move_down_timer_timeout)
	add_child(tile_move_down_timer)

func high_score_sort(a, b):
	return a.points > b.points

func add_high_score(name: String, points: int):
	var best_high_score_beaten = null
	for high_score in high_scores:
		if points > high_score.points:
			if best_high_score_beaten != null:
				if points > best_high_score_beaten.points:
					best_high_score_beaten = high_score
			else:
				best_high_score_beaten = high_score
	
	if best_high_score_beaten != null:
		high_scores.remove_at(high_scores.find(best_high_score_beaten))
		high_scores.append({
			name = name,
			points = points
		})
	
	save_high_scores()
	high_scores.sort_custom(high_score_sort)

func save_high_scores():
	var high_score_file = FileAccess.open("user://data.boom", FileAccess.WRITE)
	high_score_file.store_string(JSON.stringify(high_scores))

func is_high_score(score: int):
	for high_score in high_scores:
		if high_score.points < score:
			return true
			
	return false

func stop_game():
	game_over = true
	game_stopped.emit()

func start_game():
	game_over = false
	
	tile_move_down_timer.start()
	
	grid.clear()
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			grid[Vector2i(x, y)] = {
				solid = false,
				texture = null,
				letter = null
			}
			grid_changed.emit(Vector2i(x, y))
			
	falling_block = block_spawner.spawn_random_block()
	falling_block.block_placed.connect(on_block_placed)
	
	mode = GameMode.TETRIS
	turn_counter = MAX_TETRIS_TURN_COUNT

func end_game():
	if is_high_score(score):
		get_tree().change_scene_to_packed(preload("res://highscore/high_score.tscn"))
	else:
		get_tree().change_scene_to_packed(preload("res://results/results.tscn"))
		
	mode = GameMode.TETRIS

func get_score() -> int:
	return score
	
func add_score(points: int, where: Vector2 = Vector2.INF):
	score += points
	score_changed.emit(score)
	pop_at(str(points), where)

func pop_at(text: String, where: Vector2):
	var pop = preload("res://textpops/text_pop.tscn").instantiate()
	pop.set_text(text)
	pop.global_position = where
	text_pop_host.add_child(pop)
	
func explode_at(where: Vector2):
	var particles = preload("res://particles/explosion_particles.tscn").instantiate()
	particles.emitting = true
	particles.global_position = where
	text_pop_host.add_child(particles)

func get_turn_counter() -> int:
	return turn_counter

func get_random_weighted_letter() -> String:
	var custom_weights = LETTER_FREQUENCIES
	
	var existence_discount_coefficient = 1
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
			explode_at(get_global_position_from_tile_pos(pos))
	
	camera.shake(0.1 * size)
	
	if bomb_placing_type == BombType.NORMAL:
		AudioMan.play(preload("res://grid/bombExplode0.mp3"))		
	elif bomb_placing_type == BombType.SUPER:
		AudioMan.play(preload("res://grid/bombExplode1.mp3"))
	elif bomb_placing_type == BombType.ULTRA:
		AudioMan.play(preload("res://grid/bombExplode2.mp3"))
	else:
		AudioMan.play(preload("res://grid/bombExplode3.mp3"))
		
	
	take_bomb(bomb_placing_type)
	bomb_placing = false
	
func take_bomb(type):
	_bomb_count[type] -= 1
	bomb_count_update.emit(type, _bomb_count[type])
	
func add_bomb(type):
	_bomb_count[type] += 1
	bomb_count_update.emit(type, _bomb_count[type])

func get_bomb_count(type):
	return _bomb_count[type]

func on_block_placed():
	falling_block.block_placed.disconnect(on_block_placed)
	last_down_press_time = 0 # "hack" to make sure next block doesn't come careening down
	
	add_score(10, get_global_position_from_tile_pos(falling_block.tile_pos))
	
	var solid_row_streak = 0
	var completed_rows = []
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
			completed_rows.append(row)
		else:
			if solid_row_streak == 1:
				add_bomb(BombType.NORMAL)
			elif solid_row_streak == 2:
				add_bomb(BombType.SUPER)
			elif solid_row_streak == 3:
				add_bomb(BombType.ULTRA)
			elif solid_row_streak == 4:
				add_bomb(BombType.MASTER)
			
			if solid_row_streak > 0:
				on_rows_finished(solid_row_streak, row - (solid_row_streak / 2) - 1)
			solid_row_streak = 0
			
			for completed_row in completed_rows:
				explode_at(get_global_position_from_tile_pos(Vector2i(0, completed_row)))
				explode_at(get_global_position_from_tile_pos(Vector2i(GRID_WIDTH - 1, completed_row)))
				
			if completed_rows.size() == 1:
				AudioMan.play(preload("res://grid/lineClear0.mp3"))
			elif completed_rows.size() == 2:
				AudioMan.play(preload("res://grid/lineClear1.mp3"))
			elif completed_rows.size() == 3:
				AudioMan.play(preload("res://grid/lineClear2.mp3"))
			elif completed_rows.size() >= 4:
				AudioMan.play(preload("res://grid/lineClear3.mp3"))
		
			completed_rows.clear()			
			
	if solid_row_streak == 1:
		add_bomb(BombType.NORMAL)
	elif solid_row_streak == 2:
		add_bomb(BombType.SUPER)
	elif solid_row_streak == 3:
		add_bomb(BombType.ULTRA)
	elif solid_row_streak == 4:
		add_bomb(BombType.MASTER)
		
	for completed_row in completed_rows:
		explode_at(get_global_position_from_tile_pos(Vector2i(0, completed_row)))
		explode_at(get_global_position_from_tile_pos(Vector2i(GRID_WIDTH - 1, completed_row)))
		
	if completed_rows.size() == 1:
		AudioMan.play(preload("res://grid/lineClear0.mp3"))
	elif completed_rows.size() == 2:
		AudioMan.play(preload("res://grid/lineClear1.mp3"))
	elif completed_rows.size() == 3:
		AudioMan.play(preload("res://grid/lineClear2.mp3"))
	elif completed_rows.size() >= 4:
		AudioMan.play(preload("res://grid/lineClear3.mp3"))
		

	decrement_turn_counter()
	if turn_counter > 0 and mode == GameMode.TETRIS and not game_over:
		falling_block = block_spawner.spawn_random_block()
		falling_block.block_placed.connect(on_block_placed)

func on_rows_finished(count: int, middle_row_tile_y: int):
	add_score(count * 500, get_global_position_from_tile_pos(Vector2i(GRID_WIDTH / 2, middle_row_tile_y)))

func decrement_turn_counter():
	turn_counter -= 1
	
	if turn_counter == 0:
		if mode == GameMode.TETRIS:
			mode = GameMode.WORDSEARCH
			turn_counter = MAX_WORDSEARCH_TURN_COUNT
			selecting = false
			selection_begin = Vector2i.ZERO
			selection_end = Vector2i.ZERO
		else:
			mode = GameMode.TETRIS
			turn_counter = MAX_TETRIS_TURN_COUNT
			falling_block = block_spawner.spawn_random_block()
			falling_block.block_placed.connect(on_block_placed)
			
			selecting = false
			selection_begin = Vector2.ZERO
			selection_end = Vector2.ZERO
			rounds += 1
		
		AudioMan.play(preload("res://grid/modeSwitch.mp3"))
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
	if selection_end != end_pos:
		var sound = [
			preload("res://grid/wordSelect0.mp3"),
			preload("res://grid/wordSelect1.mp3"),
			preload("res://grid/wordSelect2.mp3"),
			preload("res://grid/wordSelect3.mp3"),
		].pick_random()
		AudioMan.play(sound)
	
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
		decrement_turn_counter()
		var word_length = selected_words[0].length()
		var score = 0
		if word_length == 3:
			score = 50
		if word_length == 4:
			score = 150
		if word_length == 5:
			score = 400
		if word_length == 6:
			score = 1000
		if word_length == 7:
			score = 3000
		if word_length == 8:
			score = 10000
		if word_length >= 9:
			score = pow(20000, word_length - 8)
		add_score(score, get_global_position_from_tile_pos(selection_begin))
		AudioMan.play(preload("res://grid/wordExplode.mp3"))
	
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
				explode_at(get_global_position_from_tile_pos(pos))
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
				explode_at(get_global_position_from_tile_pos(pos))
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
				explode_at(get_global_position_from_tile_pos(pos))
				grid_changed.emit(pos)

func get_selected_words() -> Array[String]:
	if grid.is_empty():
		return ["",""]
	
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
	
	if Input.is_action_just_pressed("move_down") and mode == GameMode.TETRIS:
		last_down_press_time = 0
		AudioMan.play_random_pitched(preload("res://grid/rachet.mp3"))
		tile_move_down_timer.start()
		on_tile_move_down_timer_timeout()
	
	if last_down_press_time > 0.5 and Input.is_action_pressed("move_down") and mode == GameMode.TETRIS:
		tile_move_down_timer.start()
		AudioMan.play_random_pitched(preload("res://grid/rachet.mp3"))
		on_tile_move_down_timer_timeout()
	
	if Input.is_action_just_released("selection"):
		end_selection()
		
	if mode != GameMode.WORDSEARCH:
		selecting = false
		selection_begin = Vector2i.ZERO
		selection_end = Vector2i.ZERO
		bomb_placing = false
		
	tile_move_down_timer.wait_time = max(TILE_MOVE_DOWN_SECS - (0.05 * rounds), 0.2)
