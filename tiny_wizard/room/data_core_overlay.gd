class_name DataCoreOverlay
extends Node2D


@export var variant := "server"


func _ready() -> void:
	z_index = -2
	_build_floor()
	_build_grid()
	_build_data_lines()
	_build_equipment()
	_build_alert_marks()


func _build_floor() -> void:
	var floor := Polygon2D.new()
	floor.name = "DataCoreFloorTint"
	floor.color = Color(0.045, 0.052, 0.068, 0.62)
	floor.polygon = PackedVector2Array([
		Vector2(72, 92),
		Vector2(952, 92),
		Vector2(952, 508),
		Vector2(72, 508),
	])
	add_child(floor)


func _build_grid() -> void:
	for x in range(128, 912, 64):
		_add_line(Vector2(x, 104), Vector2(x, 496), Color(0.18, 0.36, 0.45, 0.24), 1.0)
	for y in range(128, 488, 64):
		_add_line(Vector2(86, y), Vector2(938, y), Color(0.18, 0.36, 0.45, 0.22), 1.0)


func _build_data_lines() -> void:
	for line in _variant_data_lines():
		_add_line(
			line.get("from", Vector2.ZERO),
			line.get("to", Vector2.ZERO),
			line.get("color", Color(0.34, 0.88, 1.0, 0.42)),
			line.get("width", 2.0)
		)


func _build_equipment() -> void:
	for item in _variant_equipment():
		_add_equipment(
			item.get("position", Vector2.ZERO),
			item.get("size", Vector2(90, 52)),
			item.get("kind", "server"),
			item.get("accent", Color(0.34, 0.88, 1.0, 0.85))
		)


func _build_alert_marks() -> void:
	var marks := _variant_alert_marks()
	for mark in marks:
		_add_warning_strip(mark.get("position", Vector2.ZERO), mark.get("size", Vector2(160, 20)), bool(mark.get("vertical", false)))


func _variant_data_lines() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"from": Vector2(256, 302), "to": Vector2(768, 302), "color": Color(0.28, 0.88, 1.0, 0.32), "width": 3.0},
			]
		"comm":
			return [
				{"from": Vector2(250, 222), "to": Vector2(774, 222), "color": Color(0.42, 0.95, 1.0, 0.48), "width": 4.0},
				{"from": Vector2(250, 382), "to": Vector2(774, 382), "color": Color(0.42, 0.95, 1.0, 0.32), "width": 3.0},
			]
		"satellite":
			return [
				{"from": Vector2(512, 150), "to": Vector2(512, 450), "color": Color(0.95, 0.2, 0.16, 0.38), "width": 4.0},
				{"from": Vector2(300, 300), "to": Vector2(724, 300), "color": Color(0.95, 0.2, 0.16, 0.26), "width": 3.0},
			]
		"archive":
			return [
				{"from": Vector2(226, 196), "to": Vector2(798, 196), "color": Color(0.52, 0.92, 1.0, 0.44), "width": 3.0},
				{"from": Vector2(226, 404), "to": Vector2(798, 404), "color": Color(0.52, 0.92, 1.0, 0.32), "width": 3.0},
			]
		"merchant":
			return [
				{"from": Vector2(346, 300), "to": Vector2(678, 300), "color": Color(0.38, 0.94, 1.0, 0.48), "width": 4.0},
			]
		"boss":
			return [
				{"from": Vector2(230, 300), "to": Vector2(794, 300), "color": Color(1.0, 0.2, 0.12, 0.44), "width": 4.0},
				{"from": Vector2(512, 158), "to": Vector2(512, 442), "color": Color(1.0, 0.2, 0.12, 0.3), "width": 3.0},
			]
	return [
		{"from": Vector2(238, 300), "to": Vector2(786, 300), "color": Color(0.34, 0.88, 1.0, 0.32), "width": 3.0},
	]


