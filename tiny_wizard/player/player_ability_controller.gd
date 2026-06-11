class_name LabPlayerAbilityController
extends Node2D


const ABILITY_PANSHI := "panshi"
const ABILITY_LIUYING := "liuying"
const ABILITY_HUISHENG := "huisheng"
const META_ORIGINAL_SPEED := "echo_original_speed"

@export_enum("panshi", "liuying", "huisheng") var ability_id := ABILITY_PANSHI
@export var enemy_collision_mask := 8

@export_group("Panshi")
@export var panshi_cooldown := 12.0
@export var panshi_duration := 4.0
@export var panshi_shield_gain := 2
@export var panshi_damage_multiplier := 0.7
@export var panshi_pulse_radius := 132.0
@export var panshi_pulse_damage := 1

@export_group("Liuying")
@export var liuying_cooldown := 5.0
@export var liuying_dash_distance := 205.0
@export var liuying_invulnerable_time := 0.18
@export var liuying_fire_rate_time := 1.5
@export var liuying_fire_cooldown_multiplier := 0.75

@export_group("Huisheng")
@export var huisheng_cooldown := 9.0
@export var huisheng_pulse_radius := 180.0
@export var huisheng_pulse_damage := 1
@export var huisheng_slow_duration := 2.0
@export var huisheng_slow_multiplier := 0.55

var _character: QuiverCharacter
var _cooldown_remaining := 0.0
var _active_remaining := 0.0
var _invulnerable_remaining := 0.0
var _fire_rate_remaining := 0.0
var _panshi_shield_added := 0
var _aura_ring: Line2D
var _aura_tween: Tween


func _ready() -> void:
	_character = get_parent() as QuiverCharacter
	_create_aura_ring()


func _process(delta: float) -> void:
	_tick_timers(delta)
	_update_aura_ring()

	if _character == null:
		return
	if Input.is_action_just_pressed("character_skill"):
		_try_activate()


func should_ignore_damage() -> bool:
	return _invulnerable_remaining > 0.0


func modify_incoming_damage(damage: int) -> int:
	if ability_id == ABILITY_PANSHI and _active_remaining > 0.0:
		return maxi(1, ceili(float(damage) * panshi_damage_multiplier))
	return damage


func get_fire_cooldown_multiplier() -> float:
	if _fire_rate_remaining > 0.0:
		return liuying_fire_cooldown_multiplier
	return 1.0


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func _tick_timers(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if _invulnerable_remaining > 0.0:
		_invulnerable_remaining = maxf(0.0, _invulnerable_remaining - delta)
	if _fire_rate_remaining > 0.0:
		_fire_rate_remaining = maxf(0.0, _fire_rate_remaining - delta)
	if _active_remaining > 0.0:
		_active_remaining = maxf(0.0, _active_remaining - delta)
		if _active_remaining <= 0.0 and ability_id == ABILITY_PANSHI:
			_end_panshi_protocol()


func _try_activate() -> void:
	if _cooldown_remaining > 0.0:
		return

	match ability_id:
		ABILITY_LIUYING:
			_activate_liuying()
		ABILITY_HUISHENG:
			_activate_huisheng()
		_:
			_activate_panshi()


func _activate_panshi() -> void:
	_cooldown_remaining = panshi_cooldown
	_active_remaining = panshi_duration
	_panshi_shield_added = 0

	var stats := _character.character_stats
	if "current_shield" in stats:
		stats.current_shield += panshi_shield_gain
		_panshi_shield_added = panshi_shield_gain

	_show_aura(Color(0.42, 0.9, 1.0, 0.82), 78.0, panshi_duration)
	_show_pulse(Color(0.38, 0.9, 1.0, 0.9), panshi_pulse_radius, 0.35)
	_damage_targets_in_radius(panshi_pulse_radius, panshi_pulse_damage, false)


func _end_panshi_protocol() -> void:
	if _character == null:
		return
	var stats := _character.character_stats
	if "current_shield" in stats and _panshi_shield_added > 0:
		stats.current_shield = maxi(0, stats.current_shield - _panshi_shield_added)
	_panshi_shield_added = 0
	_hide_aura()


func _activate_liuying() -> void:
	_cooldown_remaining = liuying_cooldown
	_invulnerable_remaining = liuying_invulnerable_time
	_fire_rate_remaining = liuying_fire_rate_time

	var direction := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	if direction.length() <= 0.0:
		direction = -_character.global_position.direction_to(_character.get_global_mouse_position())
	if direction.length() <= 0.0:
		direction = Vector2.RIGHT
	direction = direction.normalized()

	var start_position := _character.global_position
	var body := _character as CharacterBody2D
	if body != null:
		body.move_and_collide(direction * liuying_dash_distance)
	else:
		_character.global_position += direction * liuying_dash_distance
	var end_position := _character.global_position

	_show_dash_trail(start_position, end_position, Color(0.95, 0.62, 0.24, 0.9), 0.22)
	_show_aura(Color(0.95, 0.62, 0.24, 0.55), 58.0, liuying_fire_rate_time)


func _activate_huisheng() -> void:
	_cooldown_remaining = huisheng_cooldown
	_show_pulse(Color(0.64, 0.46, 1.0, 0.92), huisheng_pulse_radius, 0.48)
	_damage_targets_in_radius(huisheng_pulse_radius, huisheng_pulse_damage, true)


func _damage_targets_in_radius(radius: float, damage: int, apply_slow: bool) -> void:
	if _character == null or _character.get_world_2d() == null:
		return

	var shape := CircleShape2D.new()
	shape.radius = radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, _character.global_position)
	query.collision_mask = enemy_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if _character is CollisionObject2D:
		query.exclude = [(_character as CollisionObject2D).get_rid()]

	var results: Array[Dictionary] = _character.get_world_2d().direct_space_state.intersect_shape(query, 32)
	var hit_targets: Dictionary = {}
	for result in results:
		var collider: Object = result.get("collider") as Object
		var damage_target: Object = _find_damage_target(collider)
		if damage_target == null:
			continue
		var instance_id: int = damage_target.get_instance_id()
		if hit_targets.has(instance_id):
			continue
		hit_targets[instance_id] = true

		var hit_from := Vector2.ZERO
		if damage_target is Node2D:
			hit_from = ((damage_target as Node2D).global_position - _character.global_position).normalized()
		damage_target.call("hit", damage, hit_from)
		if apply_slow:
			_apply_echo_slow(damage_target)


