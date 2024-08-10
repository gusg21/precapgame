extends Node2D

class_name BlockSpawner

@export var block_scene: PackedScene
@export var block_strings: Array[String]

func _enter_tree():
	GameMaster.block_spawner = self

func spawn_random_block():
	var new_block = block_scene.instantiate()
	new_block.set_block_string(block_strings.pick_random())
	add_child(new_block)
	return new_block
