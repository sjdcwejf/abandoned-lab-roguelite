class_name DataCoreOverlay
extends Node2D


const FACILITY_COMPUTER_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/computer_spritesheet.png")
const FACILITY_SCREEN_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/computer_screen_large.png")
const FACILITY_ORB_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/orb_spritesheet.png")
const FACILITY_BUTTON_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/button_large_spritesheet.png")
const CYBERPUNK_INTERIORS_TEXTURE = preload("res://tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors.png")
const CYBERPUNK_FLOORS_TEXTURE = preload("res://tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_Floors.png")
const CYBERPUNK_WALLS_TEXTURE = preload("res://tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_Walls.png")

@export var variant := "server"


func _ready() -> void:
	z_index = -2
	_build_floor()
	_build_data_core_frame()
	_build_wall_background_modules()
	_build_door_frames()
	_build_data_floor_panels()
	_build_grid()
	_build_room_identity_marks()
	_build_data_lines()
	_build_equipment()
	_build_alert_marks()
	_build_data_asset_props()
	_build_cyberpunk_data_props()
	_build_solid_blocking_props()
	_build_signal_noise()


func _build_floor() -> void:
	var palette: Dictionary = _background_palette()
	var floor := Polygon2D.new()
	floor.name = "DataCoreFloorTint"
	floor.color = palette["floor"] as Color
	floor.polygon = PackedVector2Array([
		Vector2(72, 92),
		Vector2(952, 92),
		Vector2(952, 508),
		Vector2(72, 508),
	])
	add_child(floor)


func _build_data_core_frame() -> void:
	var palette: Dictionary = _background_palette()
	var outer_color: Color = palette["outer_frame"] as Color
	var inner_color: Color = palette["inner_frame"] as Color
	var light_color: Color = palette["edge_light"] as Color
	_add_background_rect("DataCoreOuterFrameTop", Vector2(512, 94), Vector2(888, 28), outer_color, 0)
	_add_background_rect("DataCoreOuterFrameBottom", Vector2(512, 506), Vector2(888, 28), outer_color, 0)
	_add_background_rect("DataCoreOuterFrameLeft", Vector2(72, 300), Vector2(28, 416), outer_color, 0)
	_add_background_rect("DataCoreOuterFrameRight", Vector2(952, 300), Vector2(28, 416), outer_color, 0)
	_add_background_rect("DataCoreInnerFrameTop", Vector2(512, 112), Vector2(780, 8), inner_color, 1)
	_add_background_rect("DataCoreInnerFrameBottom", Vector2(512, 488), Vector2(780, 8), inner_color, 1)
	_add_background_rect("DataCoreInnerFrameLeft", Vector2(92, 300), Vector2(8, 330), inner_color, 1)
	_add_background_rect("DataCoreInnerFrameRight", Vector2(932, 300), Vector2(8, 330), inner_color, 1)
	for marker in _variant_wall_lights():
		var position: Vector2 = marker.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = marker.get("size", Vector2(72, 5)) as Vector2
		_add_background_rect("DataCoreWallLight", position, size, light_color, 2)


func _build_door_frames() -> void:
	var palette: Dictionary = _background_palette()
	var door_color: Color = palette["door_frame"] as Color
	var light_color: Color = palette["door_light"] as Color
	for door in [
		{"position": Vector2(512, 112), "size": Vector2(160, 18), "light_position": Vector2(512, 122), "light_size": Vector2(82, 4)},
		{"position": Vector2(512, 488), "size": Vector2(160, 18), "light_position": Vector2(512, 478), "light_size": Vector2(82, 4)},
		{"position": Vector2(92, 300), "size": Vector2(18, 148), "light_position": Vector2(102, 300), "light_size": Vector2(4, 72)},
		{"position": Vector2(932, 300), "size": Vector2(18, 148), "light_position": Vector2(922, 300), "light_size": Vector2(4, 72)},
	]:
		var position: Vector2 = door.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = door.get("size", Vector2.ZERO) as Vector2
		var light_position: Vector2 = door.get("light_position", Vector2.ZERO) as Vector2
		var light_size: Vector2 = door.get("light_size", Vector2.ZERO) as Vector2
		_add_background_rect("DataCoreDoorFrame", position, size, door_color, 1)
		_add_background_rect("DataCoreDoorLight", light_position, light_size, light_color, 2)


func _build_grid() -> void:
	var palette: Dictionary = _background_palette()
	var grid_color: Color = palette["grid"] as Color
	for x in range(144, 896, 64):
		_add_line(Vector2(x, 132), Vector2(x, 468), grid_color, 1.0)
	for y in range(140, 472, 64):
		_add_line(Vector2(116, y), Vector2(908, y), grid_color, 1.0)


func _build_data_floor_panels() -> void:
	var palette: Dictionary = _background_palette()
	var panel_color: Color = palette["panel"] as Color
	for panel in _variant_floor_panels():
		var position: Vector2 = panel.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = panel.get("size", Vector2(128, 72)) as Vector2
		var color: Color = panel.get("color", panel_color) as Color
		var shape := str(panel.get("shape", "rect"))
		match shape:
			"diamond":
				_add_diamond_panel(position, size, color)
			"octagon":
				_add_octagon_panel(position, size, color)
			_:
				_add_panel(position, size, color)


