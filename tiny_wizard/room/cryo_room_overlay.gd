class_name CryoRoomOverlay
extends Node2D


@export var variant := "combat"


func _ready() -> void:
	z_index = -2
	_build_floor_tint()
	_build_tile_grid()
	_build_frost_patches()
	_build_equipment_accents()


func _build_floor_tint() -> void:
	var floor := Polygon2D.new()
	floor.name = "CryoFloorTint"
	floor.color = Color(0.05, 0.11, 0.16, 0.48)
	floor.polygon = PackedVector2Array([
		Vector2(72, 92),
		Vector2(952, 92),
		Vector2(952, 508),
		Vector2(72, 508),
	])
	add_child(floor)


func _build_tile_grid() -> void:
	for x in range(128, 912, 64):
		_add_line(Vector2(x, 104), Vector2(x, 496), Color(0.18, 0.33, 0.38, 0.28), 1.0)
	for y in range(128, 488, 64):
		_add_line(Vector2(86, y), Vector2(938, y), Color(0.18, 0.33, 0.38, 0.28), 1.0)


func _build_frost_patches() -> void:
	var patches := _variant_patches()
	for patch in patches:
		_add_patch(patch.get("position", Vector2.ZERO), patch.get("size", Vector2(90, 42)), patch.get("alpha", 0.22))


func _build_equipment_accents() -> void:
	var equipment := _variant_equipment()
	for item in equipment:
		var pos := item.get("position", Vector2.ZERO) as Vector2
		var size := item.get("size", Vector2(80, 36)) as Vector2
		_add_equipment(pos, size, item.get("glow", false))


func _variant_patches() -> Array[Dictionary]:
	match variant:
		"pod":
			return [
				{"position": Vector2(256, 240), "size": Vector2(126, 58), "alpha": 0.26},
				{"position": Vector2(768, 354), "size": Vector2(118, 52), "alpha": 0.24},
			]
		"vent":
			return [
				{"position": Vector2(300, 214), "size": Vector2(132, 54), "alpha": 0.24},
				{"position": Vector2(704, 382), "size": Vector2(150, 62), "alpha": 0.26},
			]
		"reward":
			return [
				{"position": Vector2(236, 162), "size": Vector2(98, 40), "alpha": 0.18},
				{"position": Vector2(822, 426), "size": Vector2(100, 44), "alpha": 0.18},
			]
		"elite":
			return [
				{"position": Vector2(512, 300), "size": Vector2(230, 90), "alpha": 0.23},
				{"position": Vector2(226, 196), "size": Vector2(116, 48), "alpha": 0.2},
				{"position": Vector2(790, 404), "size": Vector2(124, 48), "alpha": 0.2},
			]
		"boss":
			return [
				{"position": Vector2(512, 300), "size": Vector2(230, 90), "alpha": 0.23},
				{"position": Vector2(226, 196), "size": Vector2(116, 48), "alpha": 0.2},
				{"position": Vector2(790, 404), "size": Vector2(124, 48), "alpha": 0.2},
			]
	return [
		{"position": Vector2(250, 210), "size": Vector2(116, 48), "alpha": 0.22},
		{"position": Vector2(742, 392), "size": Vector2(130, 54), "alpha": 0.22},
	]


func _variant_equipment() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(190, 190), "size": Vector2(116, 60), "glow": true},
				{"position": Vector2(834, 390), "size": Vector2(116, 60), "glow": true},
			]
		"pod":
			return [
				{"position": Vector2(184, 302), "size": Vector2(90, 240), "glow": true},
				{"position": Vector2(840, 302), "size": Vector2(90, 240), "glow": true},
			]
		"vent":
			return [
				{"position": Vector2(512, 116), "size": Vector2(260, 38), "glow": false},
				{"position": Vector2(512, 486), "size": Vector2(260, 38), "glow": false},
			]
		"reward":
			return [
				{"position": Vector2(220, 306), "size": Vector2(90, 220), "glow": true},
				{"position": Vector2(804, 306), "size": Vector2(90, 220), "glow": true},
			]
		"elite":
			return [
				{"position": Vector2(166, 188), "size": Vector2(122, 86), "glow": true},
				{"position": Vector2(858, 412), "size": Vector2(122, 86), "glow": true},
				{"position": Vector2(512, 120), "size": Vector2(300, 42), "glow": false},
			]
		"boss":
			return [
				{"position": Vector2(512, 128), "size": Vector2(360, 72), "glow": true},
				{"position": Vector2(180, 318), "size": Vector2(84, 256), "glow": true},
				{"position": Vector2(844, 318), "size": Vector2(84, 256), "glow": true},
			]
	return [
		{"position": Vector2(180, 300), "size": Vector2(92, 230), "glow": true},
		{"position": Vector2(844, 306), "size": Vector2(92, 230), "glow": true},
		{"position": Vector2(512, 116), "size": Vector2(220, 42), "glow": false},
	]


func _add_patch(center: Vector2, size: Vector2, alpha: float) -> void:
	var patch := Polygon2D.new()
	patch.name = "FrostPatch"
	patch.color = Color(0.52, 0.9, 1.0, alpha)
	var half := size * 0.5
	patch.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y * 0.1),
		center + Vector2(-half.x * 0.5, -half.y),
		center + Vector2(half.x * 0.55, -half.y * 0.72),
		center + Vector2(half.x, -half.y * 0.05),
		center + Vector2(half.x * 0.64, half.y),
		center + Vector2(-half.x * 0.42, half.y * 0.7),
	])
	add_child(patch)


func _add_equipment(center: Vector2, size: Vector2, glow: bool) -> void:
	var half := size * 0.5
	var body := Polygon2D.new()
	body.name = "CryoEquipment"
	body.color = Color(0.08, 0.13, 0.16, 0.78)
	body.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(body)

	var rim_color := Color(0.22, 0.72, 0.9, 0.7) if glow else Color(0.5, 0.64, 0.68, 0.48)
	_add_line(center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), rim_color, 2.0)
	_add_line(center + Vector2(half.x, -half.y), center + Vector2(half.x, half.y), rim_color, 2.0)
	_add_line(center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y), rim_color, 2.0)
	_add_line(center + Vector2(-half.x, half.y), center + Vector2(-half.x, -half.y), rim_color, 2.0)

	if glow:
		_add_line(center + Vector2(-half.x * 0.52, 0), center + Vector2(half.x * 0.52, 0), Color(0.48, 0.96, 1.0, 0.82), 3.0)


func _add_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.name = "CryoLine"
	line.z_index = 1
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	add_child(line)
