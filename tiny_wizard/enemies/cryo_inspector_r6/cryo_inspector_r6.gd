extends ProtomatterDropEnemy


const PRESSURE_ROUND_SCENE := preload("res://tiny_wizard/enemies/cryo_inspector_r6/cryo_pressure_round.tscn")

@export var clamp_damage := 2
@export var vent_damage := 1
@export var vent_radius := 126.0
@export var attack_slow_duration := 0.9
@export_range(0.2, 1.0, 0.01) var attack_slow_multiplier := 0.64

var _pressure_relief_used := false
var _visual_tween: Tween

@onready var body_sprite := $Visual/BodySprite as AnimatedSprite2D


func _ready() -> void:
	super._ready()
	set_meta("cryo_enemy", true)
	set_meta("elite_enemy", true)


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 54.0 * multiplier


func is_pressure_relief_ready() -> bool:
	if _pressure_relief_used or character_stats == null or character_stats.max_life <= 0:
		return false
	return float(character_stats.current_life) / float(character_stats.max_life) <= 0.48


func play_windup(attack_name: StringName, direction: Vector2, duration: float) -> void:
	_face_direction(direction)
	if _visual_tween != null:
		_visual_tween.kill()
	if body_sprite != null:
		_visual_tween = create_tween()
		_visual_tween.tween_property(body_sprite, "scale", Vector2(1.1, 0.94), duration)
		_visual_tween.parallel().tween_property(
			body_sprite,
			"modulate",
			Color(0.72, 0.96, 1.0, 1.0),
			duration
		)

	if attack_name == &"vent":
		_spawn_ring_warning(vent_radius, duration)
	else:
		var length := 92.0 if attack_name == &"clamp" else 390.0
		var width := 38.0 if attack_name == &"clamp" else 4.0
		_spawn_line_warning(direction, length, width, duration)


func fire_pressure_round(target_position: Vector2) -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return
	var origin := global_position + Vector2(0.0, -42.0)
	var direction := origin.direction_to(target_position)
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	var projectile := PRESSURE_ROUND_SCENE.instantiate() as Node2D
	if projectile == null:
		return
	if effect_parent is Node2D:
		projectile.position = (effect_parent as Node2D).to_local(origin)
	else:
		projectile.global_position = origin
	projectile.call("setup", direction)
	effect_parent.add_child(projectile)


func execute_clamp(direction: Vector2) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction.length() < 0.01:
		normalized_direction = Vector2.RIGHT
	var shape := RectangleShape2D.new()
	shape.size = Vector2(82.0, 48.0)
	var center := global_position + Vector2(0.0, -32.0) + normalized_direction * 41.0
	_damage_shape(shape, Transform2D(normalized_direction.angle(), center), clamp_damage, normalized_direction)


func execute_pressure_relief() -> void:
	_pressure_relief_used = true
	var shape := CircleShape2D.new()
	shape.radius = vent_radius
	_damage_shape(shape, Transform2D(0.0, global_position + Vector2(0.0, -28.0)), vent_damage, Vector2.ZERO)
	_spawn_pressure_burst()


func finish_attack() -> void:
	if _visual_tween != null:
		_visual_tween.kill()
	if body_sprite != null:
		_visual_tween = create_tween()
		_visual_tween.tween_property(body_sprite, "scale", Vector2.ONE, 0.18)
		_visual_tween.parallel().tween_property(body_sprite, "modulate", Color.WHITE, 0.18)


func _damage_shape(shape: Shape2D, transform: Transform2D, damage: int, impulse: Vector2) -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = transform
	query.collision_mask = 2
	query.exclude = [get_rid()]
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		target.call("hit", damage, impulse)
		LabStatusEffectController.apply_slow(target, attack_slow_duration, attack_slow_multiplier)


func _face_direction(direction: Vector2) -> void:
	if body_sprite != null and absf(direction.x) > 0.05:
		body_sprite.flip_h = direction.x < 0.0


func _spawn_line_warning(direction: Vector2, length: float, width: float, duration: float) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction.length() < 0.01:
		normalized_direction = Vector2.RIGHT
	var warning := Line2D.new()
	warning.name = "R6AttackWarning"
	warning.z_index = -1
	warning.width = width
	warning.default_color = Color(0.48, 0.9, 1.0, 0.72)
	warning.points = PackedVector2Array([
		Vector2(0.0, -38.0),
		Vector2(0.0, -38.0) + normalized_direction * length,
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(0.72, 0.98, 1.0, 0.08), duration)
	tween.tween_callback(warning.queue_free)


func _spawn_ring_warning(radius: float, duration: float) -> void:
	var ring := Line2D.new()
	ring.name = "R6PressureReliefWarning"
	ring.z_index = -1
	ring.width = 5.0
	ring.default_color = Color(0.44, 0.9, 1.0, 0.76)
	ring.closed = true
	var points := PackedVector2Array()
	for index in range(33):
		points.append(Vector2.from_angle(TAU * float(index) / 32.0) * radius)
	ring.points = points
	ring.position = Vector2(0.0, -28.0)
	ring.scale = Vector2(0.35, 0.35)
	add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE, duration)
	tween.parallel().tween_property(ring, "modulate", Color(0.7, 0.98, 1.0, 0.12), duration)
	tween.tween_callback(ring.queue_free)


func _spawn_pressure_burst() -> void:
	var ring := Line2D.new()
	ring.name = "R6PressureReliefBurst"
	ring.z_index = 3
	ring.width = 12.0
	ring.default_color = Color(0.78, 1.0, 1.0, 0.92)
	ring.closed = true
	var points := PackedVector2Array()
	for index in range(33):
		points.append(Vector2.from_angle(TAU * float(index) / 32.0) * vent_radius)
	ring.points = points
	ring.position = Vector2(0.0, -28.0)
	ring.scale = Vector2(0.35, 0.35)
	add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE, 0.16)
	tween.parallel().tween_property(ring, "modulate", Color(0.78, 1.0, 1.0, 0.0), 0.32)
	tween.tween_callback(ring.queue_free)

