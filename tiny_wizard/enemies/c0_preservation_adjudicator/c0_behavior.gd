extends QuiverCharacterBehavior


func _process(_delta: float) -> void:
	action.moving_direction = Vector2.ZERO


func on_wall_collision(_collision: KinematicCollision2D) -> void:
	action.moving_direction = Vector2.ZERO