func _build_wall_background_modules() -> void:
	for module in _variant_wall_modules():
		var position: Vector2 = module.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = module.get("size", Vector2(96, 18)) as Vector2
		var color: Color = module.get("color", Color(0.09, 0.16, 0.2, 0.22)) as Color
		var kind := str(module.get("kind", "module"))
		_add_background_rect("DataCoreWallModule", position, size, color, 2)
		match kind:
			"vent":
				_add_wall_slats(position, size, Color(0.22, 0.5, 0.62, 0.18))
			"screen":
				_add_line(position + Vector2(-size.x * 0.42, 0), position + Vector2(size.x * 0.42, 0), Color(0.34, 0.74, 0.96, 0.16), 1.2)
			"port":
				_add_background_rect("DataCoreWallPortLight", position, Vector2(size.x * 0.32, 4), Color(0.36, 0.78, 0.96, 0.22), 3)
			"archive":
				_add_background_rect("DataCoreArchiveWallInset", position, Vector2(size.x * 0.62, size.y * 0.42), Color(0.02, 0.028, 0.045, 0.32), 3)
			"alert":
				_add_background_rect("DataCoreAnomalyWallPoint", position, Vector2(8, 8), Color(0.82, 0.15, 0.13, 0.24), 3)


func _build_room_identity_marks() -> void:
	for mark in _variant_identity_marks():
		var position: Vector2 = mark.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = mark.get("size", Vector2(52, 4)) as Vector2
		var color: Color = mark.get("color", Color(0.28, 0.7, 0.9, 0.16)) as Color
		var shape := str(mark.get("shape", "rect"))
		match shape:
			"diamond":
				_add_diamond_panel(position, size, color)
			"octagon":
				_add_octagon_panel(position, size, color)
			_:
				_add_background_rect("DataCoreIdentityMark", position, size, color, 2)


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
		var position: Vector2 = mark.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = mark.get("size", Vector2(160, 8)) as Vector2
		var color: Color = mark.get("color", Color(0.22, 0.78, 0.95, 0.2)) as Color
		_add_background_rect("DataCoreLowLightMarker", position, size, color, 1)


func _build_data_asset_props() -> void:
	for prop in _variant_asset_props():
		var texture: Texture2D = prop.get("texture") as Texture2D
		var region: Rect2 = prop.get("region", Rect2(0, 0, 16, 16)) as Rect2
		var position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
		var scale_value: Vector2 = prop.get("scale", Vector2.ONE) as Vector2
		var color: Color = prop.get("modulate", Color.WHITE) as Color
		_add_asset_sprite(texture, region, position, scale_value, color)


func _build_cyberpunk_data_props() -> void:
	for prop in _variant_cyberpunk_props():
		var texture: Texture2D = prop.get("texture") as Texture2D
		var region: Rect2 = prop.get("region", Rect2(0, 0, 16, 16)) as Rect2
		var position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
		var scale_value: Vector2 = prop.get("scale", Vector2.ONE) as Vector2
		var color: Color = prop.get("modulate", Color.WHITE) as Color
		var z_value := int(prop.get("z_index", 4))
		_add_asset_sprite(texture, region, position, scale_value, color, z_value)


func _build_solid_blocking_props() -> void:
	for prop in _variant_solid_blocking_props():
		var position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = prop.get("size", Vector2(64, 64)) as Vector2
		var name_suffix := str(prop.get("name", "Data"))
		_add_solid_blocking_prop(name_suffix, position, size)


func _build_signal_noise() -> void:
	var palette: Dictionary = _background_palette()
	var noise_color: Color = palette["signal_noise"] as Color
	var segments := [
		[Vector2(282, 188), Vector2(312, 188), Vector2(326, 198)],
		[Vector2(696, 402), Vector2(730, 402), Vector2(746, 390)],
		[Vector2(466, 154), Vector2(492, 166), Vector2(530, 166)],
		[Vector2(552, 446), Vector2(584, 434), Vector2(620, 434)],
	]
	for segment in segments:
		var line := Line2D.new()
		line.name = "DataSignalNoise"
		line.z_index = 2
		line.width = 1.2
		line.default_color = noise_color
		line.points = PackedVector2Array(segment)
		add_child(line)


func _background_palette() -> Dictionary:
	var palette := {
		"floor": Color(0.036, 0.043, 0.052, 0.74),
		"panel": Color(0.018, 0.038, 0.055, 0.38),
		"grid": Color(0.14, 0.25, 0.32, 0.16),
		"outer_frame": Color(0.018, 0.024, 0.033, 0.78),
		"inner_frame": Color(0.09, 0.14, 0.18, 0.44),
		"edge_light": Color(0.18, 0.62, 0.78, 0.24),
		"door_frame": Color(0.05, 0.07, 0.085, 0.66),
		"door_light": Color(0.26, 0.78, 0.95, 0.34),
		"signal_noise": Color(0.44, 0.82, 0.95, 0.18),
	}
	match variant:
		"archive":
			palette["floor"] = Color(0.024, 0.029, 0.04, 0.82)
			palette["panel"] = Color(0.012, 0.025, 0.044, 0.42)
			palette["edge_light"] = Color(0.18, 0.48, 0.68, 0.18)
			palette["signal_noise"] = Color(0.36, 0.64, 0.82, 0.13)
		"boss":
			palette["floor"] = Color(0.028, 0.031, 0.044, 0.8)
			palette["panel"] = Color(0.02, 0.026, 0.052, 0.44)
			palette["edge_light"] = Color(0.3, 0.32, 0.76, 0.22)
			palette["door_light"] = Color(0.82, 0.18, 0.16, 0.26)
			palette["signal_noise"] = Color(0.52, 0.48, 0.95, 0.16)
		"merchant":
			palette["floor"] = Color(0.04, 0.047, 0.058, 0.72)
			palette["panel"] = Color(0.022, 0.04, 0.06, 0.34)
			palette["edge_light"] = Color(0.32, 0.38, 0.82, 0.2)
		"satellite":
			palette["floor"] = Color(0.032, 0.037, 0.052, 0.76)
			palette["panel"] = Color(0.018, 0.03, 0.058, 0.38)
			palette["edge_light"] = Color(0.25, 0.4, 0.86, 0.2)
			palette["signal_noise"] = Color(0.5, 0.5, 0.95, 0.15)
	return palette


