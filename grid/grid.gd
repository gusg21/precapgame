extends Node

class_name Grid

@export var grid_spacing: int = 8
@export var empty_grid_tile_tex: Texture2D
@export var grid_bg_scene: PackedScene

var tiles: Dictionary = {}


func _enter_tree():
	GameMaster.grid_object = self
	GameMaster.grid_changed.connect(on_grid_changed)

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(GameMaster.GRID_WIDTH):
		for y in range(GameMaster.GRID_HEIGHT):
			var grid_tile = Sprite2D.new()
			grid_tile.texture = empty_grid_tile_tex
			grid_tile.centered = false
			grid_tile.position = Vector2i(
				x - GameMaster.GRID_WIDTH / 2, 
				y - GameMaster.GRID_HEIGHT / 2
				) * grid_spacing
			add_child(grid_tile)
			
			tiles[Vector2i(x, y)] = grid_tile
			
	var bg = grid_bg_scene.instantiate()
	bg = bg as NinePatchRect
	bg.size = Vector2(
		GameMaster.GRID_WIDTH * grid_spacing + 2,
		GameMaster.GRID_HEIGHT * grid_spacing + 2
		)
	bg.position = -(bg.size / 2)
	bg.z_index = -2
	add_child(bg)

func on_grid_changed(tile_pos: Vector2i):
	if tile_pos in tiles.keys():
		tiles[tile_pos].texture = GameMaster.get_tile_at(tile_pos).texture

func get_global_position_from_tile_pos(tile_pos: Vector2i) -> Vector2:
	return Vector2(
				tile_pos.x - GameMaster.GRID_WIDTH / 2, 
				tile_pos.y - GameMaster.GRID_HEIGHT / 2
				) * grid_spacing
