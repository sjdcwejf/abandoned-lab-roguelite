extends ProtomatterDropEnemy


@export var spray_damage := 1
@export var spray_length := 118.0
@export var spray_half_width := 43.0
@export var spray_slow_duration := 0.7
@export_range(0.2, 1.0, 0.01) var spray_slow_multiplier := 0.72

@onready var body_sprite := $Visual/BodySprite as AnimatedSprite2D
@onready var spray_sprite := $Visual/SpraySprite as AnimatedSprite2D


func _ready() -> void:
	super._ready()
	set_meta("cryo_enemy", true)
	if spray_sprite != null:
		spray_sprite.animation_finished.connect(_on_spray_animation_finished)


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 68.0 * multiplier


func play_idle() -> void:
	if body_sprite != null and body_sprite.animation != &"idle":
		body_sprite.play(&"idle")


func play_windup(direction: Vector2, duration: float) -> void:
	_face_direction(direction)
	if body_sprite != null:
		body_sprite.play(&"windup")
	_spawn_cone_warning(direction, duration)


func execute_spray(direction: Vector2) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction.length() < 0.01:
		normalized_direction = Vector2.RIGHT
	_face_direction(normalized_direction)
	if body_sprite != null:
		body_sprite.play(&"attack")
	if spray_sprite != null:
		spray_sprite.visible = true
		spray_sprite.rotation = normalized_direction.angle()
		spray_sprite.flip_v = normalized_direction.x < 0.0
		spray_sprite.play(&"spray")

	var shape := ConvexPolygonShape2D.new()
	shape.points = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(spray_length, -spray_half_width),
		Vector2(spray_length, spray_half_width),
		Vector2(0.0, 12.0),
	])
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(normalized_direction.angle(), global_position + Vector2(0.0, -22.0))
	query.collision_mask = 2
	query.exclude = [get_rid()]

	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		target.call("hit", spray_damage, normalized_direction)
		LabStatusEffectController.apply_slow(target, spray_slow_duration, spray_slow_multiplier)


func finish_attack() -> void:
	if body_sprite != null:
		body_sprite.play(&"idle")


func _face_direction(direction: Vector2) -> void:
	if body_sprite != null and absf(direction.x) > 0.05:
		body_sprite.flip_h = direction.x < 0.0


func _spawn_cone_warning(direction: Vector2, duration: float) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction.length() < 0.01:
		normalized_direction = Vector2.RIGHT
	var warning := Line2D.new()
	warning.name = "SealantSprayWarning"
	warning.z_index = -1
	warning.width = 3.0
	warning.default_color = Color(0.56, 0.9, 1.0, 0.66)
	var origin := Vector2(0.0, -22.0)
	warning.points = PackedVector2Array([
		origin + normalized_direction.rotated(-0.36) * spray_length,
		origin,
		origin + normalized_direction.rotated(0.36) * spray_length,
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(0.8, 0.98, 1.0, 0.08), duration)
	tween.tween_callback(warning.queue_free)


func _on_spray_animation_finished() -> void:
	if spray_sprite != null:
		spray_sprite.visible = false

