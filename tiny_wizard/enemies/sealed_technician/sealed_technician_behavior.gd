extends QuiverCharacterBehavior


enum State {
	MOVE,
	WINDUP,
	RECOVERY,
}

@onready var player_detector := $PlayerDetector

var _state := State.MOVE
var _state_time := 0.0
var _attack_cooldown := randf_range(0.8, 1.5)
var _attack_direction := Vector2.RIGHT
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
		enemy.call("play_idle")
		return

	var target_position: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target_position)
	var distance := global_position.distance_to(target_position)
	if _attack_cooldown <= 0.0 and distance <= 300.0:
		_start_windup(enemy, to_target)
		return

	if distance < 124.0:
		action.moving_direction = -to_target
	elif distance > 245.0:
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
	if _state == State.WINDUP and _state_time <= 0.0:
		enemy.call("execute_spray", _attack_direction)
		_state = State.RECOVERY
		_state_time = 0.56
	elif _state == State.RECOVERY and _state_time <= 0.0:
		_state = State.MOVE
		enemy.call("set_speed_multiplier", 1.0)
		enemy.call("finish_attack")


func _start_windup(enemy: Node, direction: Vector2) -> void:
	_attack_direction = direction.normalized()
	if _attack_direction.length() < 0.01:
		_attack_direction = Vector2.RIGHT
	_state = State.WINDUP
	_state_time = 0.52
	_attack_cooldown = 2.65
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", _attack_direction, _state_time)

