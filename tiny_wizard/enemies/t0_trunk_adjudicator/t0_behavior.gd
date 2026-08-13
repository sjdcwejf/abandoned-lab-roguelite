extends QuiverCharacterBehavior


func _process(_delta: float) -> void:
	action.moving_direction = Vector2.ZERO
	action.aiming_direction = Vector2.DOWN
	action.shoot = false
