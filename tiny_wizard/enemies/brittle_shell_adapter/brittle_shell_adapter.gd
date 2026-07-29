extends ProtomatterDropEnemy


@export var dash_damage := 1
@export var dash_hit_radius := 19.0
@export var dash_hit_offset := 24.0

var _dash_hit_ids := {}

@onready var body_sprite := $Visual/BodySprite as AnimatedSprite2D
@onready var impact_sprite := $Visual/ImpactSprite as AnimatedSprite2D


func _ready() -> void:
	super._ready()
	set_meta("cryo_enemy", true)
	if impact_sprite != null:
		impact_sprite.animation_finished.connect(_on_impact_animation_finished)


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 78.0 * multiplier


func play_idle() -> void:
	if body_sprite != null and body_sprite.animation != &"idle":
		body_sprite.play(&"idle")


func play_windup(direction: Vector2, duration: float) -> void:
	_face_direction(direction)
	if body_sprite != null:
		body_sprite.play(&"windup")
	_spawn_line_warning(direction, 220.0, 5.0, Color(0.72, 0.92, 1.0, 0.72), duration)


func begin_dash(direction: Vector2) -> void:
	_dash_hit_ids.clear()
	_face_direction(direction)
	if body_sprite != null:
		body_sprite.play(&"attack")


func tick_dash_attack(direction: Vector2) -> bool:
	var normalized_direction := direction.normalized()
	if normalized_direction.length() < 0.01:
		normalized_direction = Vector2.RIGHT

	var shape := CircleShape2D.new()
	shape.radius = dash_hit_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(
		0.0,
		global_position + normalized_direction * dash_hit_offset + Vector2(0.0, -20.0)
	)
	query.collision_mask = 2
	query.exclude = [get_rid()]

	var hit_anything := false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		var target_id := target.get_instance_id()
		if _dash_hit_ids.has(target_id):
			continue
		_dash_hit_ids[target_id] = true
		target.call("hit", dash_damage, normalized_direction)
		hit_anything = true
	return hit_anything


func play_impact(direction: Vector2) -> void:
	_face_direction(direction)
	if impact_sprite != null:
		impact_sprite.visible = true
		impact_sprite.play(&"impact")


func _face_direction(direction: Vector2) -> void:
	if body_sprite != null and absf(direction.x) > 0.05:
		body_sprite.flip_h = direction.x < 0.0
	if impact_sprite != null and absf(direction.x) > 0.05:
		impact_sprite.flip_h = direction.x < 0.0


func _spawn_line_warning(
	direction: Vector2,
	length: float,
	width: float,
	color: Color,
	duration: float
) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction.length() < 0.01:
		normalized_direction = Vector2.RIGHT
	var warning := Line2D.new()
	warning.name = "BrittleShellDashWarning"
	warning.z_index = -1
	warning.width = width
	warning.default_color = color
	warning.points = PackedVector2Array([
		Vector2(0.0, -20.0),
		Vector2(0.0, -20.0) + normalized_direction * length,
	])
	add_child(warning)
	var tween := warning.create_tween()
	tween.tween_property(warning, "modulate", Color(color.r, color.g, color.b, 0.08), duration)
	tween.tween_callback(warning.queue_free)


func _on_impact_animation_finished() -> void:
	if impact_sprite != null:
		impact_sprite.visible = false
