extends Sprite2D

class_name Effect

var time = 0.0
var speed = 0.7

func _enter_tree():
	GameMaster.effect = self

func pow():
	time = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time -= delta * speed
	
	var shader = (material as ShaderMaterial)
	var t_clamp = clamp(time, 0, 1)
	shader.set_shader_parameter("power", pow(t_clamp, 10.0))
	shader.set_shader_parameter("radius", lerp(0.0, 1000.0, 1.0 - t_clamp))
