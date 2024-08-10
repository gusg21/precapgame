extends Node

const GRID_WIDTH = 12
const GRID_HEIGHT = 24
const TILE_MOVE_DOWN_SECS: float = 1

var grid_object: Grid
var block_spawner: BlockSpawner

var grid: Dictionary
var tile_move_down_timer: Timer # block move down timer. bad name :(
var falling_block: Block = null
var last_down_press_time = 0

signal tile_move_down
signal grid_changed(tile_pos: Vector2i)

# Called when the node enters the scene tree for the first time.
func _ready():
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

func on_block_placed():
	falling_block.block_placed.disconnect(on_block_placed)
	falling_block = block_spawner.spawn_random_block()
	falling_block.block_placed.connect(on_block_placed)
	
	last_down_press_time = 0 # hack to make sure next block doesn't come careening down

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