func _variant_floor_panels() -> Array[Dictionary]:
	var palette: Dictionary = _background_palette()
	var panel_color: Color = palette["panel"] as Color
	match variant:
		"start":
			return [
				{"position": Vector2(512, 300), "size": Vector2(156, 340), "color": Color(0.014, 0.036, 0.058, 0.48)},
				{"position": Vector2(512, 300), "size": Vector2(376, 132), "color": Color(0.018, 0.044, 0.066, 0.34)},
				{"position": Vector2(512, 300), "size": Vector2(212, 88), "color": Color(0.028, 0.058, 0.078, 0.26), "shape": "octagon"},
				{"position": Vector2(512, 126), "size": Vector2(224, 46), "color": Color(0.02, 0.038, 0.055, 0.36)},
			]
		"server":
			return [
				{"position": Vector2(184, 306), "size": Vector2(110, 282), "color": Color(0.012, 0.026, 0.046, 0.5)},
				{"position": Vector2(316, 306), "size": Vector2(92, 282), "color": Color(0.012, 0.024, 0.042, 0.34)},
				{"position": Vector2(708, 306), "size": Vector2(92, 282), "color": Color(0.012, 0.024, 0.042, 0.34)},
				{"position": Vector2(840, 306), "size": Vector2(110, 282), "color": Color(0.012, 0.026, 0.046, 0.5)},
				{"position": Vector2(512, 388), "size": Vector2(220, 82), "color": Color(0.018, 0.042, 0.06, 0.32)},
			]
		"comm":
			return [
				{"position": Vector2(512, 302), "size": Vector2(430, 194), "color": Color(0.018, 0.035, 0.068, 0.28)},
				{"position": Vector2(512, 286), "size": Vector2(284, 142), "color": Color(0.018, 0.044, 0.074, 0.38), "shape": "octagon"},
				{"position": Vector2(512, 216), "size": Vector2(332, 52), "color": Color(0.012, 0.03, 0.055, 0.42)},
				{"position": Vector2(512, 374), "size": Vector2(332, 36), "color": Color(0.012, 0.025, 0.045, 0.32)},
				{"position": Vector2(252, 222), "size": Vector2(168, 132), "color": Color(0.014, 0.032, 0.054, 0.3)},
				{"position": Vector2(772, 382), "size": Vector2(168, 132), "color": Color(0.014, 0.032, 0.054, 0.3)},
			]
		"satellite":
			return [
				{"position": Vector2(512, 300), "size": Vector2(360, 244), "color": Color(0.016, 0.028, 0.064, 0.3), "shape": "diamond"},
				{"position": Vector2(512, 300), "size": Vector2(258, 184), "color": Color(0.018, 0.024, 0.05, 0.4), "shape": "octagon"},
				{"position": Vector2(512, 300), "size": Vector2(116, 86), "color": Color(0.026, 0.032, 0.072, 0.34), "shape": "diamond"},
			]
		"archive":
			return [
				{"position": Vector2(512, 300), "size": Vector2(300, 148), "color": Color(0.012, 0.022, 0.046, 0.5)},
				{"position": Vector2(208, 232), "size": Vector2(142, 112), "color": Color(0.012, 0.018, 0.032, 0.5)},
				{"position": Vector2(208, 376), "size": Vector2(142, 112), "color": Color(0.012, 0.018, 0.032, 0.5)},
				{"position": Vector2(816, 232), "size": Vector2(142, 112), "color": Color(0.012, 0.018, 0.032, 0.5)},
				{"position": Vector2(816, 376), "size": Vector2(142, 112), "color": Color(0.012, 0.018, 0.032, 0.5)},
				{"position": Vector2(512, 430), "size": Vector2(196, 58), "color": Color(0.014, 0.026, 0.048, 0.46)},
			]
		"merchant":
			return [
				{"position": Vector2(512, 300), "size": Vector2(420, 176), "color": Color(0.018, 0.032, 0.052, 0.22)},
				{"position": Vector2(414, 232), "size": Vector2(174, 92), "color": Color(0.018, 0.032, 0.056, 0.38)},
				{"position": Vector2(610, 232), "size": Vector2(174, 92), "color": Color(0.018, 0.032, 0.056, 0.38)},
				{"position": Vector2(512, 382), "size": Vector2(258, 88), "color": Color(0.014, 0.028, 0.046, 0.28)},
			]
		"boss":
			return [
				{"position": Vector2(512, 300), "size": Vector2(466, 278), "color": Color(0.012, 0.018, 0.044, 0.4), "shape": "octagon"},
				{"position": Vector2(512, 300), "size": Vector2(332, 210), "color": Color(0.018, 0.024, 0.064, 0.38), "shape": "diamond"},
				{"position": Vector2(512, 300), "size": Vector2(196, 134), "color": Color(0.022, 0.024, 0.072, 0.46), "shape": "octagon"},
				{"position": Vector2(512, 300), "size": Vector2(82, 58), "color": Color(0.05, 0.028, 0.07, 0.36), "shape": "diamond"},
			]
	return [
		{"position": Vector2(512, 300), "size": Vector2(420, 180), "color": panel_color},
	]


