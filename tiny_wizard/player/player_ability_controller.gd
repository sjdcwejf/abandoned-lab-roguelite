class_name LabPlayerAbilityController
extends Node2D


const ABILITY_PANSHI := "panshi"
const ABILITY_LIUYING := "liuying"
const ABILITY_HUISHENG := "huisheng"
const META_ORIGINAL_SPEED := "echo_original_speed"
const META_VULNERABLE_DAMAGE_MULTIPLIER := "lab_vulnerable_damage_multiplier"
const META_VULNERABLE_END_TIME := "lab_vulnerable_end_time"
const VULNERABLE_MARK_NAME := "LiuyingVulnerableMark"
const LIUYING_DECOY_GROUP := "lab_decoy_targets"
const META_DECOY_OWNER := "lab_decoy_owner"
const META_DECOY_EXPIRES_AT := "lab_decoy_expires_at"

@export_enum("panshi", "liuying", "huisheng") var ability_id := ABILITY_PANSHI
@export var enemy_collision_mask := 8

@export_group("Panshi")
@export var panshi_cooldown := 12.0
@export var panshi_duration := 4.0
@export var panshi_shield_gain := 2
@export var panshi_damage_multiplier := 0.7
@export var panshi_pulse_radius := 132.0
@export var panshi_pulse_damage := 1
@export var panshi_energy_cost := 40.0

@export_group("Liuying")
@export var liuying_charge_count := 2
@export var liuying_charge_cooldown := 8.0
@export var liuying_dash_distance := 315.0
@export var liuying_dash_hit_radius := 42.0
@export var liuying_dash_damage_ratio := 0.5
@export var liuying_vulnerable_damage_multiplier := 1.2
@export var liuying_vulnerable_duration := 3.0
@export var liuying_invulnerable_time := 0.18
@export_range(0.0, 1.0, 0.01) var liuying_dodge_chance := 0.15
@export var liuying_momentum_required_time := 2.0
@export var liuying_momentum_speed_multiplier := 1.2
@export var liuying_afterimage_interval := 0.08
@export var liuying_afterimage_lifetime := 0.5
@export var liuying_afterimage_min_distance := 14.0
@export var liuying_afterimage_color := Color(0.58, 0.78, 1.0, 0.38)
@export var liuying_afterimage_decoy_enabled := true
@export var liuying_energy_cost := 30.0
@export var liuying_fire_rate_time := 0.0
@export var liuying_fire_cooldown_multiplier := 1.0

@export_group("Huisheng")
@export var huisheng_cooldown := 9.0
@export var huisheng_pulse_radius := 180.0
@export var huisheng_pulse_damage := 1
@export var huisheng_slow_duration := 2.0
@export var huisheng_slow_multiplier := 0.55
@export var huisheng_energy_cost := 35.0

var _character: QuiverCharacter
var _cooldown_remaining := 0.0
var _active_remaining := 0.0
var _invulnerable_remaining := 0.0
var _fire_rate_remaining := 0.0
var _panshi_shield_added := 0
var _liuying_charges := 0
var _liuying_charge_timer := 0.0
var _liuying_moving_time := 0.0
var _liuying_base_speed := 0.0
var _liuying_momentum_active := false
var _liuying_afterimage_timer := 0.0
var _liuying_afterimage_position := Vector2.ZERO
var _liuying_has_afterimage_position := false
var _rng := RandomNumberGenerator.new()
var _aura_ring: Line2D
var _aura_tween: Tween


func _ready() -> void:
	_character = get_parent() as QuiverCharacter
	_rng.randomize()
	_initialize_liuying_state()
	_create_aura_ring()


func _process(delta: float) -> void:
	_tick_timers(delta)
	_update_aura_ring()

	if _character == null:
		return
	if Input.is_action_just_pressed("character_skill"):
		_try_activate()


