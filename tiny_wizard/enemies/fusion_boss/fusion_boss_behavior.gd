extends QuiverCharacterBehavior


enum AttackState {
	NEUTRAL,
	CHARGE_WINDUP,
	CHARGING,
	SPIT_WINDUP,
	SUMMON_WINDUP,
	PHASE_TRANSITION,
	RECOVERY,
}


@onready var player_detector := $PlayerDetector

var _state := AttackState.NEUTRAL
var _state_time_remaining := 0.0
var _charge_cooldown_remaining := randf_range(1.0, 2.2)
var _spit_cooldown_remaining := randf_range(0.8, 1.4)
var _summon_cooldown_remaining := 3.0
var _charge_direction := Vector2.RIGHT
var _pending_target_position := Vector2.ZERO
var _strafe_direction := 1.0
var _phase_transition_played := false


func _process(delta: float) -> void:
	var boss := get_parent()
	if boss == null:
		return

	_charge_cooldown_remaining = maxf(0.0, _charge_cooldown_remaining - delta)
	_spit_cooldown_remaining = maxf(0.0, _spit_cooldown_remaining - delta)
	_summon_cooldown_remaining = maxf(0.0, _summon_cooldown_remaining - delta)

	var has_target: bool = player_detector != null and player_detector.player_is_in_range()
	if not has_target:
		action.moving_direction = Vector2.ZERO
		_set_boss_speed(boss, 1.0)
		if _state != AttackState.NEUTRAL:
			_cancel_current_action(boss)
		return

	var target_position: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target_position)
	var distance := global_position.distance_to(target_position)
	var base_multiplier := _get_base_speed_multiplier(boss)

	if _state != AttackState.NEUTRAL:
		_tick_attack_state(delta, boss, base_multiplier)
		return

	if bool(boss.call("is_low_health")) and not _phase_transition_played:
		_start_phase_transition(boss)
		return

	if bool(boss.call("is_low_health")) and _summon_cooldown_remaining <= 0.0:
		_start_summon(boss)
		return

	if distance >= _get_boss_float(boss, "far_distance", 270.0):
		if _charge_cooldown_remaining <= 0.0:
			_start_charge(boss, to_target)
		else:
			action.moving_direction = to_target
			_set_boss_speed(boss, base_multiplier)
		return

	if distance >= _get_boss_float(boss, "mid_distance", 120.0):
		action.moving_direction = to_target
		_set_boss_speed(boss, base_multiplier)
		_try_start_spit(boss, target_position)
		return

	var lateral_direction := to_target.rotated(PI * 0.5 * _strafe_direction)
	action.moving_direction = lateral_direction - to_target * 0.25
	_set_boss_speed(boss, base_multiplier)
	_try_start_spit(boss, target_position)


func on_wall_collision(collision: KinematicCollision2D) -> void:
	var boss := get_parent()
	_strafe_direction *= -1.0
	if boss != null and _state == AttackState.CHARGING:
		_start_recovery(boss, _get_boss_float(boss, "wall_stun_duration", 1.2), true)
		return
	action.moving_direction = collision.get_normal()


func _tick_attack_state(delta: float, boss: Node, base_multiplier: float) -> void:
	_state_time_remaining = maxf(0.0, _state_time_remaining - delta)

	match _state:
		AttackState.CHARGE_WINDUP:
			action.moving_direction = Vector2.ZERO
			_set_boss_speed(boss, 0.0)
			if _state_time_remaining <= 0.0:
				_state = AttackState.CHARGING
				_state_time_remaining = _get_boss_float(boss, "charge_duration", 0.42)
				action.moving_direction = _charge_direction
				_set_boss_speed(boss, base_multiplier * _get_boss_float(boss, "charge_speed_multiplier", 2.55))
				boss.call("play_charge_release", _state_time_remaining)

		AttackState.CHARGING:
			action.moving_direction = _charge_direction
			_set_boss_speed(boss, base_multiplier * _get_boss_float(boss, "charge_speed_multiplier", 2.55))
			if _state_time_remaining <= 0.0:
				_start_recovery(boss, _get_boss_float(boss, "charge_recovery", 0.85))

		AttackState.SPIT_WINDUP:
			action.moving_direction = Vector2.ZERO
			_set_boss_speed(boss, 0.0)
			if _state_time_remaining <= 0.0:
				boss.call("request_poison_spit", _pending_target_position)
				_start_recovery(boss, _get_boss_float(boss, "spit_recovery", 0.78))

		AttackState.SUMMON_WINDUP:
			action.moving_direction = Vector2.ZERO
			_set_boss_speed(boss, 0.0)
			if _state_time_remaining <= 0.0:
				var summoned := bool(boss.call("request_low_health_summon"))
				var cooldown := _get_boss_float(boss, "low_health_summon_cooldown", 8.0)
				_summon_cooldown_remaining = cooldown if summoned else 1.0
				_start_recovery(boss, _get_boss_float(boss, "summon_recovery", 0.85))

		AttackState.PHASE_TRANSITION:
			action.moving_direction = Vector2.ZERO
			_set_boss_speed(boss, 0.0)
			if _state_time_remaining <= 0.0:
				_start_recovery(boss, _get_boss_float(boss, "phase_transition_recovery", 0.55))

		AttackState.RECOVERY:
			action.moving_direction = Vector2.ZERO
			_set_boss_speed(boss, 0.0)
			if _state_time_remaining <= 0.0:
				_state = AttackState.NEUTRAL
				_set_boss_speed(boss, base_multiplier)
				boss.call("finish_attack_visual")