func _variant_wall_lights() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(390, 112), "size": Vector2(82, 4)},
				{"position": Vector2(634, 112), "size": Vector2(82, 4)},
				{"position": Vector2(390, 488), "size": Vector2(82, 4)},
				{"position": Vector2(634, 488), "size": Vector2(82, 4)},
			]
		"server":
			return [
				{"position": Vector2(188, 112), "size": Vector2(92, 4)},
				{"position": Vector2(316, 112), "size": Vector2(68, 4)},
				{"position": Vector2(708, 112), "size": Vector2(68, 4)},
				{"position": Vector2(836, 112), "size": Vector2(92, 4)},
				{"position": Vector2(188, 488), "size": Vector2(92, 4)},
				{"position": Vector2(836, 488), "size": Vector2(92, 4)},
			]
		"comm":
			return [
				{"position": Vector2(512, 112), "size": Vector2(168, 4)},
				{"position": Vector2(300, 112), "size": Vector2(66, 4)},
				{"position": Vector2(724, 112), "size": Vector2(66, 4)},
				{"position": Vector2(512, 488), "size": Vector2(116, 4)},
			]
		"satellite":
			return [
				{"position": Vector2(208, 112), "size": Vector2(64, 4)},
				{"position": Vector2(816, 112), "size": Vector2(64, 4)},
				{"position": Vector2(208, 488), "size": Vector2(64, 4)},
				{"position": Vector2(816, 488), "size": Vector2(64, 4)},
			]
		"archive":
			return [
				{"position": Vector2(256, 112), "size": Vector2(76, 4)},
				{"position": Vector2(768, 488), "size": Vector2(76, 4)},
			]
		"boss":
			return [
				{"position": Vector2(272, 112), "size": Vector2(86, 4)},
				{"position": Vector2(752, 112), "size": Vector2(86, 4)},
				{"position": Vector2(272, 488), "size": Vector2(86, 4)},
				{"position": Vector2(752, 488), "size": Vector2(86, 4)},
			]
		"merchant":
			return [
				{"position": Vector2(360, 112), "size": Vector2(72, 4)},
				{"position": Vector2(664, 112), "size": Vector2(72, 4)},
				{"position": Vector2(512, 488), "size": Vector2(96, 4)},
			]
	return [
		{"position": Vector2(244, 112), "size": Vector2(76, 4)},
		{"position": Vector2(780, 112), "size": Vector2(76, 4)},
		{"position": Vector2(244, 488), "size": Vector2(76, 4)},
		{"position": Vector2(780, 488), "size": Vector2(76, 4)},
	]


func _variant_wall_modules() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(352, 136), "size": Vector2(76, 18), "kind": "port", "color": Color(0.04, 0.08, 0.1, 0.32)},
				{"position": Vector2(672, 136), "size": Vector2(76, 18), "kind": "port", "color": Color(0.04, 0.08, 0.1, 0.32)},
				{"position": Vector2(352, 464), "size": Vector2(76, 18), "kind": "port", "color": Color(0.04, 0.08, 0.1, 0.26)},
				{"position": Vector2(672, 464), "size": Vector2(76, 18), "kind": "port", "color": Color(0.04, 0.08, 0.1, 0.26)},
			]
		"server":
			return [
				{"position": Vector2(188, 136), "size": Vector2(112, 18), "kind": "vent", "color": Color(0.035, 0.068, 0.078, 0.38)},
				{"position": Vector2(316, 136), "size": Vector2(88, 18), "kind": "vent", "color": Color(0.035, 0.068, 0.078, 0.3)},
				{"position": Vector2(708, 136), "size": Vector2(88, 18), "kind": "vent", "color": Color(0.035, 0.068, 0.078, 0.3)},
				{"position": Vector2(836, 136), "size": Vector2(112, 18), "kind": "vent", "color": Color(0.035, 0.068, 0.078, 0.38)},
				{"position": Vector2(188, 464), "size": Vector2(112, 18), "kind": "vent", "color": Color(0.035, 0.068, 0.078, 0.3)},
				{"position": Vector2(836, 464), "size": Vector2(112, 18), "kind": "vent", "color": Color(0.035, 0.068, 0.078, 0.3)},
			]
		"comm":
			return [
				{"position": Vector2(512, 136), "size": Vector2(268, 24), "kind": "screen", "color": Color(0.032, 0.052, 0.07, 0.4)},
				{"position": Vector2(278, 136), "size": Vector2(92, 18), "kind": "port", "color": Color(0.032, 0.052, 0.07, 0.28)},
				{"position": Vector2(746, 136), "size": Vector2(92, 18), "kind": "port", "color": Color(0.032, 0.052, 0.07, 0.28)},
				{"position": Vector2(512, 464), "size": Vector2(146, 16), "kind": "screen", "color": Color(0.026, 0.042, 0.06, 0.28)},
			]
		"satellite":
			return [
				{"position": Vector2(180, 158), "size": Vector2(66, 18), "kind": "port", "color": Color(0.038, 0.046, 0.076, 0.34)},
				{"position": Vector2(844, 158), "size": Vector2(66, 18), "kind": "port", "color": Color(0.038, 0.046, 0.076, 0.34)},
				{"position": Vector2(180, 442), "size": Vector2(66, 18), "kind": "port", "color": Color(0.038, 0.046, 0.076, 0.28)},
				{"position": Vector2(844, 442), "size": Vector2(66, 18), "kind": "port", "color": Color(0.038, 0.046, 0.076, 0.28)},
				{"position": Vector2(512, 136), "size": Vector2(96, 14), "kind": "alert", "color": Color(0.07, 0.038, 0.046, 0.26)},
			]
		"archive":
			return [
				{"position": Vector2(208, 136), "size": Vector2(132, 22), "kind": "archive", "color": Color(0.022, 0.026, 0.038, 0.46)},
				{"position": Vector2(816, 136), "size": Vector2(132, 22), "kind": "archive", "color": Color(0.022, 0.026, 0.038, 0.46)},
				{"position": Vector2(208, 464), "size": Vector2(132, 22), "kind": "archive", "color": Color(0.022, 0.026, 0.038, 0.36)},
				{"position": Vector2(816, 464), "size": Vector2(132, 22), "kind": "archive", "color": Color(0.022, 0.026, 0.038, 0.36)},
			]
		"merchant":
			return [
				{"position": Vector2(420, 136), "size": Vector2(86, 16), "kind": "port", "color": Color(0.032, 0.052, 0.072, 0.26)},
				{"position": Vector2(604, 136), "size": Vector2(86, 16), "kind": "port", "color": Color(0.032, 0.052, 0.072, 0.26)},
				{"position": Vector2(512, 464), "size": Vector2(130, 14), "kind": "screen", "color": Color(0.028, 0.044, 0.062, 0.24)},
			]
		"boss":
			return [
				{"position": Vector2(512, 136), "size": Vector2(320, 24), "kind": "screen", "color": Color(0.03, 0.034, 0.062, 0.46)},
				{"position": Vector2(176, 158), "size": Vector2(72, 18), "kind": "alert", "color": Color(0.075, 0.028, 0.042, 0.34)},
				{"position": Vector2(848, 158), "size": Vector2(72, 18), "kind": "alert", "color": Color(0.075, 0.028, 0.042, 0.34)},
				{"position": Vector2(176, 442), "size": Vector2(72, 18), "kind": "alert", "color": Color(0.075, 0.028, 0.042, 0.28)},
				{"position": Vector2(848, 442), "size": Vector2(72, 18), "kind": "alert", "color": Color(0.075, 0.028, 0.042, 0.28)},
			]
	return []


