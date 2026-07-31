extends QuiverCharacterBehavior


enum State {
	MOVE,
	WINDUP,
	BURST,
	RECOVERY,
}

@onready var player_detector := $PlayerDetector

var _state := State.MOVE
var _state_time := 0.0
var _attack_cooldown := randf_range(0.9, 1.5)
var _burst_direction := Vector2.RIGHT
var _burst_target := Vector2.ZERO
var _shots_fired := 0
var _shot_marks := [0.08, 0.22, 0.36]
var _strafe_sign := -1.0 if randf() < 0.5 else 1.0


func _process(delta: float) -> void:
	var enemy := get_parent()
	if enemy == null:
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	if _state != State.MOVE:
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
	if _attack_cooldown <= 0.0 and distance >= 120.0 and distance <= 360.0:
		_start_windup(enemy, to_target, target_position)
		return

	if distance < 150.0:
		action.moving_direction = -to_target
	elif distance > 285.0:
		action.moving_direction = to_target
	else:
		action.moving_direction = to_target.rotated(PI * 0.5 * _strafe_sign)
	enemy.call("set_speed_multiplier", 1.0)
	enemy.call("play_idle")


func on_wall_collision(collision: KinematicCollision2D) -> void:
	_strafe_sign *= -1.0
	action.moving_direction = collision.get_normal()


func _tick_state(delta: float, enemy: Node) -> void:
	_state_time = maxf(0.0, _state_time - delta)
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	match _state:
		State.WINDUP:
			if _state_time <= 0.0:
				_state = State.BURST
				_state_time = 0.52
				_shots_fired = 0
				enemy.call("begin_burst", _burst_direction)
		State.BURST:
			var elapsed := 0.52 - _state_time
			while _shots_fired < _shot_marks.size() and elapsed >= float(_shot_marks[_shots_fired]):
				enemy.call("fire_rivet", _burst_target)
				_shots_fired += 1
			if _state_time <= 0.0:
				_state = State.RECOVERY
				_state_time = 0.55
		State.RECOVERY:
			if _state_time <= 0.0:
				_state = State.MOVE
				enemy.call("set_speed_multiplier", 1.0)
				enemy.call("finish_attack")


func _start_windup(enemy: Node, direction: Vector2, target_position: Vector2) -> void:
	_burst_direction = direction.normalized()
	if _burst_direction.length() < 0.01:
		_burst_direction = Vector2.RIGHT
	_burst_target = target_position
	_state = State.WINDUP
	_state_time = 0.48
	_attack_cooldown = 2.9
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", _burst_direction, _state_time)
