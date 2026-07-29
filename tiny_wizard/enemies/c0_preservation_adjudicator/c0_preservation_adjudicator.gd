extends "res://tiny_wizard/enemies/fusion_boss/fusion_boss.gd"


const C0_POD_PROJECTILE_SCENE := preload(
	"res://tiny_wizard/enemies/c0_preservation_adjudicator/c0_pod_projectile.tscn"
)
const IDLE_TEXTURE := preload(
	"res://tiny_wizard/assets/art/enemies/chapter3/c0_preservation_adjudicator_cold_revision.png"
)
const TRANSFER_TEXTURE := preload(
	"res://tiny_wizard/assets/art/enemies/chapter3/01_forced_transfer_sheet.png"
)
const VENT_TEXTURE := preload(
	"res://tiny_wizard/assets/art/enemies/chapter3/02_triple_pressure_vent_sheet.png"
)
const POD_TEXTURE := preload(
	"res://tiny_wizard/assets/art/enemies/chapter3/03_preservation_pod_ejection_sheet.png"
)
const TERMINAL_TEXTURE := preload(
	"res://tiny_wizard/assets/art/enemies/chapter3/04_terminate_preservation_sheet.png"
)

const ATTACK_DURATION := 1.5
const ATTACK_TEXTURES := {
	&"transfer": TRANSFER_TEXTURE,
	&"vent": VENT_TEXTURE,
	&"pod": POD_TEXTURE,
	&"terminal": TERMINAL_TEXTURE,
}
const ATTACK_TRIGGER_TIMES := {
	&"transfer": 0.72,
	&"vent": 0.68,
	&"pod": 0.76,
	&"terminal": 0.82,
}

@export var transfer_range := 190.0
@export var transfer_width := 54.0
@export var vent_range := 250.0
@export var vent_width := 44.0
@export var terminal_range := 520.0
@export var terminal_width := 76.0
@export var terminal_visual_width := 94.0
@export var attack_interval := 0.62

var _attack_elapsed := 0.0
var _attack_cooldown := 1.0
var _terminal_cooldown := 2.5
var _attack_active := false
var _attack_executed := false
var _current_attack: StringName = &""
var _locked_direction := Vector2.RIGHT
var _locked_target := Vector2.ZERO
var _attack_index := 0

@onready var body_sprite := $Visual/BodySprite as Sprite2D
@onready var shadow_sprite := $Visual/Shadow as Sprite2D
@onready var player_detector := $Behavior/PlayerDetector


func _ready() -> void:
	super._ready()
	set_meta("cryo_enemy", true)
	boss_display_name = "零号封存裁定机 C-0"
	if body_sprite != null:
		body_sprite.texture = IDLE_TEXTURE
		body_sprite.hframes = 1
		body_sprite.frame = 0


func _process(delta: float) -> void:
	if _defeated:
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_terminal_cooldown = maxf(0.0, _terminal_cooldown - delta)
	if _attack_active:
		_tick_attack(delta)
		return
	if player_detector == null or not player_detector.player_is_in_range():
		return
	if _attack_cooldown > 0.0:
		return

	_locked_target = player_detector.get_player_position()
	_locked_direction = (global_position + Vector2(0.0, -58.0)).direction_to(_locked_target)
	if _locked_direction.length() < 0.01:
		_locked_direction = Vector2.RIGHT
	_start_attack(_choose_attack())


func _choose_attack() -> StringName:
	if is_low_health() and _terminal_cooldown <= 0.0:
		_terminal_cooldown = 5.2
		return &"terminal"
	var attacks: Array[StringName] = [&"transfer", &"vent", &"pod"]
	var selected := attacks[_attack_index % attacks.size()]
	_attack_index += 1
	return selected


func _start_attack(attack_name: StringName) -> void:
	_current_attack = attack_name
	_attack_active = true
	_attack_executed = false
	_attack_elapsed = 0.0
	if body_sprite != null:
		body_sprite.texture = ATTACK_TEXTURES.get(attack_name, TRANSFER_TEXTURE)
		body_sprite.hframes = 12
		body_sprite.frame = 0
		body_sprite.position = Vector2(0.0, -60.0)
		body_sprite.flip_h = _locked_direction.x < 0.0
	if shadow_sprite != null:
		shadow_sprite.visible = false
	_spawn_attack_warning(attack_name)


func _tick_attack(delta: float) -> void:
	_attack_elapsed += delta
	if body_sprite != null:
		body_sprite.frame = mini(11, int(floor(_attack_elapsed / ATTACK_DURATION * 12.0)))
	var trigger_time := float(ATTACK_TRIGGER_TIMES.get(_current_attack, 0.75))
	if not _attack_executed and _attack_elapsed >= trigger_time:
		_attack_executed = true
		_execute_attack(_current_attack)
	if _attack_elapsed >= ATTACK_DURATION:
		_finish_attack()


func _execute_attack(attack_name: StringName) -> void:
	match attack_name:
		&"transfer":
			_execute_transfer()
		&"vent":
			_execute_vent()
		&"pod":
			_execute_pod()
		&"terminal":
			_execute_terminal()


func _execute_transfer() -> void:
	var origin := global_position + Vector2(0.0, -58.0)
	var endpoint := _ray_endpoint(origin, _locked_direction, transfer_range)
	var hit_ids := {}
	_damage_lane(origin, endpoint, transfer_width, 2, _locked_direction, hit_ids, 0.55, 0.76)
	_spawn_active_lane(origin, endpoint, transfer_width + 12.0, Color(0.7, 0.98, 1.0, 0.92), 0.24)