func _variant_identity_marks() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(512, 212), "size": Vector2(118, 4), "color": Color(0.3, 0.74, 0.92, 0.16)},
				{"position": Vector2(512, 388), "size": Vector2(118, 4), "color": Color(0.3, 0.74, 0.92, 0.14)},
				{"position": Vector2(512, 300), "size": Vector2(18, 18), "shape": "diamond", "color": Color(0.34, 0.78, 0.96, 0.18)},
			]
		"server":
			return [
				{"position": Vector2(184, 172), "size": Vector2(72, 3), "color": Color(0.26, 0.68, 0.88, 0.14)},
				{"position": Vector2(316, 172), "size": Vector2(54, 3), "color": Color(0.26, 0.68, 0.88, 0.1)},
				{"position": Vector2(708, 172), "size": Vector2(54, 3), "color": Color(0.26, 0.68, 0.88, 0.1)},
				{"position": Vector2(840, 172), "size": Vector2(72, 3), "color": Color(0.26, 0.68, 0.88, 0.14)},
			]
		"comm":
			return [
				{"position": Vector2(512, 286), "size": Vector2(86, 48), "shape": "octagon", "color": Color(0.32, 0.72, 0.96, 0.11)},
				{"position": Vector2(512, 216), "size": Vector2(246, 4), "color": Color(0.32, 0.72, 0.96, 0.15)},
			]
		"satellite":
			return [
				{"position": Vector2(512, 300), "size": Vector2(310, 3), "color": Color(0.42, 0.5, 0.95, 0.14)},
				{"position": Vector2(512, 300), "size": Vector2(3, 210), "color": Color(0.42, 0.5, 0.95, 0.14)},
				{"position": Vector2(512, 300), "size": Vector2(42, 42), "shape": "octagon", "color": Color(0.88, 0.16, 0.16, 0.12)},
			]
		"archive":
			return [
				{"position": Vector2(208, 300), "size": Vector2(5, 252), "color": Color(0.22, 0.46, 0.64, 0.1)},
				{"position": Vector2(816, 300), "size": Vector2(5, 252), "color": Color(0.22, 0.46, 0.64, 0.1)},
				{"position": Vector2(512, 430), "size": Vector2(138, 4), "color": Color(0.32, 0.58, 0.74, 0.13)},
			]
		"merchant":
			return [
				{"position": Vector2(414, 232), "size": Vector2(92, 4), "color": Color(0.34, 0.44, 0.86, 0.14)},
				{"position": Vector2(610, 232), "size": Vector2(92, 4), "color": Color(0.34, 0.44, 0.86, 0.14)},
				{"position": Vector2(512, 382), "size": Vector2(86, 3), "color": Color(0.28, 0.66, 0.84, 0.1)},
			]
		"boss":
			return [
				{"position": Vector2(512, 300), "size": Vector2(284, 178), "shape": "octagon", "color": Color(0.4, 0.28, 0.98, 0.1)},
				{"position": Vector2(512, 300), "size": Vector2(128, 92), "shape": "octagon", "color": Color(0.72, 0.12, 0.18, 0.12)},
				{"position": Vector2(512, 300), "size": Vector2(14, 14), "shape": "diamond", "color": Color(0.92, 0.18, 0.16, 0.2)},
			]
	return []


