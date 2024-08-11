extends Node2D

func set_text(new_text: String):
	$Label.text = new_text
	
func _process(delta):
	position.y -= delta * 10
	modulate.a = clamp(modulate.a - delta * 0.1, 0, 1)
	if modulate.a == 0:
		queue_free()
