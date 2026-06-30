extends "res://tiny_wizard/enemies/fusion_boss/fusion_boss.gd"


const CRYO_PROJECTILE_SCENE := preload("res://tiny_wizard/enemies/cryo_spitter/cryo_projectile.tscn")
const CRYO_ZONE_SCENE := preload("res://tiny_wizard/interactable_objects/cryo_zone/cryo_zone.tscn")

@export var cryo_zone_cooldown := 5.5
@export var cryo_zone_radius := 132.0
@export var cryo_zone_duration := 4.5

var _cryo_zone_cooldown_remaining := 2.0


func _ready() -> void:
	super._ready()
	set_meta("cryo_enemy", true)


func _process(delta: float) -> void:
	if _defeated:
		return
	_cryo_zone_cooldown_remaining = maxf(0.0, _cryo_zone_cooldown_remaining - delta)
	if _cryo_zone_cooldown_remaining <= 0.0:
		_cryo_zone_cooldown_remaining = cryo_zone_cooldown
		_spawn_cryo_zone_near_target()


func play_spit_windup(duration: float) -> void:
	_tween_visual(Color(0.52, 0.9, 1.0, 1.0), Vector2(1.12, 1.12), duration)
	_spawn_attack_pulse(Color(0.42, 0.86, 1.0, 0.84), 38.0, duration)


func play_summon_windup(duration: float) -> void:
	_tween_visual(Color(0.58, 0.94, 1.0, 1.0), Vector2(1.16, 1.08), duration)
	_spawn_attack_pulse(Color(0.48, 0.86, 1.0, 0.88), 64.0, duration)


func play_phase_transition(duration: float) -> void:
	_tween_visual(Color(0.6, 0.95, 1.0, 1.0), Vector2(1.24, 1.2), duration * 0.55)
	_spawn_attack_pulse(Color(0.45, 0.86, 1.0, 0.95), 92.0, duration)
	_spawn_cryo_zone_near_target()


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
		var projectile := CRYO_PROJECTILE_SCENE.instantiate() as Node2D
		if projectile == null:
			continue
		if effect_parent is Node2D:
			projectile.position = (effect_parent as Node2D).to_local(origin)
		else:
			projectile.global_position = origin
		projectile.call("setup", base_direction.rotated(angle_offset))
		effect_parent.call_deferred("add_child", projectile)


func _spawn_cryo_zone_near_target() -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return

	var target_position := global_position
	var detector := get_node_or_null("Behavior/PlayerDetector")
	if detector != null and detector.has_method("player_is_in_range") and bool(detector.call("player_is_in_range")):
		target_position = detector.call("get_player_position")
	else:
		target_position += Vector2.from_angle(randf() * TAU) * randf_range(80.0, 140.0)

	var zone := CRYO_ZONE_SCENE.instantiate() as Node2D
	if zone == null:
		return
	zone.set("radius", cryo_zone_radius)
	zone.set("duration", cryo_zone_duration)
	zone.set("show_player_feedback", true)
	if effect_parent is Node2D:
		zone.position = (effect_parent as Node2D).to_local(target_position)
	else:
		zone.global_position = target_position
	effect_parent.call_deferred("add_child", zone)

