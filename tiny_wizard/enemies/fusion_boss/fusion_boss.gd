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
@export var charge_duration := 0.42
@export var charge_speed_multiplier := 2.55
@export var spit_cooldown := 2.1
@export var spit_range := 360.0
@export_range(1, 9, 1) var spit_projectile_count := 5
@export var spit_spread_degrees := 44.0
@export_range(0.05, 0.9, 0.01) var low_health_threshold := 0.35
@export var low_health_speed_multiplier := 1.35
@export var low_health_summon_cooldown := 8.0
@export_range(0, 6, 1) var low_health_max_summons := 2
@export var summon_scene: PackedScene
@export_range(0, 12, 1) var death_burst_count := 6
@export var death_burst_scale := 2.0

var _base_max_speed := 70.0
var _defeated := false
var _summoned_minions: Array[Node] = []


func _ready() -> void:
	super._ready()
	protomatter_drop_chance = 1.0
	protomatter_min_drop = maxi(protomatter_min_drop, 5)
	protomatter_max_drop = maxi(protomatter_max_drop, 8)
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
