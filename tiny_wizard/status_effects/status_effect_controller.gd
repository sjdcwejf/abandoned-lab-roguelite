class_name LabStatusEffectController
extends Node2D


const STATUS_CONTROLLER_NAME := "StatusEffectController"
const STATUS_VULNERABLE := "vulnerable"
const STATUS_SLOW := "slow"
const STATUS_CORROSION := "corrosion"
const META_PENDING_CONTROLLER := "lab_status_effect_controller_pending"
const META_VULNERABLE_DAMAGE_MULTIPLIER := "lab_vulnerable_damage_multiplier"
const META_VULNERABLE_END_TIME := "lab_vulnerable_end_time"

var _target: Node
var _effects := {}
var _visuals := {}


static func apply_vulnerable(target: Object, duration: float, damage_multiplier: float) -> void:
	var controller = get_or_create(target)
	if controller == null:
		return

	controller.apply_status(STATUS_VULNERABLE, {
		"duration": duration,
		"damage_multiplier": damage_multiplier,
		"visual_color": Color(1.0, 0.66, 0.25, 0.9),
		"visual_radius": 34.0,
	})


static func apply_slow(target: Object, duration: float, speed_multiplier: float) -> void:
	var controller = get_or_create(target)
	if controller == null:
		return

	controller.apply_status(STATUS_SLOW, {
		"duration": duration,
		"speed_multiplier": speed_multiplier,
		"visual_color": Color(0.64, 0.46, 1.0, 0.82),
		"visual_radius": 42.0,
	})


static func apply_damage_over_time(target: Object, status_id := STATUS_CORROSION, duration := 4.0, damage := 1, tick_interval := 1.0, visual_color := Color(0.42, 1.0, 0.48, 0.86)) -> void:
	var controller = get_or_create(target)
	if controller == null:
		return

	controller.apply_status(status_id, {
		"duration": duration,
		"tick_damage": maxi(0, damage),
		"tick_interval": maxf(0.05, tick_interval),
		"visual_color": visual_color,
		"visual_radius": 48.0,
	})


static func get_or_create(target: Object):
	if not target is Node:
		return null

	var target_node := target as Node
	var existing := target_node.get_node_or_null(STATUS_CONTROLLER_NAME)
	if existing != null and existing.has_method("apply_status"):
		return existing
	if target_node.has_meta(META_PENDING_CONTROLLER):
		var pending = target_node.get_meta(META_PENDING_CONTROLLER)
		if pending is Node and is_instance_valid(pending) and (pending as Node).has_method("apply_status"):
			return pending

	var script := load("res://tiny_wizard/status_effects/status_effect_controller.gd") as Script
	var controller = script.new()
	controller.name = STATUS_CONTROLLER_NAME
	controller.set("_target", target_node)
	target_node.set_meta(META_PENDING_CONTROLLER, controller)
	target_node.call_deferred("add_child", controller)
	return controller


func _ready() -> void:
	if _target == null:
		_target = get_parent()
	if _target != null and _target.has_meta(META_PENDING_CONTROLLER):
		var pending = _target.get_meta(META_PENDING_CONTROLLER)
		if pending == self:
			_target.remove_meta(META_PENDING_CONTROLLER)


func _process(delta: float) -> void:
	var expired_statuses := []
	for status_id in _effects.keys():
		var effect := (_effects[status_id] as Dictionary).duplicate()
		_tick_damage_over_time(status_id, effect, delta)
		effect["remaining"] = maxf(0.0, float(effect.get("remaining", 0.0)) - delta)
		if float(effect["remaining"]) <= 0.0:
			expired_statuses.append(status_id)
		else:
			_effects[status_id] = effect
			_update_status_visual(status_id, effect)

	for status_id in expired_statuses:
		_remove_status(status_id)


func apply_status(status_id: String, options: Dictionary) -> void:
	var effect := {}
	var existing = _effects.get(status_id, null)
	if existing is Dictionary:
		effect = (existing as Dictionary).duplicate()

	var duration := maxf(0.05, float(options.get("duration", effect.get("duration", 1.0))))
	var current_remaining := float(effect.get("remaining", 0.0))
	effect["duration"] = maxf(duration, float(effect.get("duration", duration)))
	effect["remaining"] = maxf(current_remaining, duration)

	for key in options.keys():
		if key == "duration":
			continue
		effect[key] = options[key]

	if not effect.has("tick_timer") and effect.has("tick_interval"):
		effect["tick_timer"] = float(effect["tick_interval"])

	effect = _apply_status_mutators(status_id, effect)
	_effects[status_id] = effect
	_refresh_status_visual(status_id, effect)


