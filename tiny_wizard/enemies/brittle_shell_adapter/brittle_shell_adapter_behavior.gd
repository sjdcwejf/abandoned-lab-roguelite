extends QuiverCharacterBehavior


enum State {
	CHASE,
	WINDUP,
	DASH,
	RECOVERY,
}

@onready var player_detector := $PlayerDetector

var _state := State.CHASE
var _state_time := 0.0
var _attack_cooldown := randf_range(0.6, 1.3)
var _dash_direction := Vector2.RIGHT


func _process(delta: float) -> void:
	var enemy := get_parent()
	if enemy == null:
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _state != State.CHASE:
		_tick_state(delta, enemy)
		return

	if player_detector == null or not player_detector.player_is_in_range():
		action.moving_direction = Vector2.ZERO
		enemy.call("set_speed_multiplier", 1.0)
		enemy.call("play_idle")
		return

	var target_position: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target_position)
	var distance := global_position.distance_to(target_position)
	if _attack_cooldown <= 0.0 and distance >= 68.0 and distance <= 235.0:
		_start_windup(enemy, to_target)
		return

	action.moving_direction = to_target
	enemy.call("set_speed_multiplier", 1.0)
	enemy.call("play_idle")


func on_wall_collision(collision: KinematicCollision2D) -> void:
	var enemy := get_parent()
	if enemy != null and _state == State.DASH:
		_start_recovery(enemy, collision.get_normal())
		return
	action.moving_direction = collision.get_normal()


func on_enemy_collision(collision: KinematicCollision2D) -> void:
	if _state == State.DASH:
		var enemy := get_parent()
		if enemy != null:
			_start_recovery(enemy, collision.get_normal())


func _tick_state(delta: float, enemy: Node) -> void:
	_state_time = maxf(0.0, _state_time - delta)
	match _state:
		State.WINDUP:
			action.moving_direction = Vector2.ZERO
			enemy.call("set_speed_multiplier", 0.0)
			if _state_time <= 0.0:
				_state = State.DASH
				_state_time = 0.58
				action.moving_direction = _dash_direction
				enemy.call("set_speed_multiplier", 4.25)
				enemy.call("begin_dash", _dash_direction)
		State.DASH:
			action.moving_direction = _dash_direction
			enemy.call("set_speed_multiplier", 4.25)
			var hit_player := bool(enemy.call("tick_dash_attack", _dash_direction))
			if hit_player or _state_time <= 0.0:
				_start_recovery(enemy, -_dash_direction)
		State.RECOVERY:
			action.moving_direction = Vector2.ZERO
			enemy.call("set_speed_multiplier", 0.0)
			if _state_time <= 0.0:
				_state = State.CHASE
				enemy.call("set_speed_multiplier", 1.0)
				enemy.call("play_idle")


func _start_windup(enemy: Node, direction: Vector2) -> void:
	_dash_direction = direction.normalized()
	if _dash_direction.length() < 0.01:
		_dash_direction = Vector2.RIGHT
	_state = State.WINDUP
	_state_time = 0.52
	_attack_cooldown = 2.4
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", _dash_direction, _state_time)


func _start_recovery(enemy: Node, impact_direction: Vector2) -> void:
	_state = State.RECOVERY
	_state_time = 0.48
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_impact", impact_direction)