func _variant_data_lines() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"from": Vector2(512, 134), "to": Vector2(512, 466), "color": Color(0.28, 0.72, 0.92, 0.18), "width": 2.0},
				{"from": Vector2(438, 300), "to": Vector2(586, 300), "color": Color(0.34, 0.78, 0.96, 0.16), "width": 1.5},
				{"from": Vector2(352, 136), "to": Vector2(470, 268), "color": Color(0.26, 0.66, 0.84, 0.1), "width": 1.2},
				{"from": Vector2(672, 136), "to": Vector2(554, 268), "color": Color(0.26, 0.66, 0.84, 0.1), "width": 1.2},
			]
		"server":
			return [
				{"from": Vector2(184, 176), "to": Vector2(184, 436), "color": Color(0.24, 0.7, 0.9, 0.18), "width": 2.0},
				{"from": Vector2(316, 176), "to": Vector2(316, 436), "color": Color(0.24, 0.7, 0.9, 0.12), "width": 1.5},
				{"from": Vector2(708, 176), "to": Vector2(708, 436), "color": Color(0.24, 0.7, 0.9, 0.12), "width": 1.5},
				{"from": Vector2(840, 176), "to": Vector2(840, 436), "color": Color(0.24, 0.7, 0.9, 0.18), "width": 2.0},
				{"from": Vector2(260, 388), "to": Vector2(764, 388), "color": Color(0.34, 0.74, 0.95, 0.14), "width": 1.6},
			]
		"comm":
			return [
				{"from": Vector2(512, 138), "to": Vector2(512, 250), "color": Color(0.34, 0.78, 1.0, 0.18), "width": 2.0},
				{"from": Vector2(252, 222), "to": Vector2(420, 272), "color": Color(0.34, 0.78, 1.0, 0.14), "width": 1.6},
				{"from": Vector2(772, 382), "to": Vector2(604, 328), "color": Color(0.46, 0.5, 0.95, 0.14), "width": 1.6},
				{"from": Vector2(360, 374), "to": Vector2(664, 374), "color": Color(0.32, 0.72, 0.92, 0.12), "width": 1.5},
			]
		"satellite":
			return [
				{"from": Vector2(512, 158), "to": Vector2(512, 442), "color": Color(0.44, 0.44, 0.95, 0.18), "width": 2.0},
				{"from": Vector2(236, 300), "to": Vector2(788, 300), "color": Color(0.3, 0.74, 0.95, 0.15), "width": 2.0},
				{"from": Vector2(180, 158), "to": Vector2(444, 268), "color": Color(0.95, 0.18, 0.16, 0.11), "width": 1.4},
				{"from": Vector2(844, 158), "to": Vector2(580, 268), "color": Color(0.42, 0.5, 0.95, 0.12), "width": 1.4},
				{"from": Vector2(180, 442), "to": Vector2(444, 332), "color": Color(0.42, 0.5, 0.95, 0.12), "width": 1.4},
				{"from": Vector2(844, 442), "to": Vector2(580, 332), "color": Color(0.95, 0.18, 0.16, 0.11), "width": 1.4},
			]
		"archive":
			return [
				{"from": Vector2(208, 232), "to": Vector2(420, 300), "color": Color(0.34, 0.68, 0.86, 0.11), "width": 1.5},
				{"from": Vector2(816, 232), "to": Vector2(604, 300), "color": Color(0.34, 0.68, 0.86, 0.11), "width": 1.5},
				{"from": Vector2(512, 300), "to": Vector2(512, 430), "color": Color(0.4, 0.44, 0.78, 0.14), "width": 1.5},
				{"from": Vector2(414, 430), "to": Vector2(610, 430), "color": Color(0.34, 0.68, 0.86, 0.12), "width": 1.4},
			]
		"merchant":
			return [
				{"from": Vector2(512, 470), "to": Vector2(512, 382), "color": Color(0.28, 0.66, 0.84, 0.1), "width": 1.4},
				{"from": Vector2(512, 382), "to": Vector2(414, 232), "color": Color(0.42, 0.54, 0.92, 0.13), "width": 1.5},
				{"from": Vector2(512, 382), "to": Vector2(610, 232), "color": Color(0.42, 0.54, 0.92, 0.13), "width": 1.5},
			]
		"boss":
			return [
				{"from": Vector2(238, 300), "to": Vector2(786, 300), "color": Color(0.44, 0.38, 0.98, 0.22), "width": 2.4},
				{"from": Vector2(512, 160), "to": Vector2(512, 440), "color": Color(0.95, 0.16, 0.14, 0.16), "width": 2.0},
				{"from": Vector2(330, 188), "to": Vector2(694, 412), "color": Color(0.34, 0.72, 0.96, 0.13), "width": 1.5},
				{"from": Vector2(694, 188), "to": Vector2(330, 412), "color": Color(0.34, 0.72, 0.96, 0.13), "width": 1.5},
				{"from": Vector2(512, 300), "to": Vector2(254, 176), "color": Color(0.48, 0.36, 0.98, 0.12), "width": 1.3},
				{"from": Vector2(512, 300), "to": Vector2(770, 176), "color": Color(0.48, 0.36, 0.98, 0.12), "width": 1.3},
				{"from": Vector2(512, 300), "to": Vector2(254, 424), "color": Color(0.48, 0.36, 0.98, 0.12), "width": 1.3},
				{"from": Vector2(512, 300), "to": Vector2(770, 424), "color": Color(0.48, 0.36, 0.98, 0.12), "width": 1.3},
			]
	return [
		{"from": Vector2(278, 300), "to": Vector2(746, 300), "color": Color(0.3, 0.72, 0.92, 0.18), "width": 2.0},
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


func _variant_asset_props() -> Array[Dictionary]:
	var computer_region := Rect2(0, 0, 16, 16)
	var screen_region := Rect2(0, 0, 239, 160)
	var orb_region := Rect2(0, 0, 16, 16)
	var button_region := Rect2(0, 0, 16, 16)
	match variant:
		"start":
			return [
				{"texture": FACILITY_SCREEN_TEXTURE, "region": screen_region, "position": Vector2(512, 132), "scale": Vector2(0.36, 0.36), "modulate": Color(0.62, 0.9, 1.0, 0.9)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(210, 414), "scale": Vector2(1.8, 1.8)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(816, 186), "scale": Vector2(1.8, 1.8)},
			]
		"comm":
			return [
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(252, 222), "scale": Vector2(2.1, 2.1), "modulate": Color(0.7, 0.95, 1.0, 0.92)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(772, 382), "scale": Vector2(2.1, 2.1), "modulate": Color(0.7, 0.95, 1.0, 0.92)},
				{"texture": FACILITY_BUTTON_TEXTURE, "region": button_region, "position": Vector2(512, 132), "scale": Vector2(1.5, 1.5), "modulate": Color(0.95, 0.46, 0.26, 0.92)},
			]
		"satellite":
			return [
				{"texture": FACILITY_ORB_TEXTURE, "region": orb_region, "position": Vector2(512, 300), "scale": Vector2(2.2, 2.2), "modulate": Color(1.0, 0.22, 0.18, 0.9)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(214, 212), "scale": Vector2(1.9, 1.9), "modulate": Color(1.0, 0.45, 0.35, 0.9)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(810, 388), "scale": Vector2(1.9, 1.9), "modulate": Color(1.0, 0.45, 0.35, 0.9)},
			]
		"archive", "boss":
			return [
				{"texture": FACILITY_SCREEN_TEXTURE, "region": screen_region, "position": Vector2(512, 302), "scale": Vector2(0.46, 0.46), "modulate": Color(0.9, 0.72, 0.36, 0.88)},
				{"texture": FACILITY_ORB_TEXTURE, "region": orb_region, "position": Vector2(230, 184), "scale": Vector2(1.6, 1.6), "modulate": Color(0.55, 0.92, 1.0, 0.82)},
				{"texture": FACILITY_ORB_TEXTURE, "region": orb_region, "position": Vector2(794, 416), "scale": Vector2(1.6, 1.6), "modulate": Color(0.55, 0.92, 1.0, 0.82)},
			]
		"merchant":
			return [
				{"texture": FACILITY_SCREEN_TEXTURE, "region": screen_region, "position": Vector2(512, 224), "scale": Vector2(0.42, 0.34), "modulate": Color(0.55, 0.92, 1.0, 0.9)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(218, 418), "scale": Vector2(1.8, 1.8)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(806, 418), "scale": Vector2(1.8, 1.8)},
			]
	return [
		{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(188, 420), "scale": Vector2(1.7, 1.7)},
		{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(836, 182), "scale": Vector2(1.7, 1.7)},
		{"texture": FACILITY_ORB_TEXTURE, "region": orb_region, "position": Vector2(512, 300), "scale": Vector2(1.6, 1.6), "modulate": Color(0.48, 0.9, 1.0, 0.78)},
	]