func should_ignore_damage() -> bool:
	if _invulnerable_remaining > 0.0:
		return true
	if ability_id == ABILITY_LIUYING and liuying_dodge_chance > 0.0 and _rng.randf() < liuying_dodge_chance:
		_show_dodge_feedback()
		return true
	return false


func notify_damage_taken() -> void:
	if ability_id == ABILITY_LIUYING:
		_reset_liuying_momentum()


func modify_incoming_damage(damage: int) -> int:
	if ability_id == ABILITY_PANSHI and _active_remaining > 0.0:
		return maxi(1, ceili(float(damage) * panshi_damage_multiplier))
	return damage


func get_fire_cooldown_multiplier() -> float:
	if _fire_rate_remaining > 0.0:
		return liuying_fire_cooldown_multiplier
	return 1.0


func get_cooldown_remaining() -> float:
	if ability_id == ABILITY_LIUYING and _liuying_charges <= 0:
		return _liuying_charge_timer
	return _cooldown_remaining


func _tick_timers(delta: float) -> void:
	_tick_energy_regen(delta)
	if ability_id == ABILITY_LIUYING:
		_tick_liuying_charges(delta)
		_tick_liuying_momentum(delta)
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


func _tick_energy_regen(delta: float) -> void:
	var stats := _get_energy_stats()
	if stats == null:
		return
	var regen := float(stats.get("energy_regen_per_second"))
	if regen <= 0.0:
		return
	stats.call("restore_energy", regen * delta)


func _try_spend_energy(amount: float) -> bool:
	if amount <= 0.0:
		return true

	var stats := _get_energy_stats()
	if stats == null:
		return true

	var spent := bool(stats.call("spend_energy", amount))
	if not spent:
		_show_no_energy_feedback()
	return spent


func _get_energy_stats() -> Object:
	if _character == null:
		return null
	var stats := _character.character_stats
	if stats == null:
		return null
	if not stats.has_method("spend_energy") or not stats.has_method("restore_energy"):
		return null
	return stats


func _try_activate() -> void:
	if ability_id != ABILITY_LIUYING and _cooldown_remaining > 0.0:
		return

	match ability_id:
		ABILITY_LIUYING:
			_activate_liuying()
		ABILITY_HUISHENG:
			_activate_huisheng()
		_:
			_activate_panshi()


func _activate_panshi() -> void:
	if not _try_spend_energy(panshi_energy_cost):
		return

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
	if _liuying_charges <= 0 and _liuying_charge_timer <= 0.0:
		_initialize_liuying_state()
	if _liuying_charges <= 0:
		return
	if not _try_spend_energy(liuying_energy_cost):
		return

	_consume_liuying_charge()
	_invulnerable_remaining = liuying_invulnerable_time
	_fire_rate_remaining = liuying_fire_rate_time

	var direction := _get_liuying_dash_direction()

	var start_position := _character.global_position
	var body := _character as CharacterBody2D
	if body != null:
		body.move_and_collide(direction * liuying_dash_distance)
	else:
		_character.global_position += direction * liuying_dash_distance
	var end_position := _character.global_position

	var dash_damage := _get_liuying_dash_damage()
	_damage_targets_along_segment(start_position, end_position, liuying_dash_hit_radius, dash_damage, true)
	_show_dash_trail(start_position, end_position, Color(0.72, 0.78, 1.0, 0.92), 0.22)
	_show_pulse(Color(0.95, 0.72, 0.34, 0.85), 54.0, 0.18)


func _activate_huisheng() -> void:
	if not _try_spend_energy(huisheng_energy_cost):
		return

	_cooldown_remaining = huisheng_cooldown
	_show_pulse(Color(0.64, 0.46, 1.0, 0.92), huisheng_pulse_radius, 0.48)
	_damage_targets_in_radius(huisheng_pulse_radius, huisheng_pulse_damage, true)


func get_ability_display_name() -> String:
	match ability_id:
		ABILITY_LIUYING:
			return "Phase Assault"
		ABILITY_HUISHENG:
			return "Echo Pulse"
		_:
			return "Bulwark Protocol"


