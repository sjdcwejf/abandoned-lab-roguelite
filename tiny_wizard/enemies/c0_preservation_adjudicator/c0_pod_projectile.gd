extends Area2D


@export var speed := 310.0
@export var damage := 1
@export var lifetime := 1.45
@export var explosion_radius := 58.0
@export var slow_duration := 0.8
@export_range(0.2, 1.0, 0.01) var slow_multiplier := 0.68

var _direction := Vector2.RIGHT
var _finished := false


func setup(direction: Vector2) -> void:
	if direction.length() > 0.01:
		_direction = direction.normalized()
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _finished:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()
		return
	global_position += _direction * speed * delta


func _on_body_entered(_body: Node) -> void:
	_explode()


func _explode() -> void:
	if _finished:
		return
	_finished = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 2
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		target.call("hit", damage, _direction)
		LabStatusEffectController.apply_slow(target, slow_duration, slow_multiplier)
	_spawn_burst()


func _spawn_burst() -> void:
	var ring := Line2D.new()
	ring.name = "PreservationPodBurst"
	ring.width = 8.0
	ring.default_color = Color(0.7, 0.98, 1.0, 0.94)
	ring.closed = true
	var points := PackedVector2Array()
	for index in range(25):
		points.append(Vector2.from_angle(TAU * float(index) / 24.0) * explosion_radius)
	ring.points = points
	ring.scale = Vector2(0.25, 0.25)
	add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE, 0.14)
	tween.parallel().tween_property(ring, "modulate", Color(0.7, 0.98, 1.0, 0.0), 0.3)
	tween.tween_callback(queue_free)
