class_name ExosuitFactoryOverlay
extends Node2D


@export var variant := "combat"


func _ready() -> void:
	z_index = -2
	_build_floor_tint()
	_build_tile_grid()
	_build_warning_tracks()
	_build_energy_lines()
	_build_factory_equipment()


func _build_floor_tint() -> void:
	var floor := Polygon2D.new()
	floor.name = "FactoryFloorTint"
	floor.color = Color(0.075, 0.078, 0.085, 0.58)
	floor.polygon = PackedVector2Array([
		Vector2(72, 92),
		Vector2(952, 92),
		Vector2(952, 508),
		Vector2(72, 508),
	])
	add_child(floor)


func _build_tile_grid() -> void:
	for x in range(128, 912, 64):
		_add_line(Vector2(x, 104), Vector2(x, 496), Color(0.28, 0.31, 0.33, 0.26), 1.0)
	for y in range(128, 488, 64):
		_add_line(Vector2(86, y), Vector2(938, y), Color(0.28, 0.31, 0.33, 0.26), 1.0)


func _build_warning_tracks() -> void:
	var strips := _variant_warning_strips()
	for strip in strips:
		_add_warning_strip(strip.get("position", Vector2.ZERO), strip.get("size", Vector2(150, 22)), bool(strip.get("vertical", false)))


func _build_energy_lines() -> void:
	var lines := _variant_energy_lines()
	for line in lines:
		_add_line(
			line.get("from", Vector2.ZERO),
			line.get("to", Vector2.ZERO),
			line.get("color", Color(0.22, 0.82, 0.96, 0.42)),
			line.get("width", 3.0)
		)


func _build_factory_equipment() -> void:
	for item in _variant_equipment():
		_add_equipment(
			item.get("position", Vector2.ZERO),
			item.get("size", Vector2(90, 44)),
			item.get("kind", "rack"),
			bool(item.get("glow", false))
		)


func _variant_warning_strips() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(512, 176), "size": Vector2(260, 22)},
				{"position": Vector2(512, 424), "size": Vector2(260, 22)},
			]
		"test":
			return [
				{"position": Vector2(512, 160), "size": Vector2(300, 22)},
				{"position": Vector2(512, 440), "size": Vector2(300, 22)},
				{"position": Vector2(222, 300), "size": Vector2(162, 22), "vertical": true},
				{"position": Vector2(802, 300), "size": Vector2(162, 22), "vertical": true},
			]
		"merchant":
			return [
				{"position": Vector2(512, 200), "size": Vector2(340, 22)},
				{"position": Vector2(512, 422), "size": Vector2(300, 22)},
			]
		"boss":
			return [
				{"position": Vector2(512, 154), "size": Vector2(420, 24)},
				{"position": Vector2(512, 446), "size": Vector2(420, 24)},
				{"position": Vector2(180, 300), "size": Vector2(260, 22), "vertical": true},
				{"position": Vector2(844, 300), "size": Vector2(260, 22), "vertical": true},
			]
	return [
		{"position": Vector2(512, 154), "size": Vector2(280, 20)},
		{"position": Vector2(512, 446), "size": Vector2(280, 20)},
	]


func _variant_energy_lines() -> Array[Dictionary]:
	match variant:
		"weapon":
			return [
				{"from": Vector2(308, 246), "to": Vector2(716, 246), "color": Color(0.24, 0.9, 1.0, 0.52), "width": 4.0},
				{"from": Vector2(308, 380), "to": Vector2(716, 380), "color": Color(0.24, 0.9, 1.0, 0.38), "width": 3.0},
			]
		"merchant":
			return [
				{"from": Vector2(360, 300), "to": Vector2(664, 300), "color": Color(0.24, 0.9, 1.0, 0.48), "width": 4.0},
			]
		"boss":
			return [
				{"from": Vector2(248, 300), "to": Vector2(776, 300), "color": Color(0.9, 0.18, 0.12, 0.45), "width": 4.0},
				{"from": Vector2(512, 174), "to": Vector2(512, 426), "color": Color(0.9, 0.18, 0.12, 0.28), "width": 3.0},
			]
	return [
		{"from": Vector2(250, 302), "to": Vector2(774, 302), "color": Color(0.24, 0.9, 1.0, 0.22), "width": 2.0},
	]


