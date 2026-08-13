extends QuiverCharacterBehavior


@onready var player_detector := $PlayerDetector


func _process(_delta: float) -> void:
	var enemy := get_parent()
	if enemy == null:
		return
	if player_detector == null or not player_detector.player_is_in_range():
		action.moving_direction = Vector2.ZERO
		enemy.call("set_speed_multiplier", 1.0)
		return
	var target: Vector2 = player_detector.get_player_position()
	var direction := global_position.direction_to(target)
	var distance := global_position.distance_to(target)
	if distance > 210.0:
		action.moving_direction = direction
	else:
		action.moving_direction = direction.rotated(PI * 0.5)
	enemy.call("set_speed_multiplier", 1.0)
