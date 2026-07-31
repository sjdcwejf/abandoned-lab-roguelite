extends QuiverCharacterBehavior


enum State {
	POSITION,
	WINDUP,
	ACTIVE,
	RECOVERY,
}

@onready var player_detector := $PlayerDetector

var _state := State.POSITION
var _state_time := 0.0
var _attack_cooldown := randf_range(0.7, 1.2)
var _pending_attack := &"hook_slam"
var _last_attack := &""
var _damage_done := false


func _process(delta: float) -> void:
	var enemy := get_parent()
	if enemy == null:
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	if _state != State.POSITION:
		_tick_state(delta, enemy)
		return
	if player_detector == null or not player_detector.player_is_in_range():
		action.moving_direction = Vector2.ZERO
		enemy.call("set_speed_multiplier", 0.7)
		enemy.call("play_idle")
		return

	var target_position: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target_position)
	var distance := global_position.distance_to(target_position)
	if _attack_cooldown <= 0.0 and distance <= 330.0:
		_start_windup(enemy, _choose_attack(target_position, distance))
		return

	if distance > 210.0:
		action.moving_direction = to_target
	elif distance < 126.0:
		action.moving_direction = -to_target
	else:
		action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 1.0)
	enemy.call("play_idle")


func on_wall_collision(collision: KinematicCollision2D) -> void:
	action.moving_direction = collision.get_normal()


func _tick_state(delta: float, enemy: Node) -> void:
	_state_time = maxf(0.0, _state_time - delta)
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	match _state:
		State.WINDUP:
			if _state_time <= 0.0:
				_state = State.ACTIVE
				_damage_done = false
				_state_time = _active_duration(_pending_attack)
				enemy.call("begin_attack", _pending_attack)
		State.ACTIVE:
			var elapsed := _active_duration(_pending_attack) - _state_time
			if not _damage_done and elapsed >= _damage_time(_pending_attack):
				_damage_done = true
				enemy.call("execute_attack", _pending_attack)
			if _state_time <= 0.0:
				_state = State.RECOVERY
				_state_time = 0.72
		State.RECOVERY:
			if _state_time <= 0.0:
				_last_attack = _pending_attack
				_state = State.POSITION
				_attack_cooldown = 1.1
				enemy.call("set_speed_multiplier", 1.0)
				enemy.call("finish_attack")


func _start_windup(enemy: Node, attack_name: StringName) -> void:
	_pending_attack = attack_name
	_state = State.WINDUP
	_state_time = _windup_duration(attack_name)
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", _pending_attack, _state_time)


func _choose_attack(target_position: Vector2, distance: float) -> StringName:
	var local_x := target_position.x - global_position.x
	var selected := &"pendulum_sweep"
	if distance < 142.0 or absf(local_x) < 48.0:
		selected = &"pendulum_sweep"
	elif local_x < 0.0:
		selected = &"hook_slam"
	else:
		selected = &"driver_slam"
	if selected == _last_attack:
		if selected == &"hook_slam":
			return &"pendulum_sweep"
		if selected == &"driver_slam":
			return &"pendulum_sweep"
		return &"hook_slam" if local_x < 0.0 else &"driver_slam"
	return selected


func _windup_duration(attack_name: StringName) -> float:
	match attack_name:
		&"driver_slam":
			return 0.62
		&"pendulum_sweep":
			return 0.7
	return 0.64


func _active_duration(attack_name: StringName) -> float:
	match attack_name:
		&"driver_slam":
			return 0.88
		&"pendulum_sweep":
			return 0.62
	return 0.62


func _damage_time(attack_name: StringName) -> float:
	match attack_name:
		&"driver_slam":
			return 0.38
		&"pendulum_sweep":
			return 0.28
	return 0.3