func _variant_equipment() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(208, 300), "size": Vector2(112, 236), "kind": "pipe", "glow": true},
				{"position": Vector2(816, 300), "size": Vector2(112, 236), "kind": "pipe", "glow": true},
				{"position": Vector2(512, 120), "size": Vector2(260, 42), "kind": "door"},
			]
		"drone":
			return [
				{"position": Vector2(206, 220), "size": Vector2(124, 86), "kind": "rack"},
				{"position": Vector2(818, 396), "size": Vector2(124, 86), "kind": "rack"},
				{"position": Vector2(512, 128), "size": Vector2(300, 42), "kind": "conveyor"},
				{"position": Vector2(512, 472), "size": Vector2(300, 42), "kind": "conveyor"},
			]
		"test":
			return [
				{"position": Vector2(188, 302), "size": Vector2(92, 240), "kind": "rack", "glow": true},
				{"position": Vector2(836, 302), "size": Vector2(92, 240), "kind": "rack", "glow": true},
			]
		"weapon":
			return [
				{"position": Vector2(228, 304), "size": Vector2(126, 230), "kind": "rack", "glow": true},
				{"position": Vector2(796, 304), "size": Vector2(126, 230), "kind": "rack", "glow": true},
				{"position": Vector2(512, 236), "size": Vector2(188, 44), "kind": "terminal", "glow": true},
			]
		"elite":
			return [
				{"position": Vector2(188, 196), "size": Vector2(130, 84), "kind": "bay", "glow": true},
				{"position": Vector2(836, 404), "size": Vector2(130, 84), "kind": "bay", "glow": true},
				{"position": Vector2(512, 120), "size": Vector2(310, 42), "kind": "conveyor"},
			]
		"merchant":
			return [
				{"position": Vector2(512, 224), "size": Vector2(320, 76), "kind": "terminal", "glow": true},
				{"position": Vector2(216, 390), "size": Vector2(118, 140), "kind": "rack"},
				{"position": Vector2(808, 390), "size": Vector2(118, 140), "kind": "rack"},
			]
		"boss":
			return [
				{"position": Vector2(512, 130), "size": Vector2(420, 80), "kind": "door", "glow": true},
				{"position": Vector2(184, 302), "size": Vector2(100, 300), "kind": "bay", "glow": true},
				{"position": Vector2(840, 302), "size": Vector2(100, 300), "kind": "bay", "glow": true},
			]
	return [
		{"position": Vector2(184, 306), "size": Vector2(100, 240), "kind": "rack", "glow": true},
		{"position": Vector2(840, 306), "size": Vector2(100, 240), "kind": "rack", "glow": true},
		{"position": Vector2(512, 128), "size": Vector2(280, 42), "kind": "conveyor"},
	]


func _add_warning_strip(center: Vector2, size: Vector2, vertical := false) -> void:
	var half := size * 0.5
	var body := Polygon2D.new()
	body.name = "WarningStrip"
	body.color = Color(0.62, 0.38, 0.08, 0.42)
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

	var stripe_count := 8
	for i in range(stripe_count):
		var offset := -half.x + i * (size.x / float(stripe_count))
		if vertical:
			_add_line(center + Vector2(-half.y, offset), center + Vector2(half.y, offset + 18), Color(1.0, 0.68, 0.12, 0.55), 2.0)
		else:
			_add_line(center + Vector2(offset, -half.y), center + Vector2(offset + 18, half.y), Color(1.0, 0.68, 0.12, 0.55), 2.0)


func _add_equipment(center: Vector2, size: Vector2, kind: String, glow: bool) -> void:
	var half := size * 0.5
	var body := Polygon2D.new()
	body.name = "FactoryEquipment"
	body.color = Color(0.075, 0.088, 0.098, 0.86)
	if kind == "bay":
		body.color = Color(0.09, 0.08, 0.076, 0.88)
	elif kind == "terminal":
		body.color = Color(0.045, 0.06, 0.064, 0.9)
	body.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(body)

	var rim_color := Color(0.26, 0.86, 0.98, 0.68) if glow else Color(0.62, 0.66, 0.64, 0.42)
	_add_line(center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), rim_color, 2.0)
	_add_line(center + Vector2(half.x, -half.y), center + Vector2(half.x, half.y), rim_color, 2.0)
	_add_line(center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y), rim_color, 2.0)
	_add_line(center + Vector2(-half.x, half.y), center + Vector2(-half.x, -half.y), rim_color, 2.0)

	if kind in ["rack", "bay"]:
		for line_index in range(3):
			var y := center.y - half.y * 0.45 + line_index * half.y * 0.45
			_add_line(Vector2(center.x - half.x * 0.64, y), Vector2(center.x + half.x * 0.64, y), Color(0.72, 0.78, 0.76, 0.28), 2.0)
	if kind == "conveyor":
		for line_index in range(4):
			var x := center.x - half.x * 0.75 + line_index * half.x * 0.5
			_add_line(Vector2(x, center.y - half.y * 0.42), Vector2(x + 42, center.y + half.y * 0.42), Color(0.85, 0.55, 0.12, 0.34), 2.0)
	if glow:
		_add_line(center + Vector2(-half.x * 0.54, 0), center + Vector2(half.x * 0.54, 0), Color(0.35, 0.95, 1.0, 0.72), 3.0)


func _add_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.name = "FactoryLine"
	line.z_index = 1
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	add_child(line)