func _find_damage_target(target: Object) -> Object:
	if target == null or target == _character:
		return null
	if target.has_method("hit"):
		return target
	if not target is Node:
		return null

	var current := (target as Node).get_parent()
	while current != null:
		if current == _character:
			return null
		if current.has_method("hit"):
			return current
		current = current.get_parent()
	return null


func _apply_echo_slow(target: Object) -> void:
	if not target is QuiverCharacter:
		return

	var slowed_character := target as QuiverCharacter
	var physics_stats := slowed_character.physics_stats
	if physics_stats == null:
		return

	if not slowed_character.has_meta(META_ORIGINAL_SPEED):
		slowed_character.set_meta(META_ORIGINAL_SPEED, physics_stats.max_speed)

	var original_speed := float(slowed_character.get_meta(META_ORIGINAL_SPEED))
	physics_stats.max_speed = minf(physics_stats.max_speed, original_speed * huisheng_slow_multiplier)

	var timer := get_tree().create_timer(huisheng_slow_duration)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(slowed_character):
			return
		if slowed_character.has_meta(META_ORIGINAL_SPEED):
			var speed := float(slowed_character.get_meta(META_ORIGINAL_SPEED))
			if slowed_character.physics_stats != null:
				slowed_character.physics_stats.max_speed = speed
			slowed_character.remove_meta(META_ORIGINAL_SPEED)
	)


func _create_aura_ring() -> void:
	_aura_ring = Line2D.new()
	_aura_ring.name = "AbilityAura"
	_aura_ring.visible = false
	_aura_ring.top_level = true
	_aura_ring.z_index = 25
	_aura_ring.width = 3.0
	_aura_ring.closed = true
	add_child(_aura_ring)


func _update_aura_ring() -> void:
	if _aura_ring == null or not _aura_ring.visible or _character == null:
		return
	_aura_ring.global_position = _character.global_position


func _show_aura(color: Color, radius: float, duration: float) -> void:
	if _aura_ring == null:
		return
	if _aura_tween != null:
		_aura_tween.kill()

	_aura_ring.points = _circle_points(radius)
	_aura_ring.default_color = color
	_aura_ring.modulate = Color.WHITE
	_aura_ring.visible = true
	_update_aura_ring()

	_aura_tween = create_tween()
	_aura_tween.tween_interval(maxf(0.05, duration))
	_aura_tween.tween_property(_aura_ring, "modulate", Color(1, 1, 1, 0), 0.18)
	_aura_tween.tween_callback(_hide_aura)


func _hide_aura() -> void:
	if _aura_ring != null:
		_aura_ring.visible = false


func _show_pulse(color: Color, radius: float, duration: float) -> void:
	if _character == null:
		return

	var pulse := Line2D.new()
	pulse.name = "AbilityPulse"
	pulse.top_level = true
	pulse.z_index = 24
	pulse.width = 5.0
	pulse.closed = true
	pulse.default_color = color
	pulse.points = _circle_points(16.0)
	pulse.global_position = _character.global_position
	pulse.scale = Vector2.ONE
	add_child(pulse)

	var target_scale := Vector2(radius / 16.0, radius / 16.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "modulate", Color(1, 1, 1, 0), duration).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(pulse, "queue_free"))


func _show_dash_trail(start_position: Vector2, end_position: Vector2, color: Color, duration: float) -> void:
	var trail := Line2D.new()
	trail.name = "ReflexTrail"
	trail.top_level = true
	trail.z_index = 24
	trail.width = 9.0
	trail.default_color = color
	trail.points = PackedVector2Array([start_position, end_position])
	trail.global_position = Vector2.ZERO
	add_child(trail)

	var tween := create_tween()
	tween.tween_property(trail, "modulate", Color(1, 1, 1, 0), duration).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(trail, "queue_free"))


func _circle_points(radius: float, segments := 48) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
