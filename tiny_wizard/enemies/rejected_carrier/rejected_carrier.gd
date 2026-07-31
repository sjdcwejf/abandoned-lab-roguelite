extends ProtomatterDropEnemy


@export var charge_damage := 1
@export var charge_hit_radius := 21.0
@export var charge_hit_offset := 28.0
@export var charge_warning_length := 235.0

var _charge_direction := Vector2.RIGHT
var _charge_hit_ids := {}

@onready var body_sprite := $Visual/BodySprite as AnimatedSprite2D


func _ready() -> void:
	super._ready()
	set_meta("exosuit_enemy", true)


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 74.0 * multiplier


func play_idle() -> void:
	if body_sprite != null and body_sprite.animation != &"idle":
		body_sprite.play(&"idle")


func play_windup(direction: Vector2, duration: float) -> void:
	_charge_direction = _normalized_direction(direction)
	_spawn_line_warning(_charge_direction, charge_warning_length, 7.0, Color(1.0, 0.56, 0.22, 0.72), duration)
	if body_sprite != null:
		body_sprite.play(&"charge_left" if _charge_direction.x < 0.0 else &"charge_right")
		body_sprite.frame = 0
		body_sprite.pause()


func begin_charge(direction: Vector2) -> void:
	_charge_hit_ids.clear()
	_charge_direction = _normalized_direction(direction)
	if body_sprite != null:
		body_sprite.play(&"charge_left" if _charge_direction.x < 0.0 else &"charge_right")


func tick_charge_attack(direction: Vector2) -> bool:
	var normalized := _normalized_direction(direction)
	var shape := CircleShape2D.new()
	shape.radius = charge_hit_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + normalized * charge_hit_offset + Vector2(0.0, -24.0))
	query.collision_mask = 2
	query.exclude = [get_rid()]

	var hit_player := false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		var target_id := target.get_instance_id()
		if _charge_hit_ids.has(target_id):
			continue
		_charge_hit_ids[target_id] = true
		target.call("hit", charge_damage, normalized)
		hit_player = true
	return hit_player


func play_impact(direction: Vector2) -> void:
	_charge_direction = _normalized_direction(direction)
	if body_sprite != null:
		body_sprite.play(&"charge_left" if _charge_direction.x < 0.0 else &"charge_right")
		body_sprite.frame = max(body_sprite.sprite_frames.get_frame_count(body_sprite.animation) - 1, 0)
		body_sprite.pause()


func finish_attack() -> void:
	play_idle()


func _normalized_direction(direction: Vector2) -> Vector2:
	var normalized := direction.normalized()
	if normalized.length() < 0.01:
		normalized = Vector2.RIGHT
	return normalized


func _spawn_line_warning(direction: Vector2, length: float, width: float, color: Color, duration: float) -> void:
	var normalized := _normalized_direction(direction)
	var warning := Line2D.new()
	warning.name = "RejectedCarrierChargeWarning"
	warning.z_index = -1
	warning.width = width
	warning.default_color = color
	warning.points = PackedVector2Array([
		Vector2(0.0, -24.0),
		Vector2(0.0, -24.0) + normalized * length,
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(color.r, color.g, color.b, 0.08), duration)
	tween.tween_callback(warning.queue_free)
