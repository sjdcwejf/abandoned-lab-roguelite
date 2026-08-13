class_name Chapter5PixelTelegraph
extends Node2D


static func spawn_line(parent: Node2D, origin: Vector2, direction: Vector2, length: float, duration: float, width := 3.0, color := Color(0.46, 0.27, 0.12, 0.9)) -> Line2D:
	var final_direction := direction.normalized()
	if final_direction.length() < 0.01:
		final_direction = Vector2.RIGHT
	var line := Line2D.new()
	line.name = "Chapter5Telegraph"
	line.z_index = -1
	line.width = width
	line.default_color = color
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.points = PackedVector2Array([origin, origin + final_direction * length])
	parent.add_child(line)
	var tween := line.create_tween()
	tween.set_loops()
	tween.tween_property(line, "modulate:a", 0.26, 0.18)
	tween.tween_property(line, "modulate:a", 1.0, 0.18)
	var cleanup := line.create_tween()
	cleanup.tween_interval(maxf(0.05, duration))
	cleanup.tween_callback(line.queue_free)
	return line


static func spawn_parallel(parent: Node2D, origin: Vector2, direction: Vector2, length: float, spacing: float, count: int, duration: float) -> Array[Line2D]:
	var lines: Array[Line2D] = []
	var final_direction := direction.normalized()
	if final_direction.length() < 0.01:
		final_direction = Vector2.RIGHT
	var perpendicular := Vector2(-final_direction.y, final_direction.x)
	var middle := (float(count) - 1.0) * 0.5
	for index in range(count):
		var offset := perpendicular * (float(index) - middle) * spacing
		lines.append(spawn_line(parent, origin + offset, final_direction, length, duration, 2.0))
	return lines
