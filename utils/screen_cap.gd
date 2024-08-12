extends Node

func _ready():
	if OS.has_feature("standalone"):
		queue_free()

func _process(delta):
	if Input.is_action_just_pressed("take_screenshot"):
		var cap = get_viewport().get_texture().get_image()
		cap.save_png("user://cap_" + str(randi()) + ".png")
		print("saved screencap")
