extends QuiverCharacterBehavior


enum State {
	CHASE,
	WINDUP,
	CHARGE,
	RECOVERY,
}

@onready var player_detector := $PlayerDetector

var _state := State.CHASE
var _state_time := 0.0
var _attack_cooldown := randf_range(0.55, 1.2)
var _charge_direction := Vector2.RIGHT


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
	if _attack_cooldown <= 0.0 and distance >= 82.0 and distance <= 260.0:
		_start_windup(enemy, to_target)
		return

	action.moving_direction = to_target
	enemy.call("set_speed_multiplier", 1.0)
	enemy.call("play_idle")


func on_wall_collision(collision: KinematicCollision2D) -> void:
	var enemy := get_parent()
	if enemy != null and _state == State.CHARGE:
		_start_recovery(enemy, collision.get_normal())
		return
	action.moving_direction = collision.get_normal()


func on_enemy_collision(collision: KinematicCollision2D) -> void:
	if _state == State.CHARGE:
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
				_state = State.CHARGE
				_state_time = 0.64
				action.moving_direction = _charge_direction
				enemy.call("set_speed_multiplier", 4.85)
				enemy.call("begin_charge", _charge_direction)
		State.CHARGE:
			action.moving_direction = _charge_direction
			enemy.call("set_speed_multiplier", 4.85)
			var hit_player := bool(enemy.call("tick_charge_attack", _charge_direction))
			if hit_player or _state_time <= 0.0:
				_start_recovery(enemy, -_charge_direction)
		State.RECOVERY:
			action.moving_direction = Vector2.ZERO
			enemy.call("set_speed_multiplier", 0.0)
			if _state_time <= 0.0:
				_state = State.CHASE
				enemy.call("set_speed_multiplier", 1.0)
				enemy.call("finish_attack")


func _start_windup(enemy: Node, direction: Vector2) -> void:
	_charge_direction = direction.normalized()
	if _charge_direction.length() < 0.01:
		_charge_direction = Vector2.RIGHT
	_state = State.WINDUP
	_state_time = 0.58
	_attack_cooldown = 2.35
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_windup", _charge_direction, _state_time)


func _start_recovery(enemy: Node, impact_direction: Vector2) -> void:
	_state = State.RECOVERY
	_state_time = 0.6
	action.moving_direction = Vector2.ZERO
	enemy.call("set_speed_multiplier", 0.0)
	enemy.call("play_impact", impact_direction)
