extends QuiverCharacterVisual


@export var grounded_sprite_y := -30.0
@export var tread_shake := 0.8
@export var body_shake := 0.45

var _time := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func update_visual(action: QuiverCharacterAction) -> void:
	var delta := get_physics_process_delta_time()
	_time += delta

	animated_sprite.rotation = 0.0
	if action.moving_direction.length() > 0.01:
		animated_sprite.position = Vector2(
			sin(_time * 36.0) * body_shake,
			grounded_sprite_y + sin(_time * 28.0) * tread_shake
		)
	else:
		animated_sprite.position = Vector2(0.0, grounded_sprite_y)
