extends Camera2D

class_name Camera

var shake_time = 0
var noise: FastNoiseLite

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	GameMaster.camera = self
	noise = FastNoiseLite.new()
	
func shake(time):
	shake_time = time

func _process(delta):
	if shake_time > 0:
		shake_time -= delta
		offset = Vector2(
			randf_range(-shake_time, shake_time),
			randf_range(-shake_time, shake_time)
		) * shake_time * 10
	else:
		offset = Vector2.ZERO