func _apply_status_mutators(status_id: String, effect: Dictionary) -> Dictionary:
	match status_id:
		STATUS_VULNERABLE:
			_apply_vulnerable_mutator(effect)
		STATUS_SLOW:
			effect = _apply_slow_mutator(effect)
	return effect


func _apply_vulnerable_mutator(effect: Dictionary) -> void:
	var target := _get_target()
	if target == null:
		return

	var damage_multiplier := maxf(1.0, float(effect.get("damage_multiplier", 1.0)))
	var remaining := float(effect.get("remaining", 0.0))
	target.set_meta(META_VULNERABLE_DAMAGE_MULTIPLIER, damage_multiplier)
	target.set_meta(META_VULNERABLE_END_TIME, Time.get_ticks_msec() + int(remaining * 1000.0))


func _apply_slow_mutator(effect: Dictionary) -> Dictionary:
	var target := _get_target()
	if target == null or not "physics_stats" in target:
		return effect

	var physics_stats = target.get("physics_stats")
	if physics_stats == null or not "max_speed" in physics_stats:
		return effect

	if not effect.has("original_speed"):
		effect["original_speed"] = float(physics_stats.get("max_speed"))

	var original_speed := float(effect.get("original_speed", physics_stats.get("max_speed")))
	var speed_multiplier := clampf(float(effect.get("speed_multiplier", 1.0)), 0.05, 1.0)
	physics_stats.set("max_speed", minf(float(physics_stats.get("max_speed")), original_speed * speed_multiplier))
	return effect


func _tick_damage_over_time(_status_id: String, effect: Dictionary, delta: float) -> void:
	var tick_damage := int(effect.get("tick_damage", 0))
	if tick_damage <= 0:
		return

	var target := _get_target()
	if target == null or not target.has_method("hit"):
		return

	var tick_interval := maxf(0.05, float(effect.get("tick_interval", 1.0)))
	var tick_timer := float(effect.get("tick_timer", tick_interval)) - delta
	while tick_timer <= 0.0 and float(effect.get("remaining", 0.0)) > 0.0:
		target.call("hit", tick_damage, Vector2.ZERO)
		tick_timer += tick_interval

	effect["tick_timer"] = tick_timer


func _remove_status(status_id: String) -> void:
	var effect := _effects.get(status_id, {}) as Dictionary
	match status_id:
		STATUS_VULNERABLE:
			_remove_vulnerable_mutator()
		STATUS_SLOW:
			_remove_slow_mutator(effect)

	_effects.erase(status_id)
	var visual = _visuals.get(status_id, null)
	if visual is Node:
		(visual as Node).queue_free()
	_visuals.erase(status_id)


func _remove_vulnerable_mutator() -> void:
	var target := _get_target()
	if target == null:
		return
	if target.has_meta(META_VULNERABLE_DAMAGE_MULTIPLIER):
		target.remove_meta(META_VULNERABLE_DAMAGE_MULTIPLIER)
	if target.has_meta(META_VULNERABLE_END_TIME):
		target.remove_meta(META_VULNERABLE_END_TIME)


func _remove_slow_mutator(effect: Dictionary) -> void:
	var target := _get_target()
	if target == null or not "physics_stats" in target:
		return

	var physics_stats = target.get("physics_stats")
	if physics_stats == null or not "max_speed" in physics_stats:
		return

	if effect.has("original_speed"):
		physics_stats.set("max_speed", float(effect["original_speed"]))


func _refresh_status_visual(status_id: String, effect: Dictionary) -> void:
	var target := _get_target()
	if not target is Node2D:
		return

	var line := _visuals.get(status_id, null) as Line2D
	if line == null:
		line = Line2D.new()
		line.name = "%sStatusRing" % status_id.capitalize().replace(" ", "")
		line.z_index = 32
		line.width = 3.0
		line.closed = true
		add_child(line)
		_visuals[status_id] = line

	var radius := float(effect.get("visual_radius", 38.0))
	line.points = _circle_points(radius)
	line.default_color = effect.get("visual_color", Color.WHITE)
	_update_status_visual(status_id, effect)


func _update_status_visual(status_id: String, effect: Dictionary) -> void:
	var line := _visuals.get(status_id, null) as Line2D
	if line == null:
		return

	var duration := maxf(0.05, float(effect.get("duration", 1.0)))
	var remaining := clampf(float(effect.get("remaining", 0.0)) / duration, 0.0, 1.0)
	line.modulate = Color(1.0, 1.0, 1.0, 0.35 + remaining * 0.65)


func _get_target() -> Node:
	if _target != null and is_instance_valid(_target):
		return _target
	_target = get_parent()
	return _target


func _circle_points(radius: float, segments := 48) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
