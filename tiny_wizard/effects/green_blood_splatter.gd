class_name LabGreenBloodSplatter
extends Node2D


@export var lifetime := 0.42
@export var gravity := Vector2(0.0, 72.0)

var _age := 0.0
var _droplets: Array[Dictionary] = []
var _streaks: Array[Dictionary] = []


func setup(hit_from := Vector2.ZERO, scale_multiplier := 1.0) -> void:
	var spray_direction := hit_from.normalized()
	if spray_direction == Vector2.ZERO:
		spray_direction = Vector2.RIGHT.rotated(randf() * TAU)

	scale_multiplier = maxf(0.2, scale_multiplier)
	_droplets.clear()
	_streaks.clear()

	var droplet_count := randi_range(7, 11)
	for index in range(droplet_count):
		var spread := randf_range(-0.95, 0.95)
		var direction := spray_direction.rotated(spread).normalized()
		var speed := randf_range(55.0, 150.0) * scale_multiplier
		_droplets.append({
			"velocity": direction * speed,
			"radius": randf_range(1.7, 4.0) * scale_multiplier,
			"color": _random_blood_color(),
			"delay": randf_range(0.0, 0.035),
		})

	var streak_count := randi_range(3, 5)
	for index in range(streak_count):
		var spread := randf_range(-0.55, 0.55)
		var direction := spray_direction.rotated(spread).normalized()
		_streaks.append({
			"velocity": direction * randf_range(95.0, 180.0) * scale_multiplier,
			"length": randf_range(10.0, 22.0) * scale_multiplier,
			"width": randf_range(2.0, 3.8) * scale_multiplier,
			"color": _random_blood_color(),
			"delay": randf_range(0.0, 0.025),
		})


func _ready() -> void:
	z_as_relative = false
	z_index = 35


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade := clampf(1.0 - (_age / lifetime), 0.0, 1.0)
	for streak in _streaks:
		var streak_age := _age - float(streak.get("delay", 0.0))
		if streak_age <= 0.0:
			continue

		var velocity: Vector2 = streak.get("velocity", Vector2.ZERO)
		var position := _position_at_time(velocity, streak_age)
		var direction := velocity.normalized()
		var color: Color = streak.get("color", Color.GREEN)
		color.a *= fade
		draw_line(
			position - direction * float(streak.get("length", 12.0)) * fade,
			position,
			color,
			float(streak.get("width", 2.0)) * fade,
			true
		)

	for droplet in _droplets:
		var droplet_age := _age - float(droplet.get("delay", 0.0))
		if droplet_age <= 0.0:
			continue

		var velocity: Vector2 = droplet.get("velocity", Vector2.ZERO)
		var position := _position_at_time(velocity, droplet_age)
		var color: Color = droplet.get("color", Color.GREEN)
		color.a *= fade
		draw_circle(position, float(droplet.get("radius", 2.0)) * (0.75 + 0.35 * fade), color)


func _position_at_time(velocity: Vector2, time: float) -> Vector2:
	return velocity * time + gravity * time * time * 0.5


func _random_blood_color() -> Color:
	var choices := [
		Color(0.22, 0.95, 0.32, 0.88),
		Color(0.12, 0.76, 0.24, 0.9),
		Color(0.55, 1.0, 0.22, 0.78),
		Color(0.05, 0.55, 0.18, 0.9),
	]
	return choices.pick_random()