func _execute_vent() -> void:
	var origin := global_position + Vector2(0.0, -58.0)
	var hit_ids := {}
	for angle_degrees in [-22.0, 0.0, 22.0]:
		var direction := _locked_direction.rotated(deg_to_rad(angle_degrees))
		var endpoint := _ray_endpoint(origin, direction, vent_range)
		_damage_lane(origin, endpoint, vent_width, 1, direction, hit_ids, 0.8, 0.7)
		_spawn_active_lane(origin, endpoint, vent_width + 8.0, Color(0.52, 0.9, 1.0, 0.76), 0.34)


func _execute_pod() -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return
	var origin := global_position + Vector2(0.0, -50.0) + _locked_direction * 48.0
	var projectile := C0_POD_PROJECTILE_SCENE.instantiate() as Node2D
	if projectile == null:
		return
	if effect_parent is Node2D:
		projectile.position = (effect_parent as Node2D).to_local(origin)
	else:
		projectile.global_position = origin
	projectile.call("setup", _locked_direction)
	effect_parent.add_child(projectile)


func _execute_terminal() -> void:
	var origin := global_position + Vector2(0.0, -58.0)
	var endpoint := _ray_endpoint(origin, _locked_direction, terminal_range)
	var hit_ids := {}
	_damage_lane(origin, endpoint, terminal_width, 2, _locked_direction, hit_ids, 0.95, 0.58)
	_spawn_active_lane(
		origin,
		endpoint,
		terminal_visual_width,
		Color(0.7, 0.98, 1.0, 0.96),
		0.7
	)


func _damage_lane(
	origin: Vector2,
	endpoint: Vector2,
	width: float,
	damage: int,
	impulse: Vector2,
	hit_ids: Dictionary,
	slow_duration: float,
	slow_multiplier: float
) -> void:
	var length := origin.distance_to(endpoint)
	if length <= 1.0:
		return
	var direction := origin.direction_to(endpoint)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(length, width)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(direction.angle(), origin + direction * length * 0.5)
	query.collision_mask = 2
	query.exclude = [get_rid()]
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 12):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		var target_id := target.get_instance_id()
		if hit_ids.has(target_id):
			continue
		hit_ids[target_id] = true
		target.call("hit", damage, impulse)
		LabStatusEffectController.apply_slow(target, slow_duration, slow_multiplier)


func _ray_endpoint(origin: Vector2, direction: Vector2, max_distance: float) -> Vector2:
	var normalized_direction := direction.normalized()
	if normalized_direction.length() < 0.01:
		normalized_direction = Vector2.RIGHT
	var requested_end := origin + normalized_direction * max_distance
	var query := PhysicsRayQueryParameters2D.create(origin, requested_end, 1)
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return requested_end
	return result.get("position", requested_end) as Vector2


func _spawn_attack_warning(attack_name: StringName) -> void:
	var origin := global_position + Vector2(0.0, -58.0)
	match attack_name:
		&"transfer":
			var endpoint := _ray_endpoint(origin, _locked_direction, transfer_range)
			_spawn_warning_lane(origin, endpoint, 5.0, 0.72)
		&"vent":
			for angle_degrees in [-22.0, 0.0, 22.0]:
				var direction := _locked_direction.rotated(deg_to_rad(angle_degrees))
				var endpoint := _ray_endpoint(origin, direction, vent_range)
				_spawn_warning_lane(origin, endpoint, 4.0, 0.68)
		&"pod":
			var endpoint := _ray_endpoint(origin, _locked_direction, 310.0)
			_spawn_warning_lane(origin, endpoint, 3.0, 0.76)
		&"terminal":
			var endpoint := _ray_endpoint(origin, _locked_direction, terminal_range)
			_spawn_warning_lane(origin, endpoint, 10.0, 0.82)


func _spawn_warning_lane(origin: Vector2, endpoint: Vector2, width: float, duration: float) -> void:
	var warning := Line2D.new()
	warning.name = "C0AttackWarning"
	warning.z_index = -1
	warning.width = width
	warning.default_color = Color(0.54, 0.9, 1.0, 0.72)
	warning.points = PackedVector2Array([
		to_local(origin),
		to_local(endpoint),
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(0.78, 0.98, 1.0, 0.08), duration)
	tween.tween_callback(warning.queue_free)


func _spawn_active_lane(
	origin: Vector2,
	endpoint: Vector2,
	width: float,
	color: Color,
	duration: float
) -> void:
	var lane := Line2D.new()
	lane.name = "C0ActiveAttack"
	lane.z_index = 4
	lane.width = width
	lane.default_color = color
	lane.points = PackedVector2Array([
		to_local(origin),
		to_local(endpoint),
	])
	add_child(lane)
	var tween := lane.create_tween()
	tween.tween_property(lane, "modulate", Color(color.r, color.g, color.b, 0.0), duration)
	tween.tween_callback(lane.queue_free)


func _finish_attack() -> void:
	_attack_active = false
	_attack_executed = false
	_current_attack = &""
	_attack_cooldown = attack_interval
	if body_sprite != null:
		body_sprite.texture = IDLE_TEXTURE
		body_sprite.hframes = 1
		body_sprite.frame = 0
		body_sprite.position = Vector2(0.0, -58.0)
		body_sprite.flip_h = false
	if shadow_sprite != null:
		shadow_sprite.visible = true