func _variant_cyberpunk_props() -> Array[Dictionary]:
	match variant:
		"server":
			return [
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(0, 96, 48, 64), "position": Vector2(188, 248), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(48, 96, 48, 64), "position": Vector2(188, 368), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(0, 96, 48, 64), "position": Vector2(836, 248), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(48, 96, 48, 64), "position": Vector2(836, 368), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(0, 48, 112, 32), "position": Vector2(512, 126), "scale": Vector2(2.1, 1.65), "modulate": Color(0.68, 0.9, 1.0, 0.94), "z_index": 4},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(176, 96, 64, 32), "position": Vector2(512, 388), "scale": Vector2(1.2, 1.2), "z_index": 5},
			]
		"archive":
			return [
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(0, 96, 48, 64), "position": Vector2(208, 238), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(48, 96, 48, 64), "position": Vector2(208, 372), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(0, 96, 48, 64), "position": Vector2(816, 238), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(48, 96, 48, 64), "position": Vector2(816, 372), "scale": Vector2(1.8, 1.8), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(96, 48, 96, 48), "position": Vector2(512, 300), "scale": Vector2(1.75, 1.55), "modulate": Color(0.9, 0.78, 0.48, 0.94), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(192, 112, 48, 32), "position": Vector2(512, 430), "scale": Vector2(1.4, 1.4), "z_index": 5},
			]
		"comm", "satellite":
			return [
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(96, 0, 112, 48), "position": Vector2(512, 126), "scale": Vector2(1.8, 1.3), "z_index": 4},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(176, 96, 64, 32), "position": Vector2(252, 222), "scale": Vector2(1.2, 1.2), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(176, 96, 64, 32), "position": Vector2(772, 382), "scale": Vector2(1.2, 1.2), "z_index": 5},
			]
		"merchant":
			return [
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(0, 48, 112, 32), "position": Vector2(512, 224), "scale": Vector2(2.2, 1.45), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(0, 96, 48, 64), "position": Vector2(210, 386), "scale": Vector2(1.5, 1.5), "z_index": 5},
				{"texture": CYBERPUNK_INTERIORS_TEXTURE, "region": Rect2(48, 96, 48, 64), "position": Vector2(814, 386), "scale": Vector2(1.5, 1.5), "z_index": 5},
			]
	return []


