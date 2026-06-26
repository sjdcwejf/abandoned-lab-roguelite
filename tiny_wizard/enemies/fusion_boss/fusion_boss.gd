extends "res://tiny_wizard/enemies/protomatter_drop_enemy.gd"


signal boss_stats_changed(current_life: int, max_life: int)
signal boss_defeated

const DEFAULT_SUMMON_SCENE := preload("res://tiny_wizard/enemies/black_fly/black_fly.tscn")
const POISON_PROJECTILE_SCENE := preload("res://tiny_wizard/enemies/fusion_boss/fusion_poison_projectile.tscn")

@export var boss_display_name := "失格者 A-03：破仓体"
@export var far_distance := 270.0
@export var mid_distance := 120.0
@export var chase_speed_multiplier := 1.0
@export var charge_cooldown := 4.0
@export var charge_windup := 0.72
@export var charge_duration := 0.42
@export var charge_speed_multiplier := 2.55
@export var charge_recovery := 0.85
@export var wall_stun_duration := 1.2
@export var spit_cooldown := 2.1
@export var spit_windup := 0.58
@export var spit_recovery := 0.78
@export var spit_range := 360.0
@export_range(1, 9, 1) var spit_projectile_count := 5
@export var spit_spread_degrees := 44.0
@export_range(0.05, 0.9, 0.01) var low_health_threshold := 0.35
@export var low_health_speed_multiplier := 1.35
@export var low_health_summon_cooldown := 8.0
@export_range(0, 6, 1) var low_health_max_summons := 2
@export var summon_windup := 0.9
@export var summon_recovery := 0.85
@export var phase_transition_duration := 1.05
@export var phase_transition_recovery := 0.55
@export var summon_scene: PackedScene
@export_range(0, 12, 1) var death_burst_count := 6
@export var death_burst_scale := 2.0
@export var relic_drop_enabled := true

var _base_max_speed := 70.0
var _defeated := false
var _summoned_minions: Array[Node] = []
var _visual_node: Node2D
var _visual_base_scale := Vector2.ONE
var _visual_base_modulate := Color.WHITE
var _visual_tween: Tween


func _ready() -> void:
	super._ready()
	_visual_node = get_node_or_null("Visual") as Node2D
	if _visual_node != null:
		_visual_base_scale = _visual_node.scale
		_visual_base_modulate = _visual_node.modulate
	protomatter_drop_chance = 0.0
	relic_drop_chance = 0.0
	if physics_stats != null:
		_base_max_speed = physics_stats.max_speed
	if character_stats != null:
		var stats_changed_callable := Callable(self, "_on_character_stats_changed")
		if not character_stats.stats_changed.is_connected(stats_changed_callable):
			character_stats.stats_changed.connect(stats_changed_callable)
	_emit_boss_stats_changed()


func hit(damage := 1, from := Vector2.ZERO) -> void:
	if _defeated:
		return
	super.hit(damage, from)
	_emit_boss_stats_changed()


func die() -> void:
	if _defeated:
		return

	_defeated = true
	_spawn_death_burst()
	_drop_relic()
	_emit_boss_stats_changed()
	boss_defeated.emit()
	super.die()


func is_low_health() -> bool:
	if character_stats == null or character_stats.max_life <= 0:
		return false
	return float(character_stats.current_life) / float(character_stats.max_life) <= low_health_threshold


func get_base_speed_multiplier() -> float:
	var multiplier := chase_speed_multiplier
	if is_low_health():
		multiplier *= low_health_speed_multiplier
	return multiplier


func set_movement_speed_multiplier(multiplier: float) -> void:
	if physics_stats == null:
		return
	physics_stats.max_speed = _base_max_speed * multiplier


func play_charge_windup(direction: Vector2, duration: float) -> void:
	_tween_visual(Color(1.0, 0.42, 0.25, 1.0), Vector2(0.84, 1.14), duration)
	_spawn_charge_warning(direction, duration)


func play_charge_release(duration: float) -> void:
	_tween_visual(Color(1.0, 0.78, 0.55, 1.0), Vector2(1.17, 0.88), minf(duration, 0.18))


func play_spit_windup(duration: float) -> void:
	_tween_visual(Color(0.42, 1.0, 0.32, 1.0), Vector2(1.12, 1.12), duration)
	_spawn_attack_pulse(Color(0.35, 1.0, 0.28, 0.82), 34.0, duration)


func play_summon_windup(duration: float) -> void:
	_tween_visual(Color(0.55, 1.0, 0.48, 1.0), Vector2(1.16, 1.08), duration)
	_spawn_attack_pulse(Color(0.48, 1.0, 0.38, 0.88), 58.0, duration)


func play_phase_transition(duration: float) -> void:
	_tween_visual(Color(0.35, 1.0, 0.3, 1.0), Vector2(1.24, 1.2), duration * 0.55)
	_spawn_attack_pulse(Color(0.4, 1.0, 0.28, 0.95), 82.0, duration)


func play_recovery(duration: float, wall_stun := false) -> void:
	var color := Color(0.62, 0.68, 0.62, 1.0) if wall_stun else Color(0.84, 0.9, 0.8, 1.0)
	var scale_multiplier := Vector2(1.12, 0.88) if wall_stun else Vector2(0.96, 0.94)
	_tween_visual(color, scale_multiplier, minf(duration, 0.18))


func finish_attack_visual() -> void:
	if _visual_node == null:
		return
	if _visual_tween != null:
		_visual_tween.kill()
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(_visual_node, "scale", _visual_base_scale, 0.14)
	_visual_tween.parallel().tween_property(_visual_node, "modulate", _visual_base_modulate, 0.14)


