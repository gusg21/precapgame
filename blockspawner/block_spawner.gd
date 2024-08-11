extends Node2D

class_name BlockSpawner

@export var block_scene: PackedScene
@export var block_strings: Array[String]
@export var block_textures: Array[Texture2D]

func _enter_tree():
	print("registering self")
	GameMaster.block_spawner = self

func spawn_random_block():
	var new_block = block_scene.instantiate()
	new_block.set_block_string(block_strings.pick_random())
	new_block.set_block_texture(block_textures.pick_random())
	add_child(new_block)
	return new_block
