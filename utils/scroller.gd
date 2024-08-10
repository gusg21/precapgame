extends Sprite2D

@export var direction: Vector2 = Vector2.ONE
@export var speed: float = 2.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	region_rect.position += direction * speed * delta