func _variant_solid_blocking_props() -> Array[Dictionary]:
	match variant:
		"server":
			return [
				{"name": "LeftServerColumnA", "position": Vector2(188, 248), "size": Vector2(82, 96)},
				{"name": "LeftServerColumnB", "position": Vector2(188, 368), "size": Vector2(82, 96)},
				{"name": "RightServerColumnA", "position": Vector2(836, 248), "size": Vector2(82, 96)},
				{"name": "RightServerColumnB", "position": Vector2(836, 368), "size": Vector2(82, 96)},
				{"name": "NorthDataBridge", "position": Vector2(512, 126), "size": Vector2(270, 42)},
				{"name": "RavenKeyTerminal", "position": Vector2(512, 388), "size": Vector2(86, 56)},
			]
		"archive":
			return [
				{"name": "LeftArchiveColumnA", "position": Vector2(208, 238), "size": Vector2(82, 96)},
				{"name": "LeftArchiveColumnB", "position": Vector2(208, 372), "size": Vector2(82, 96)},
				{"name": "RightArchiveColumnA", "position": Vector2(816, 238), "size": Vector2(82, 96)},
				{"name": "RightArchiveColumnB", "position": Vector2(816, 372), "size": Vector2(82, 96)},
				{"name": "BlackBoxArchiveCore", "position": Vector2(512, 300), "size": Vector2(190, 92)},
				{"name": "MotherBaitTerminal", "position": Vector2(512, 430), "size": Vector2(86, 50)},
			]
	return []


func _variant_alert_marks() -> Array[Dictionary]:
	match variant:
		"satellite":
			return [
				{"position": Vector2(512, 150), "size": Vector2(220, 6), "color": Color(0.72, 0.18, 0.18, 0.18)},
				{"position": Vector2(512, 450), "size": Vector2(220, 6), "color": Color(0.72, 0.18, 0.18, 0.14)},
				{"position": Vector2(312, 300), "size": Vector2(6, 112), "color": Color(0.34, 0.46, 0.92, 0.14)},
				{"position": Vector2(712, 300), "size": Vector2(6, 112), "color": Color(0.34, 0.46, 0.92, 0.14)},
			]
		"boss":
			return [
				{"position": Vector2(512, 170), "size": Vector2(360, 7), "color": Color(0.74, 0.16, 0.15, 0.22)},
				{"position": Vector2(512, 430), "size": Vector2(360, 7), "color": Color(0.74, 0.16, 0.15, 0.18)},
				{"position": Vector2(512, 300), "size": Vector2(8, 220), "color": Color(0.38, 0.34, 0.96, 0.12)},
			]
		"archive":
			return [
				{"position": Vector2(512, 430), "size": Vector2(230, 5), "color": Color(0.26, 0.56, 0.75, 0.12)},
			]
		"merchant":
			return [
				{"position": Vector2(512, 224), "size": Vector2(260, 5), "color": Color(0.38, 0.38, 0.86, 0.14)},
			]
	return [
		{"position": Vector2(512, 454), "size": Vector2(240, 5), "color": Color(0.24, 0.62, 0.82, 0.14)},
	]


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


func _add_panel(center: Vector2, size: Vector2, color: Color) -> void:
	var half := size * 0.5
	var panel := Polygon2D.new()
	panel.name = "DataFloorPanel"
	panel.color = color
	panel.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(panel)


func _add_diamond_panel(center: Vector2, size: Vector2, color: Color) -> void:
	var half: Vector2 = size * 0.5
	var panel := Polygon2D.new()
	panel.name = "DataFloorDiamondPanel"
	panel.color = color
	panel.polygon = PackedVector2Array([
		center + Vector2(0, -half.y),
		center + Vector2(half.x, 0),
		center + Vector2(0, half.y),
		center + Vector2(-half.x, 0),
	])
	add_child(panel)


func _add_octagon_panel(center: Vector2, size: Vector2, color: Color) -> void:
	var half: Vector2 = size * 0.5
	var bevel: Vector2 = Vector2(minf(half.x * 0.32, 42.0), minf(half.y * 0.32, 34.0))
	var panel := Polygon2D.new()
	panel.name = "DataFloorOctagonPanel"
	panel.color = color
	panel.polygon = PackedVector2Array([
		center + Vector2(-half.x + bevel.x, -half.y),
		center + Vector2(half.x - bevel.x, -half.y),
		center + Vector2(half.x, -half.y + bevel.y),
		center + Vector2(half.x, half.y - bevel.y),
		center + Vector2(half.x - bevel.x, half.y),
		center + Vector2(-half.x + bevel.x, half.y),
		center + Vector2(-half.x, half.y - bevel.y),
		center + Vector2(-half.x, -half.y + bevel.y),
	])
	add_child(panel)


func _add_wall_slats(center: Vector2, size: Vector2, color: Color) -> void:
	var left: float = center.x - size.x * 0.38
	var right: float = center.x + size.x * 0.38
	var y: float = center.y
	for index in range(4):
		var offset: float = (float(index) - 1.5) * 4.0
		_add_line(Vector2(left, y + offset), Vector2(right, y + offset), color, 1.0)


func _add_background_rect(node_name: String, center: Vector2, size: Vector2, color: Color, z_value := 0) -> void:
	var half := size * 0.5
	var rect_node := Polygon2D.new()
	rect_node.name = node_name
	rect_node.z_index = z_value
	rect_node.color = color
	rect_node.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(rect_node)


func _add_asset_sprite(texture: Texture2D, region: Rect2, position: Vector2, scale_value: Vector2, color: Color, z_value := 3) -> void:
	if texture == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.name = "DataAssetProp"
	sprite.texture = atlas
	sprite.position = position
	sprite.scale = scale_value
	sprite.modulate = color
	sprite.z_index = z_value
	add_child(sprite)


func _add_solid_blocking_prop(name_suffix: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "SolidBlocker%s" % name_suffix
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 15
	body.add_to_group("solid_blocking_prop")
	body.set_meta("solid_blocking_prop", true)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


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
