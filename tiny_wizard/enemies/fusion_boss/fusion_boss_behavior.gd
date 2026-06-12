extends QuiverCharacterBehavior


@onready var player_detector := $PlayerDetector

var _charge_cooldown_remaining := randf_range(1.0, 2.2)
var _charge_time_remaining := 0.0
var _spit_cooldown_remaining := randf_range(0.8, 1.4)
var _summon_cooldown_remaining := 3.0
var _charge_direction := Vector2.RIGHT
var _strafe_direction := 1.0


func _process(delta: float) -> void:
	var boss := get_parent()
	if boss == null:
		return

	_charge_cooldown_remaining = maxf(0.0, _charge_cooldown_remaining - delta)
	_spit_cooldown_remaining = maxf(0.0, _spit_cooldown_remaining - delta)
	_summon_cooldown_remaining = maxf(0.0, _summon_cooldown_remaining - delta)

	if _charge_time_remaining > 0.0:
		_charge_time_remaining -= delta
		action.moving_direction = _charge_direction
		_set_boss_speed(boss, _get_boss_float(boss, "charge_speed_multiplier", 2.55))
		return

	var has_target: bool = player_detector != null and player_detector.player_is_in_range()
	if not has_target:
		action.moving_direction = Vector2.ZERO
		_set_boss_speed(boss, 1.0)
		return

	var target_position: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target_position)
	var distance := global_position.distance_to(target_position)
	var base_multiplier := _get_base_speed_multiplier(boss)

	if bool(boss.call("is_low_health")):
		_try_summon(boss)

	if distance >= _get_boss_float(boss, "far_distance", 270.0):
		if _charge_cooldown_remaining <= 0.0:
			_start_charge(boss, to_target, base_multiplier)
		else:
			action.moving_direction = to_target
			_set_boss_speed(boss, base_multiplier)
		return

	if distance >= _get_boss_float(boss, "mid_distance", 120.0):
		action.moving_direction = to_target
		_set_boss_speed(boss, base_multiplier)
		_try_spit(boss, target_position)
		return

	var lateral_direction := to_target.rotated(PI * 0.5 * _strafe_direction)
	action.moving_direction = lateral_direction - to_target * 0.25
	_set_boss_speed(boss, base_multiplier)
	_try_spit(boss, target_position)


func on_wall_collision(collision: KinematicCollision2D) -> void:
	_strafe_direction *= -1.0
	action.moving_direction = collision.get_normal()


func _start_charge(boss: Node, direction: Vector2, base_multiplier: float) -> void:
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	_charge_direction = direction.normalized()
	_charge_time_remaining = _get_boss_float(boss, "charge_duration", 0.42)
	_charge_cooldown_remaining = _get_boss_float(boss, "charge_cooldown", 4.0)
	action.moving_direction = _charge_direction
	_set_boss_speed(boss, base_multiplier * _get_boss_float(boss, "charge_speed_multiplier", 2.55))


func _try_spit(boss: Node, target_position: Vector2) -> void:
	if _spit_cooldown_remaining > 0.0:
		return
	if global_position.distance_to(target_position) > _get_boss_float(boss, "spit_range", 360.0):
		return

	boss.call("request_poison_spit", target_position)
	_spit_cooldown_remaining = _get_boss_float(boss, "spit_cooldown", 2.1)


func _try_summon(boss: Node) -> void:
	if _summon_cooldown_remaining > 0.0:
		return

	var summoned := bool(boss.call("request_low_health_summon"))
	var cooldown := _get_boss_float(boss, "low_health_summon_cooldown", 8.0)
	_summon_cooldown_remaining = cooldown if summoned else 1.0


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