func get_ability_energy_cost() -> float:
	match ability_id:
		ABILITY_LIUYING:
			return liuying_energy_cost
		ABILITY_HUISHENG:
			return huisheng_energy_cost
		_:
			return panshi_energy_cost


func get_energy_current() -> float:
	var stats := _get_energy_stats()
	if stats == null:
		return 0.0
	return float(stats.get("current_energy"))


func get_energy_max() -> float:
	var stats := _get_energy_stats()
	if stats == null:
		return 0.0
	return float(stats.get("max_energy"))


func get_energy_ratio() -> float:
	var max_energy := get_energy_max()
	if max_energy <= 0.0:
		return 0.0
	return clampf(get_energy_current() / max_energy, 0.0, 1.0)


func get_ability_status_text() -> String:
	var energy_cost := get_ability_energy_cost()
	if get_energy_max() > 0.0 and get_energy_current() + 0.001 < energy_cost:
		return "Need %.0f energy" % energy_cost

	if ability_id == ABILITY_LIUYING:
		if _liuying_charges <= 0:
			return "Recharge %.1fs" % _liuying_charge_timer
		if _liuying_momentum_active:
			return "Momentum active"
		return "Charges %d/%d" % [_liuying_charges, _get_liuying_max_charges()]

	if _cooldown_remaining > 0.0:
		return "Cooldown %.1fs" % _cooldown_remaining
	return "Ready"


func _initialize_liuying_state() -> void:
	_liuying_charges = _get_liuying_max_charges()
	_liuying_charge_timer = 0.0
	if ability_id == ABILITY_LIUYING and _character != null and _character.physics_stats != null:
		_liuying_base_speed = _character.physics_stats.max_speed


func _get_liuying_max_charges() -> int:
	return maxi(1, liuying_charge_count)


func _consume_liuying_charge() -> void:
	var max_charges := _get_liuying_max_charges()
	_liuying_charges = mini(_liuying_charges, max_charges)
	_liuying_charges = maxi(0, _liuying_charges - 1)
	if _liuying_charges < max_charges and _liuying_charge_timer <= 0.0:
		_liuying_charge_timer = liuying_charge_cooldown


func _tick_liuying_charges(delta: float) -> void:
	var max_charges := _get_liuying_max_charges()
	_liuying_charges = mini(_liuying_charges, max_charges)
	if _liuying_charges >= max_charges:
		_liuying_charge_timer = 0.0
		return

	if _liuying_charge_timer <= 0.0:
		_liuying_charge_timer = liuying_charge_cooldown
	_liuying_charge_timer = maxf(0.0, _liuying_charge_timer - delta)
	if _liuying_charge_timer > 0.0:
		return

	_liuying_charges += 1
	if _liuying_charges < max_charges:
		_liuying_charge_timer = liuying_charge_cooldown


func _tick_liuying_momentum(delta: float) -> void:
	if _character == null or _character.physics_stats == null:
		return
	if _liuying_base_speed <= 0.0:
		_liuying_base_speed = _character.physics_stats.max_speed

	var is_moving := _get_movement_input().length() > 0.1
	if is_moving:
		_liuying_moving_time += delta
		if _liuying_moving_time >= liuying_momentum_required_time:
			_set_liuying_momentum(true)
	else:
		_reset_liuying_momentum()

	_tick_liuying_afterimages(delta, is_moving)


func _set_liuying_momentum(is_active: bool) -> void:
	if _character == null or _character.physics_stats == null:
		return
	if _liuying_momentum_active == is_active:
		return

	_liuying_momentum_active = is_active
	if is_active:
		_character.physics_stats.max_speed = _liuying_base_speed * liuying_momentum_speed_multiplier
		_show_aura(Color(0.82, 0.9, 1.0, 0.48), 58.0, 999.0)
	else:
		_character.physics_stats.max_speed = _liuying_base_speed
		_hide_aura()


