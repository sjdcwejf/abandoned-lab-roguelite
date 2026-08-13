extends QuiverCharacterBehavior


enum State { MOVE, WINDUP, ACTIVE, RECOVERY }

@onready var player_detector := $PlayerDetector

var _state := State.MOVE
var _state_time := 0.0
var _attack_cooldown := randf_range(0.7, 1.1)
var _direction := Vector2.RIGHT


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
		return
	var target: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target)
	var distance := global_position.distance_to(target)
	if _attack_cooldown <= 0.0 and distance <= 145.0:
		_direction = to_target
		_start_windup(enemy)
		return
	if distance > 74.0:
		action.moving_direction = to_target
	else:
		action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 1.0)
	enemy.call("play_idle", to_target)


func _start_windup(enemy: Node) -> void:
	_state = State.WINDUP
	_state_time = 0.66
	_attack_cooldown = 1.9
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", _direction, _state_time)


func _tick_state(delta: float, enemy: Node) -> void:
	_state_time = maxf(0.0, _state_time - delta)
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	match _state:
		State.WINDUP:
			if _state_time <= 0.0:
				_state = State.ACTIVE
				_state_time = 1.02
				enemy.call("begin_attack", _direction)
		State.ACTIVE:
			if _state_time <= 0.0:
				_state = State.RECOVERY
				_state_time = 0.42
		State.RECOVERY:
			if _state_time <= 0.0:
				_state = State.MOVE
				enemy.call("set_speed_multiplier", 1.0)
				enemy.call("finish_attack")
