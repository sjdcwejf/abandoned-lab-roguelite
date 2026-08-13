extends QuiverCharacterBehavior


enum State { MOVE, WINDUP, ACTIVE, RECOVERY }

@onready var player_detector := $PlayerDetector

var _state := State.MOVE
var _state_time := 0.0
var _attack_cooldown := randf_range(0.8, 1.4)
var _direction := Vector2.RIGHT
var _target := Vector2.ZERO


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
		return

	_target = player_detector.get_player_position()
	var to_target := global_position.direction_to(_target)
	var distance := global_position.distance_to(_target)
	if _attack_cooldown <= 0.0 and distance >= 120.0 and distance <= 360.0:
		_start_windup(enemy, to_target)
		return

	if distance < 145.0:
		action.moving_direction = -to_target
	else:
		action.moving_direction = to_target.rotated(PI * 0.5)
	enemy.call("set_speed_multiplier", 1.0)
	enemy.call("play_idle", to_target)


func _tick_state(delta: float, enemy: Node) -> void:
	_state_time = maxf(0.0, _state_time - delta)
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	match _state:
		State.WINDUP:
			if _state_time <= 0.0:
				_state = State.ACTIVE
				_state_time = 0.16
				enemy.call("begin_attack", _direction, _target)
				enemy.call("fire_nail")
		State.ACTIVE:
			if _state_time <= 0.0:
				_state = State.RECOVERY
				_state_time = 0.62
		State.RECOVERY:
			if _state_time <= 0.0:
				_state = State.MOVE
				_attack_cooldown = 1.45
				enemy.call("set_speed_multiplier", 1.0)
				enemy.call("finish_attack")


func _start_windup(enemy: Node, direction: Vector2) -> void:
	_direction = direction.normalized()
	if _direction.length() < 0.01:
		_direction = Vector2.RIGHT
	_state = State.WINDUP
	_state_time = 1.2
	_attack_cooldown = 2.6
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", _direction, _state_time)