func _start_charge(boss: Node, direction: Vector2) -> void:
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	_charge_direction = direction.normalized()
	_state = AttackState.CHARGE_WINDUP
	_state_time_remaining = _get_boss_float(boss, "charge_windup", 0.72)
	_charge_cooldown_remaining = _get_boss_float(boss, "charge_cooldown", 4.0)
	action.moving_direction = Vector2.ZERO
	_set_boss_speed(boss, 0.0)
	boss.call("play_charge_windup", _charge_direction, _state_time_remaining)


func _try_start_spit(boss: Node, target_position: Vector2) -> void:
	if _spit_cooldown_remaining > 0.0:
		return
	if global_position.distance_to(target_position) > _get_boss_float(boss, "spit_range", 360.0):
		return

	_pending_target_position = target_position
	_state = AttackState.SPIT_WINDUP
	_state_time_remaining = _get_boss_float(boss, "spit_windup", 0.58)
	_spit_cooldown_remaining = _get_boss_float(boss, "spit_cooldown", 2.1)
	action.moving_direction = Vector2.ZERO
	_set_boss_speed(boss, 0.0)
	boss.call("play_spit_windup", _state_time_remaining)


func _start_summon(boss: Node) -> void:
	_state = AttackState.SUMMON_WINDUP
	_state_time_remaining = _get_boss_float(boss, "summon_windup", 0.9)
	action.moving_direction = Vector2.ZERO
	_set_boss_speed(boss, 0.0)
	boss.call("play_summon_windup", _state_time_remaining)


func _start_phase_transition(boss: Node) -> void:
	_phase_transition_played = true
	_state = AttackState.PHASE_TRANSITION
	_state_time_remaining = _get_boss_float(boss, "phase_transition_duration", 1.05)
	action.moving_direction = Vector2.ZERO
	_set_boss_speed(boss, 0.0)
	boss.call("play_phase_transition", _state_time_remaining)


func _start_recovery(boss: Node, duration: float, wall_stun := false) -> void:
	_state = AttackState.RECOVERY
	_state_time_remaining = maxf(0.05, duration)
	action.moving_direction = Vector2.ZERO
	_set_boss_speed(boss, 0.0)
	boss.call("play_recovery", _state_time_remaining, wall_stun)


func _cancel_current_action(boss: Node) -> void:
	_state = AttackState.NEUTRAL
	_state_time_remaining = 0.0
	action.moving_direction = Vector2.ZERO
	_set_boss_speed(boss, 1.0)
	if boss.has_method("finish_attack_visual"):
		boss.call("finish_attack_visual")


func _set_boss_speed(boss: Node, multiplier: float) -> void:
	if boss.has_method("set_movement_speed_multiplier"):
		boss.call("set_movement_speed_multiplier", multiplier)
	elif physics_stats != null:
		physics_stats.max_speed *= multiplier


func _get_base_speed_multiplier(boss: Node) -> float:
	if boss.has_method("get_base_speed_multiplier"):
		return float(boss.call("get_base_speed_multiplier"))
	return 1.0


func _get_boss_float(boss: Node, property_name: StringName, fallback: float) -> float:
	var value: Variant = boss.get(property_name)
	if value == null:
		return fallback
	return float(value)
