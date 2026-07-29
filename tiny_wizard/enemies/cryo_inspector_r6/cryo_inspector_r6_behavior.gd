extends QuiverCharacterBehavior


enum State {
	MOVE,
	WINDUP,
	RECOVERY,
}

@onready var player_detector := $PlayerDetector

var _state := State.MOVE
var _state_time := 0.0
var _shot_cooldown := 1.0
var _clamp_cooldown := 0.8
var _pending_attack: StringName = &""
var _pending_target := Vector2.ZERO
var _pending_direction := Vector2.RIGHT
var _strafe_sign := 1.0


func _process(delta: float) -> void:
	var enemy := get_parent()
	if enemy == null:
		return
	_shot_cooldown = maxf(0.0, _shot_cooldown - delta)
	_clamp_cooldown = maxf(0.0, _clamp_cooldown - delta)

	if _state != State.MOVE:
		_tick_state(delta, enemy)
		return
	if player_detector == null or not player_detector.player_is_in_range():
		action.moving_direction = Vector2.ZERO
		return

	var target_position: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target_position)
	var distance := global_position.distance_to(target_position)

	if bool(enemy.call("is_pressure_relief_ready")):
		_start_attack(enemy, &"vent", to_target, target_position, 0.86)
		return
	if distance <= 98.0 and _clamp_cooldown <= 0.0:
		_clamp_cooldown = 3.0
		_start_attack(enemy, &"clamp", to_target, target_position, 0.48)
		return
	if distance <= 390.0 and _shot_cooldown <= 0.0:
		_shot_cooldown = 2.35
		_start_attack(enemy, &"shot", to_target, target_position, 0.72)
		return

	if distance < 150.0:
		action.moving_direction = -to_target
	elif distance > 290.0:
		action.moving_direction = to_target
	else:
		action.moving_direction = to_target.rotated(PI * 0.5 * _strafe_sign)
	enemy.call("set_speed_multiplier", 1.0)


func on_wall_collision(collision: KinematicCollision2D) -> void:
	_strafe_sign *= -1.0
	action.moving_direction = collision.get_normal()


func _tick_state(delta: float, enemy: Node) -> void:
	_state_time = maxf(0.0, _state_time - delta)
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	if _state == State.WINDUP and _state_time <= 0.0:
		match _pending_attack:
			&"shot":
				enemy.call("fire_pressure_round", _pending_target)
			&"clamp":
				enemy.call("execute_clamp", _pending_direction)
			&"vent":
				enemy.call("execute_pressure_relief")
		_state = State.RECOVERY
		_state_time = 0.62 if _pending_attack != &"vent" else 0.85
	elif _state == State.RECOVERY and _state_time <= 0.0:
		_state = State.MOVE
		_pending_attack = &""
		enemy.call("set_speed_multiplier", 1.0)
		enemy.call("finish_attack")


func _start_attack(
	enemy: Node,
	attack_name: StringName,
	direction: Vector2,
	target_position: Vector2,
	windup: float
) -> void:
	_pending_attack = attack_name
	_pending_direction = direction.normalized()
	if _pending_direction.length() < 0.01:
		_pending_direction = Vector2.RIGHT
	_pending_target = target_position
	_state = State.WINDUP
	_state_time = windup
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", attack_name, _pending_direction, windup)

