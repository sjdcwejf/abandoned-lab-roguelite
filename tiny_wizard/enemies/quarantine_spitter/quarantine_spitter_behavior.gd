extends QuiverCharacterBehavior


enum AttackState {
	MOBILE,
	WINDUP,
	RECOVERY,
}

@export var retreat_distance := 165.0
@export var approach_distance := 310.0
@export var fire_range := 350.0
@export var fire_cooldown := 2.5
@export var fire_windup := 0.62
@export var fire_recovery := 0.55

@onready var player_detector := $PlayerDetector

var _state := AttackState.MOBILE
var _state_timer := 0.0
var _fire_cooldown_remaining := randf_range(0.8, 1.7)
var _pending_target_position := Vector2.ZERO
var _strafe_direction := 1.0


func _process(delta: float) -> void:
	var enemy := get_parent()
	if enemy == null:
		return

	_fire_cooldown_remaining = maxf(0.0, _fire_cooldown_remaining - delta)
	if _state != AttackState.MOBILE:
		_tick_attack_state(delta, enemy)
		return

	if player_detector == null or not player_detector.player_is_in_range():
		action.moving_direction = Vector2.ZERO
		return

	var target_position: Vector2 = player_detector.get_player_position()
	var to_target := global_position.direction_to(target_position)
	var distance := global_position.distance_to(target_position)
	if _fire_cooldown_remaining <= 0.0 and distance <= fire_range:
		_start_windup(enemy, target_position)
		return

	var lateral := to_target.rotated(PI * 0.5 * _strafe_direction)
	if distance < retreat_distance:
		action.moving_direction = -to_target + lateral * 0.25
	elif distance > approach_distance:
		action.moving_direction = to_target + lateral * 0.2
	else:
		action.moving_direction = lateral


func on_wall_collision(collision: KinematicCollision2D) -> void:
	_strafe_direction *= -1.0
	action.moving_direction = collision.get_normal()


func _start_windup(enemy: Node, target_position: Vector2) -> void:
	_state = AttackState.WINDUP
	_state_timer = fire_windup
	_pending_target_position = target_position
	_fire_cooldown_remaining = fire_cooldown
	action.moving_direction = Vector2.ZERO
	enemy.call("play_fire_windup", target_position, fire_windup)


func _tick_attack_state(delta: float, enemy: Node) -> void:
	_state_timer = maxf(0.0, _state_timer - delta)
	action.moving_direction = Vector2.ZERO
	if _state_timer > 0.0:
		return

	if _state == AttackState.WINDUP:
		enemy.call("request_fire", _pending_target_position)
		_state = AttackState.RECOVERY
		_state_timer = fire_recovery
		return

	_state = AttackState.MOBILE
	enemy.call("finish_attack_visual")
