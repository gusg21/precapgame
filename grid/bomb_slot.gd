extends Sprite2D

@export var bomb_type: GameMaster.BombType
@export var bomb_texture: Texture2D

var mouse_over: bool = false
var old_count = 0

func _ready():
	GameMaster.bomb_count_update.connect(on_bomb_count_update)
	
	$BasicBomb.texture = bomb_texture
	
	$Area2D.mouse_entered.connect(on_mouse_entered)
	$Area2D.mouse_exited.connect(on_mouse_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var enabled = GameMaster.get_mode() == GameMaster.GameMode.WORDSEARCH and !GameMaster.is_bomb_placing() and \
				  GameMaster.get_bomb_count(bomb_type) > 0
	
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
		AudioMan.play(preload("res://utils/button_pressed.mp3"))
		GameMaster.begin_bomb_placing(bomb_type)

func on_bomb_count_update(type: GameMaster.BombType, count: int):
	if bomb_type == type:
		if old_count != count:
			var diff = count - old_count
			if diff > 0:
				GameMaster.pop_at(str(diff), global_position)
				GameMaster.explode_at(global_position)
		
		$Count.text = str(count)
		old_count = count

func on_mouse_entered():
	mouse_over = true
	
func on_mouse_exited():
	mouse_over = false
