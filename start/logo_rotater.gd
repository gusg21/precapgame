extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation.y = sin((Time.get_ticks_msec() / 1000.0) * TAU * 0.1) * 0.2
	rotation.z = sin((Time.get_ticks_msec() / 1000.0) * TAU * 0.15) * 0.1
