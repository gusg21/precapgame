extends Sprite2D

@export var bomb_type: GameMaster.BombType
@export var bomb_texture: Texture2D

var mouse_over: bool = false

func _ready():
	$BasicBomb.texture = bomb_texture
	
	$Area2D.mouse_entered.connect(on_mouse_entered)
	$Area2D.mouse_exited.connect(on_mouse_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var enabled = GameMaster.get_mode() == GameMaster.GameMode.WORDSEARCH and !GameMaster.is_bomb_placing() and \
				  GameMaster.bomb_count[bomb_type] > 0
	
	$Count.text = str(GameMaster.bomb_count[bomb_type])
	$BasicBomb.modulate.a = 0.5 if !enabled else 1.0
	if enabled:
		if mouse_over:
			$BasicBomb.scale = Vector2(2, 2)
			$BasicBomb.z_index = 5
		else:
			$BasicBomb.scale = Vector2.ONE if ((Time.get_ticks_msec() + bomb_type * 100) % 1000 < 800) else Vector2(1.1, 1.1)
			$BasicBomb.z_index = 3
	else:
		$BasicBomb.scale = Vector2.ONE
	
	$BombLabel.visible = enabled and mouse_over
	$BombLabel.text = GameMaster.BombType.keys()[bomb_type]
	
	if Input.is_action_just_pressed("selection") and mouse_over and enabled:
		GameMaster.begin_bomb_placing(bomb_type)
	
func on_mouse_entered():
	mouse_over = true
	
func on_mouse_exited():
	mouse_over = false