func _reset_liuying_momentum() -> void:
	_liuying_moving_time = 0.0
	_set_liuying_momentum(false)
	_liuying_afterimage_timer = 0.0
	_liuying_has_afterimage_position = false


func _get_movement_input() -> Vector2:
	return Input.get_vector("player_left", "player_right", "player_up", "player_down")


func _get_liuying_dash_direction() -> Vector2:
	var direction := _get_movement_input()
	if direction.length() <= 0.0:
		direction = _character.global_position.direction_to(_character.get_global_mouse_position())
	if direction.length() <= 0.0:
		direction = Vector2.RIGHT
	return direction.normalized()


func _get_liuying_dash_damage() -> int:
	var base_damage := 2
	var weapon_holder := _character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder != null:
		var current_weapon := weapon_holder.get("current_weapon") as Object
		if current_weapon != null:
			if "damage" in current_weapon:
				base_damage = int(current_weapon.get("damage"))
			elif "punch_damage" in current_weapon:
				base_damage = int(current_weapon.get("punch_damage"))
	return maxi(1, ceili(float(base_damage) * liuying_dash_damage_ratio))


func _damage_targets_in_radius(radius: float, damage: int, apply_slow: bool) -> void:
	if _character == null or _character.get_world_2d() == null:
		return

	var hit_targets: Dictionary = {}
	_damage_targets_at_position(_character.global_position, radius, damage, apply_slow, false, hit_targets)


func _damage_targets_along_segment(start_position: Vector2, end_position: Vector2, radius: float, damage: int, apply_vulnerable: bool) -> void:
	if _character == null or _character.get_world_2d() == null:
		return

	var hit_targets: Dictionary = {}
	var distance := start_position.distance_to(end_position)
	var steps := maxi(1, ceili(distance / maxf(12.0, radius * 0.75)))
	for step in range(steps + 1):
		var weight := float(step) / float(steps)
		var sample_position := start_position.lerp(end_position, weight)
		_damage_targets_at_position(sample_position, radius, damage, false, apply_vulnerable, hit_targets)


func _damage_targets_at_position(origin: Vector2, radius: float, damage: int, apply_slow: bool, apply_vulnerable: bool, hit_targets: Dictionary) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, origin)
	query.collision_mask = enemy_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if _character is CollisionObject2D:
		query.exclude = [(_character as CollisionObject2D).get_rid()]

	var results: Array[Dictionary] = _character.get_world_2d().direct_space_state.intersect_shape(query, 32)
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
			hit_from = ((damage_target as Node2D).global_position - origin).normalized()
		damage_target.call("hit", damage, hit_from)
		if apply_slow:
			_apply_echo_slow(damage_target)
		if apply_vulnerable:
			_apply_liuying_vulnerable(damage_target)


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


func _apply_liuying_vulnerable(target: Object) -> void:
	if not target is Node:
		return

	var target_node := target as Node
	var expires_at := Time.get_ticks_msec() + int(liuying_vulnerable_duration * 1000.0)
	target_node.set_meta(META_VULNERABLE_DAMAGE_MULTIPLIER, liuying_vulnerable_damage_multiplier)
	target_node.set_meta(META_VULNERABLE_END_TIME, expires_at)
	_show_vulnerable_mark(target_node)

	var timer := get_tree().create_timer(liuying_vulnerable_duration)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(target_node):
			return
		if not target_node.has_meta(META_VULNERABLE_END_TIME):
			return
		if int(target_node.get_meta(META_VULNERABLE_END_TIME)) > Time.get_ticks_msec():
			return
		target_node.remove_meta(META_VULNERABLE_DAMAGE_MULTIPLIER)
		target_node.remove_meta(META_VULNERABLE_END_TIME)
		var mark := target_node.get_node_or_null(VULNERABLE_MARK_NAME)
		if mark != null:
			mark.queue_free()
	)


