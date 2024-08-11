extends Sprite2D

@export var direction: Vector2 = Vector2.ONE
@export var speed: float = 2.0

static var intended_pos: Vector2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	intended_pos += direction * speed * delta
	region_rect.position = intended_pos.snapped(Vector2.ONE)