func _tween_visual(color: Color, scale_multiplier: Vector2, duration: float) -> void:
	if _visual_node == null:
		return
	if _visual_tween != null:
		_visual_tween.kill()
	var target_scale := Vector2(
		_visual_base_scale.x * scale_multiplier.x,
		_visual_base_scale.y * scale_multiplier.y
	)
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(_visual_node, "scale", target_scale, maxf(0.05, duration))
	_visual_tween.parallel().tween_property(_visual_node, "modulate", color, maxf(0.05, duration))


func _spawn_charge_warning(direction: Vector2, duration: float) -> void:
	var final_direction := direction.normalized()
	if final_direction.length() < 0.01:
		final_direction = Vector2.RIGHT
	var warning := Line2D.new()
	warning.name = "冲撞预警"
	warning.z_index = -1
	warning.width = 5.0
	warning.default_color = Color(1.0, 0.22, 0.1, 0.72)
	warning.points = PackedVector2Array([
		Vector2(0.0, -34.0),
		Vector2(0.0, -34.0) + final_direction * 330.0,
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(1.0, 0.7, 0.25, 0.16), maxf(0.05, duration))
	tween.tween_callback(warning.queue_free)


func _spawn_attack_pulse(color: Color, radius: float, duration: float) -> void:
	var pulse := Line2D.new()
	pulse.name = "原质预警环"
	pulse.z_index = -1
	pulse.width = 4.0
	pulse.default_color = color
	pulse.closed = true
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * float(index) / 24.0
		points.append(Vector2.from_angle(angle) * radius)
	pulse.points = points
	pulse.position = Vector2(0.0, -26.0)
	pulse.scale = Vector2(0.45, 0.45)
	add_child(pulse)
	var tween := pulse.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "scale", Vector2(1.45, 1.45), maxf(0.08, duration))
	tween.parallel().tween_property(pulse, "modulate", Color(color.r, color.g, color.b, 0.0), maxf(0.08, duration))
	tween.tween_callback(pulse.queue_free)


func _drop_relic() -> void:
	if not relic_drop_enabled or _relic_dropped:
		return
	_relic_dropped = true

	var drop_parent := _get_drop_parent()
	if drop_parent == null:
		return

	var relic_controller := _find_active_relic_controller()
	if relic_controller == null:
		return

	var drop_position := _get_safe_drop_position(drop_parent, global_position + Vector2(44.0, -10.0))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var dropped := RelicDropService.try_drop_relic_from_pool(drop_parent, relic_controller, drop_position, &"", rng)
	if not dropped:
		print("Boss relic reward skipped: no legal relic candidate.")


func request_poison_spit(target_position: Vector2) -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return

	var origin := global_position + Vector2(0.0, -22.0)
	var base_direction := origin.direction_to(target_position)
	if base_direction.length() < 0.01:
		base_direction = Vector2.RIGHT

	var projectile_count := maxi(1, spit_projectile_count)
	var spread_radians := deg_to_rad(spit_spread_degrees)
	for index in range(projectile_count):
		var ratio := 0.5
		if projectile_count > 1:
			ratio = float(index) / float(projectile_count - 1)
		var angle_offset := lerpf(-spread_radians * 0.5, spread_radians * 0.5, ratio)
		var projectile := POISON_PROJECTILE_SCENE.instantiate() as Node2D
		if projectile == null:
			continue

		if effect_parent is Node2D:
			projectile.position = (effect_parent as Node2D).to_local(origin)
		else:
			projectile.global_position = origin
		projectile.call("setup", base_direction.rotated(angle_offset))
		effect_parent.call_deferred("add_child", projectile)


func request_low_health_summon() -> bool:
	if low_health_max_summons <= 0:
		return false

	_prune_summoned_minions()
	if _summoned_minions.size() >= low_health_max_summons:
		return false

	var enemies_parent := get_parent()
	if enemies_parent == null:
		return false

	var scene_to_spawn := summon_scene
	if scene_to_spawn == null:
		scene_to_spawn = DEFAULT_SUMMON_SCENE

	var minion := scene_to_spawn.instantiate() as Node2D
	if minion == null:
		return false

	var angle := randf() * TAU
	var spawn_position := global_position + Vector2.from_angle(angle) * randf_range(70.0, 105.0)
	if enemies_parent is Node2D:
		minion.position = (enemies_parent as Node2D).to_local(spawn_position)
	else:
		minion.global_position = spawn_position
	minion.process_mode = Node.PROCESS_MODE_INHERIT
	_summoned_minions.append(minion)
	enemies_parent.call_deferred("add_child", minion)
	return true


func _on_character_stats_changed() -> void:
	_emit_boss_stats_changed()


func _emit_boss_stats_changed() -> void:
	if character_stats == null:
		return
	boss_stats_changed.emit(character_stats.current_life, character_stats.max_life)


func _spawn_death_burst() -> void:
	if death_burst_count <= 0:
		return

	var original_scale := green_blood_splatter_scale
	green_blood_splatter_scale = death_burst_scale
	for index in range(death_burst_count):
		var direction := Vector2.RIGHT.rotated(randf() * TAU)
		_spawn_green_blood_splatter(direction)
	green_blood_splatter_scale = original_scale


func _prune_summoned_minions() -> void:
	for index in range(_summoned_minions.size() - 1, -1, -1):
		var minion := _summoned_minions[index]
		if minion == null or not is_instance_valid(minion) or minion.is_queued_for_deletion():
			_summoned_minions.remove_at(index)
