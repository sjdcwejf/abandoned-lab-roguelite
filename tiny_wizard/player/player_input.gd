extends QuiverCharacterBehavior


# returns the player input movement direction
func _get_moving_input()->Vector2:
	return Input.get_vector("player_left", "player_right", "player_up", "player_down")

func _get_keyboard_aiming_input()->Vector2:
	return Input.get_vector("player_shoot_left", "player_shoot_right", "player_shoot_up", "player_shoot_down")

func _get_mouse_aiming_input()->Vector2:
	var character := get_parent() as Node2D
	if character == null:
		return Vector2.ZERO
	return character.global_position.direction_to(get_global_mouse_position())

func _physics_process(_delta):
	var keyboard_aiming := _get_keyboard_aiming_input()
	var aiming := keyboard_aiming
	if aiming.length() == 0:
		aiming = _get_mouse_aiming_input()

	action.moving_direction = _get_moving_input()
	action.aiming_direction = aiming
	action.shoot = Input.is_action_pressed("fire")