func _show_vulnerable_mark(target_node: Node) -> void:
	if not target_node is Node2D:
		return

	var mark := target_node.get_node_or_null(VULNERABLE_MARK_NAME) as Line2D
	if mark == null:
		mark = Line2D.new()
		mark.name = VULNERABLE_MARK_NAME
		mark.z_index = 32
		mark.width = 3.0
		mark.closed = true
		mark.points = _circle_points(34.0)
		target_node.add_child(mark)

	mark.position = Vector2.ZERO
	mark.default_color = Color(1.0, 0.66, 0.25, 0.9)
	mark.modulate = Color.WHITE


func _show_dodge_feedback() -> void:
	_show_pulse(Color(0.76, 0.88, 1.0, 0.85), 42.0, 0.14)


func _show_no_energy_feedback() -> void:
	_show_pulse(Color(0.95, 0.22, 0.28, 0.82), 38.0, 0.12)


func _tick_liuying_afterimages(delta: float, is_moving: bool) -> void:
	if ability_id != ABILITY_LIUYING or _character == null:
		return
	if not is_moving:
		_liuying_afterimage_timer = 0.0
		_liuying_has_afterimage_position = false
		return

	_liuying_afterimage_timer -= delta
	if _liuying_afterimage_timer > 0.0:
		return

	var current_position := _character.global_position
	if _liuying_has_afterimage_position:
		var moved_distance := current_position.distance_to(_liuying_afterimage_position)
		if moved_distance < liuying_afterimage_min_distance:
			return

	_spawn_liuying_afterimage()
	_liuying_afterimage_position = current_position
	_liuying_has_afterimage_position = true
	_liuying_afterimage_timer = liuying_afterimage_interval


func _spawn_liuying_afterimage() -> void:
	if _character == null:
		return

	var visual := _character.get_node_or_null("Visual") as Node2D
	if visual == null:
		return

	var afterimage := Node2D.new()
	afterimage.name = "LiuyingAfterimage"
	afterimage.top_level = true
	afterimage.z_as_relative = false
	afterimage.z_index = 18
	add_child(afterimage)
	afterimage.global_transform = visual.global_transform
	afterimage.modulate = liuying_afterimage_color
	if liuying_afterimage_decoy_enabled:
		afterimage.add_to_group(LIUYING_DECOY_GROUP)
		afterimage.set_meta(META_DECOY_OWNER, _character)
		afterimage.set_meta(META_DECOY_EXPIRES_AT, Time.get_ticks_msec() + int(liuying_afterimage_lifetime * 1000.0))

	var copied_any := false
	for child_name in ["Shadow", "Body", "Head", "Hat"]:
		var source := visual.get_node_or_null(child_name)
		var copy := _duplicate_afterimage_part(source)
		if copy == null:
			continue
		afterimage.add_child(copy)
		copied_any = true

	if not copied_any:
		afterimage.queue_free()
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(afterimage, "modulate", Color(liuying_afterimage_color.r, liuying_afterimage_color.g, liuying_afterimage_color.b, 0.0), liuying_afterimage_lifetime).set_ease(Tween.EASE_OUT)
	tween.tween_property(afterimage, "scale", afterimage.scale * 1.03, liuying_afterimage_lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(afterimage, "queue_free"))


func _duplicate_afterimage_part(source: Node) -> Node:
	if source == null:
		return null
	if not source is CanvasItem:
		return null

	var copy := source.duplicate()
	copy.name = "%sAfterimage" % source.name
	copy.process_mode = Node.PROCESS_MODE_DISABLED
	if copy is AnimatedSprite2D:
		(copy as AnimatedSprite2D).stop()
	if copy is CanvasItem:
		var canvas_copy := copy as CanvasItem
		canvas_copy.modulate = Color.WHITE
		canvas_copy.self_modulate = Color.WHITE
	return copy


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