func _variant_equipment() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(190, 296), "size": Vector2(98, 240), "kind": "server", "accent": Color(0.32, 0.82, 0.95, 0.9)},
				{"position": Vector2(834, 296), "size": Vector2(98, 240), "kind": "server", "accent": Color(0.32, 0.82, 0.95, 0.9)},
				{"position": Vector2(512, 126), "size": Vector2(280, 46), "kind": "gate", "accent": Color(0.95, 0.48, 0.14, 0.8)},
			]
		"comm":
			return [
				{"position": Vector2(252, 222), "size": Vector2(112, 110), "kind": "relay", "accent": Color(0.32, 0.94, 1.0, 0.85)},
				{"position": Vector2(772, 382), "size": Vector2(112, 110), "kind": "relay", "accent": Color(0.32, 0.94, 1.0, 0.85)},
				{"position": Vector2(512, 126), "size": Vector2(340, 42), "kind": "antenna", "accent": Color(0.9, 0.52, 0.18, 0.8)},
			]
		"satellite":
			return [
				{"position": Vector2(214, 212), "size": Vector2(120, 84), "kind": "server", "accent": Color(0.95, 0.22, 0.18, 0.8)},
				{"position": Vector2(810, 388), "size": Vector2(120, 84), "kind": "server", "accent": Color(0.95, 0.22, 0.18, 0.8)},
				{"position": Vector2(512, 300), "size": Vector2(150, 150), "kind": "dish", "accent": Color(0.95, 0.22, 0.18, 0.82)},
			]
		"archive":
			return [
				{"position": Vector2(208, 302), "size": Vector2(110, 270), "kind": "server", "accent": Color(0.42, 0.92, 1.0, 0.82)},
				{"position": Vector2(816, 302), "size": Vector2(110, 270), "kind": "server", "accent": Color(0.42, 0.92, 1.0, 0.82)},
				{"position": Vector2(512, 302), "size": Vector2(220, 120), "kind": "blackbox", "accent": Color(0.92, 0.7, 0.24, 0.9)},
			]
		"merchant":
			return [
				{"position": Vector2(512, 224), "size": Vector2(330, 72), "kind": "terminal", "accent": Color(0.38, 0.94, 1.0, 0.86)},
				{"position": Vector2(210, 386), "size": Vector2(118, 150), "kind": "server", "accent": Color(0.32, 0.82, 0.95, 0.72)},
				{"position": Vector2(814, 386), "size": Vector2(118, 150), "kind": "server", "accent": Color(0.32, 0.82, 0.95, 0.72)},
			]
		"boss":
			return [
				{"position": Vector2(512, 146), "size": Vector2(420, 70), "kind": "gate", "accent": Color(1.0, 0.22, 0.12, 0.86)},
				{"position": Vector2(512, 300), "size": Vector2(220, 170), "kind": "core", "accent": Color(1.0, 0.22, 0.12, 0.9)},
				{"position": Vector2(188, 302), "size": Vector2(100, 270), "kind": "server", "accent": Color(0.78, 0.12, 0.16, 0.75)},
				{"position": Vector2(836, 302), "size": Vector2(100, 270), "kind": "server", "accent": Color(0.78, 0.12, 0.16, 0.75)},
			]
	return [
		{"position": Vector2(188, 306), "size": Vector2(100, 240), "kind": "server", "accent": Color(0.34, 0.88, 1.0, 0.85)},
		{"position": Vector2(836, 306), "size": Vector2(100, 240), "kind": "server", "accent": Color(0.34, 0.88, 1.0, 0.85)},
	]


func _variant_alert_marks() -> Array[Dictionary]:
	match variant:
		"satellite":
			return [{"position": Vector2(512, 150), "size": Vector2(260, 20)}, {"position": Vector2(512, 450), "size": Vector2(260, 20)}]
		"boss":
			return [{"position": Vector2(512, 170), "size": Vector2(420, 22)}, {"position": Vector2(512, 430), "size": Vector2(420, 22)}]
	return [{"position": Vector2(512, 454), "size": Vector2(280, 18)}]


func _add_equipment(center: Vector2, size: Vector2, kind: String, accent: Color) -> void:
	var half := size * 0.5
	var body := Polygon2D.new()
	body.name = "DataCoreEquipment"
	body.color = Color(0.035, 0.048, 0.058, 0.9)
	if kind in ["core", "blackbox"]:
		body.color = Color(0.018, 0.022, 0.03, 0.94)
	body.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(body)

	_add_line(center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), accent, 2.0)
	_add_line(center + Vector2(half.x, -half.y), center + Vector2(half.x, half.y), accent, 2.0)
	_add_line(center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y), accent, 2.0)
	_add_line(center + Vector2(-half.x, half.y), center + Vector2(-half.x, -half.y), accent, 2.0)

	if kind in ["server", "relay"]:
		for line_index in range(4):
			var y := center.y - half.y * 0.62 + line_index * half.y * 0.4
			_add_line(Vector2(center.x - half.x * 0.58, y), Vector2(center.x + half.x * 0.58, y), Color(0.7, 0.92, 1.0, 0.25), 2.0)
	if kind in ["core", "dish", "blackbox", "terminal"]:
		_add_line(center + Vector2(-half.x * 0.55, 0), center + Vector2(half.x * 0.55, 0), accent, 4.0)


func _add_warning_strip(center: Vector2, size: Vector2, vertical := false) -> void:
	var half := size * 0.5
	var body := Polygon2D.new()
	body.name = "DataWarningStrip"
	body.color = Color(0.45, 0.16, 0.09, 0.36)
	if vertical:
		body.polygon = PackedVector2Array([
			center + Vector2(-half.y, -half.x),
			center + Vector2(half.y, -half.x),
			center + Vector2(half.y, half.x),
			center + Vector2(-half.y, half.x),
		])
	else:
		body.polygon = PackedVector2Array([
			center + Vector2(-half.x, -half.y),
			center + Vector2(half.x, -half.y),
			center + Vector2(half.x, half.y),
			center + Vector2(-half.x, half.y),
		])
	add_child(body)


func _add_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.name = "DataLine"
	line.z_index = 1
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	add_child(line)
