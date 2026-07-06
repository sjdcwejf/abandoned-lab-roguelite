class_name MotherHiveOverlay
extends Node2D


@export_enum(
	"entrance",
	"transition",
	"recall",
	"signal",
	"antechamber",
	"supply",
	"boss"
) var variant := "entrance"


func _ready() -> void:
	z_index = -3
	_build_base_floor()
	_build_frame()
	_build_door_frames()
	_build_variant_background()
	_build_subtle_pulses()


func _build_base_floor() -> void:
	var colors: Dictionary = _palette()
	_add_rect("MotherHiveMetalFloor", Vector2(512, 300), Vector2(880, 416), colors.get("floor", Color(0.03, 0.032, 0.038, 0.84)) as Color, 0)
	for x in range(144, 900, 96):
		_add_line("MotherHiveFloorJoint", PackedVector2Array([Vector2(x, 124), Vector2(x, 476)]), Color(0.14, 0.16, 0.19, 0.16), 1.0, 1)
	for y in range(150, 470, 80):
		_add_line("MotherHiveFloorJoint", PackedVector2Array([Vector2(112, y), Vector2(912, y)]), Color(0.14, 0.16, 0.19, 0.16), 1.0, 1)


func _build_frame() -> void:
	var colors: Dictionary = _palette()
	var outer: Color = colors.get("outer_frame", Color(0.015, 0.017, 0.024, 0.9)) as Color
	var inner: Color = colors.get("inner_frame", Color(0.08, 0.09, 0.11, 0.48)) as Color
	_add_rect("MotherHiveOuterFrameTop", Vector2(512, 94), Vector2(888, 30), outer, 2)
	_add_rect("MotherHiveOuterFrameBottom", Vector2(512, 506), Vector2(888, 30), outer, 2)
	_add_rect("MotherHiveOuterFrameLeft", Vector2(72, 300), Vector2(30, 416), outer, 2)
	_add_rect("MotherHiveOuterFrameRight", Vector2(952, 300), Vector2(30, 416), outer, 2)
	_add_rect("MotherHiveInnerFrameTop", Vector2(512, 114), Vector2(778, 8), inner, 3)
	_add_rect("MotherHiveInnerFrameBottom", Vector2(512, 486), Vector2(778, 8), inner, 3)
	_add_rect("MotherHiveInnerFrameLeft", Vector2(94, 300), Vector2(8, 330), inner, 3)
	_add_rect("MotherHiveInnerFrameRight", Vector2(930, 300), Vector2(8, 330), inner, 3)
	_build_wall_infection()


func _build_door_frames() -> void:
	var colors: Dictionary = _palette()
	var door_color: Color = colors.get("door_frame", Color(0.045, 0.05, 0.06, 0.74)) as Color
	var door_light: Color = colors.get("door_light", Color(0.24, 0.64, 0.9, 0.22)) as Color
	var source_light: Color = colors.get("source", Color(0.42, 0.1, 0.62, 0.22)) as Color
	var doors: Array[Dictionary] = [
		{"p": Vector2(512, 114), "s": Vector2(158, 18), "lp": Vector2(512, 124), "ls": Vector2(78, 4)},
		{"p": Vector2(512, 486), "s": Vector2(158, 18), "lp": Vector2(512, 476), "ls": Vector2(78, 4)},
		{"p": Vector2(94, 300), "s": Vector2(18, 146), "lp": Vector2(104, 300), "ls": Vector2(4, 70)},
		{"p": Vector2(930, 300), "s": Vector2(18, 146), "lp": Vector2(920, 300), "ls": Vector2(4, 70)},
	]
	for door_value in doors:
		var door: Dictionary = door_value as Dictionary
		_add_rect("MotherHiveDoorFrame", door.get("p", Vector2.ZERO) as Vector2, door.get("s", Vector2.ZERO) as Vector2, door_color, 4)
		_add_rect("MotherHiveDoorLight", door.get("lp", Vector2.ZERO) as Vector2, door.get("ls", Vector2.ZERO) as Vector2, door_light, 5)
	if variant in ["transition", "recall", "boss"]:
		_add_line("MotherHiveDoorInfection", PackedVector2Array([Vector2(452, 486), Vector2(486, 456), Vector2(512, 430), Vector2(548, 456), Vector2(576, 486)]), source_light, 2.2, 6)
	if variant == "boss":
		_add_ring("MotherHiveBossDoorSigil", Vector2(512, 455), 34.0, source_light, 2.0, 6)


func _build_wall_infection() -> void:
	var colors: Dictionary = _palette()
	var source_color: Color = colors.get("source", Color(0.42, 0.1, 0.62, 0.18)) as Color
	var crack_color: Color = colors.get("crack", Color(0.36, 0.34, 0.5, 0.16)) as Color
	var intensity: int = _infection_level()
	var paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(116, 128), Vector2(150, 156), Vector2(178, 170), Vector2(204, 198)]),
		PackedVector2Array([Vector2(910, 138), Vector2(874, 158), Vector2(846, 188), Vector2(812, 202)]),
		PackedVector2Array([Vector2(112, 472), Vector2(146, 442), Vector2(176, 430), Vector2(214, 406)]),
		PackedVector2Array([Vector2(902, 470), Vector2(874, 436), Vector2(846, 418), Vector2(802, 396)]),
	]
	for index in range(mini(intensity + 1, paths.size())):
		_add_line("MotherHiveWallRoot", paths[index], source_color, 2.4, 5)
		_add_line("MotherHiveWallCrack", paths[index], crack_color, 5.5, 4)


func _build_variant_background() -> void:
	match variant:
		"transition":
			_build_transition_background()
		"recall":
			_build_recall_background()
		"signal":
			_build_signal_background()
		"antechamber":
			_build_antechamber_background()
		"supply":
			_build_supply_background()
		"boss":
			_build_boss_background()
		_:
			_build_entrance_background()


func _build_entrance_background() -> void:
	var colors: Dictionary = _palette()
	_add_rect("MotherHiveBrokenDataPath", Vector2(512, 300), Vector2(150, 292), colors.get("panel", Color(0.02, 0.035, 0.06, 0.34)) as Color, 2)
	_add_rect("MotherHiveAccessCheck", Vector2(512, 302), Vector2(244, 92), Color(0.035, 0.06, 0.082, 0.32), 3)
	_add_line("MotherHiveBrokenDataLine", PackedVector2Array([Vector2(512, 138), Vector2(512, 216), Vector2(494, 250), Vector2(530, 302), Vector2(512, 466)]), Color(0.22, 0.62, 0.88, 0.24), 2.0, 4)
	_add_line("MotherHiveFirstSourceCreep", PackedVector2Array([Vector2(188, 434), Vector2(236, 406), Vector2(292, 382)]), colors.get("source", Color(0.4, 0.08, 0.58, 0.2)) as Color, 2.0, 4)


func _build_transition_background() -> void:
	var colors: Dictionary = _palette()
	_add_rect("EntropyBrokenPanelA", Vector2(334, 260), Vector2(260, 120), Color(0.025, 0.035, 0.05, 0.28), 2)
	_add_rect("EntropyBrokenPanelB", Vector2(676, 352), Vector2(280, 132), Color(0.025, 0.03, 0.048, 0.32), 2)
	_add_line("EntropyOffsetDataLine", PackedVector2Array([Vector2(164, 186), Vector2(270, 222), Vector2(398, 212), Vector2(486, 286), Vector2(640, 286), Vector2(826, 372)]), Color(0.28, 0.56, 0.86, 0.18), 2.0, 4)
	_add_line("EntropySourceSplit", PackedVector2Array([Vector2(240, 156), Vector2(320, 238), Vector2(438, 286), Vector2(562, 350), Vector2(734, 440)]), colors.get("source", Color(0.44, 0.1, 0.62, 0.3)) as Color, 3.2, 5)
	_add_line("EntropyHairlineCrack", PackedVector2Array([Vector2(720, 156), Vector2(678, 214), Vector2(704, 270), Vector2(652, 330), Vector2(670, 414)]), Color(0.58, 0.26, 0.72, 0.16), 1.4, 5)


func _build_recall_background() -> void:
	var colors: Dictionary = _palette()
	var source: Color = colors.get("source", Color(0.44, 0.1, 0.62, 0.3)) as Color
	var red: Color = colors.get("red", Color(0.68, 0.08, 0.08, 0.22)) as Color
	_add_ring("RecallOuterProtocol", Vector2(512, 300), 146.0, Color(0.45, 0.16, 0.68, 0.24), 3.0, 4)
	_add_ring("RecallInnerProtocol", Vector2(512, 300), 88.0, Color(0.72, 0.12, 0.16, 0.15), 2.2, 4)
	var nodes: Array[Vector2] = [Vector2(384, 222), Vector2(640, 222), Vector2(512, 392)]
	for node_position in nodes:
		_add_octagon("RecallNodeBase", node_position, Vector2(72, 72), Color(0.13, 0.04, 0.18, 0.32), 3)
		_add_ring("RecallNodeHalo", node_position, 38.0, source, 2.0, 4)
		_add_line("RecallNodeLink", PackedVector2Array([node_position, Vector2(512, 300)]), source, 2.0, 3)
	_add_rect("RecallCenterPulse", Vector2(512, 300), Vector2(28, 28), red, 5)


func _build_signal_background() -> void:
	var colors: Dictionary = _palette()
	_add_octagon("SignalReceiveZone", Vector2(512, 282), Vector2(260, 150), Color(0.028, 0.045, 0.072, 0.36), 2)
	_add_rect("SignalArchiveReadZone", Vector2(512, 410), Vector2(260, 70), Color(0.032, 0.025, 0.052, 0.36), 3)
	for start_position in [Vector2(156, 150), Vector2(860, 154), Vector2(160, 440), Vector2(860, 438)]:
		_add_line("MotherSignalDataFeed", PackedVector2Array([start_position, Vector2(512, 282)]), Color(0.24, 0.62, 0.88, 0.2), 1.8, 4)
	_add_line("MotherSignalNeuralTrace", PackedVector2Array([Vector2(270, 202), Vector2(352, 238), Vector2(438, 228), Vector2(518, 282), Vector2(618, 254), Vector2(746, 298)]), colors.get("source", Color(0.42, 0.1, 0.58, 0.18)) as Color, 2.0, 5)


func _build_antechamber_background() -> void:
	var colors: Dictionary = _palette()
	var source: Color = colors.get("source", Color(0.44, 0.1, 0.62, 0.34)) as Color
	_add_diamond("HivePressureField", Vector2(512, 300), Vector2(360, 220), Color(0.08, 0.025, 0.1, 0.36), 2)
	_add_line("HiveAntechamberMainRoute", PackedVector2Array([Vector2(512, 132), Vector2(504, 222), Vector2(560, 296), Vector2(506, 380), Vector2(512, 468)]), Color(0.24, 0.5, 0.74, 0.14), 2.4, 4)
	for root in [
		PackedVector2Array([Vector2(116, 286), Vector2(220, 278), Vector2(332, 312), Vector2(444, 288)]),
		PackedVector2Array([Vector2(900, 326), Vector2(800, 340), Vector2(690, 318), Vector2(578, 354)]),
		PackedVector2Array([Vector2(210, 456), Vector2(326, 408), Vector2(468, 394)]),
	]:
		_add_line("HiveAntechamberRoot", root, source, 4.2, 5)


func _build_supply_background() -> void:
	var colors: Dictionary = _palette()
	_add_rect("FinalSupplySafeZone", Vector2(512, 310), Vector2(360, 170), Color(0.035, 0.045, 0.058, 0.46), 2)
	_add_rect("FinalSupplyRavenZone", Vector2(602, 300), Vector2(130, 78), Color(0.042, 0.052, 0.072, 0.42), 3)
	_add_rect("FinalSupplyTerminalZone", Vector2(418, 336), Vector2(128, 74), Color(0.032, 0.04, 0.06, 0.38), 3)
	_add_line("FinalSupplyWeakGuide", PackedVector2Array([Vector2(512, 470), Vector2(512, 390), Vector2(418, 336), Vector2(602, 300)]), Color(0.26, 0.58, 0.88, 0.16), 1.8, 4)
	_add_line("FinalSupplyContainedSource", PackedVector2Array([Vector2(822, 448), Vector2(772, 410), Vector2(706, 386)]), colors.get("source", Color(0.42, 0.1, 0.58, 0.16)) as Color, 2.4, 4)


func _build_boss_background() -> void:
	var colors: Dictionary = _palette()
	var source: Color = colors.get("source", Color(0.5, 0.1, 0.66, 0.34)) as Color
	var red: Color = colors.get("red", Color(0.72, 0.08, 0.08, 0.24)) as Color
	_add_octagon("MotherCoreOuterField", Vector2(512, 300), Vector2(390, 260), Color(0.085, 0.02, 0.105, 0.42), 2)
	_add_ring("MotherCoreProtocolOuter", Vector2(512, 300), 172.0, source, 3.0, 4)
	_add_ring("MotherCoreProtocolMiddle", Vector2(512, 300), 118.0, Color(0.7, 0.1, 0.16, 0.22), 2.4, 4)
	_add_ring("MotherCoreProtocolInner", Vector2(512, 300), 58.0, Color(0.35, 0.42, 0.86, 0.18), 2.0, 4)
	for point in [Vector2(512, 124), Vector2(512, 476), Vector2(120, 300), Vector2(904, 300), Vector2(210, 150), Vector2(814, 450)]:
		_add_line("MotherCoreVein", PackedVector2Array([point, Vector2(512, 300)]), source, 2.4, 3)
	_add_rect("MotherCorePulse", Vector2(512, 300), Vector2(38, 38), red, 5)


func _build_subtle_pulses() -> void:
	var colors: Dictionary = _palette()
	var red: Color = colors.get("red", Color(0.68, 0.08, 0.08, 0.2)) as Color
	var positions: Array[Vector2] = _pulse_positions()
	for pulse_position in positions:
		_add_rect("MotherHivePulseDot", pulse_position, Vector2(8, 8), red, 6)


func _pulse_positions() -> Array[Vector2]:
	match variant:
		"boss":
			return [Vector2(176, 154), Vector2(848, 152), Vector2(180, 446), Vector2(844, 446), Vector2(512, 300)]
		"recall":
			return [Vector2(512, 300), Vector2(384, 222), Vector2(640, 222), Vector2(512, 392)]
		"transition", "antechamber":
			return [Vector2(210, 178), Vector2(804, 420)]
	return []


func _infection_level() -> int:
	match variant:
		"entrance":
			return 1
		"transition":
			return 2
		"recall", "signal", "supply":
			return 3
		"antechamber":
			return 4
		"boss":
			return 5
	return 1


func _palette() -> Dictionary:
	var colors: Dictionary = {
		"floor": Color(0.03, 0.033, 0.04, 0.84),
		"panel": Color(0.018, 0.035, 0.052, 0.34),
		"outer_frame": Color(0.012, 0.014, 0.02, 0.9),
		"inner_frame": Color(0.07, 0.08, 0.1, 0.5),
		"door_frame": Color(0.045, 0.05, 0.058, 0.74),
		"door_light": Color(0.22, 0.56, 0.82, 0.22),
		"source": Color(0.42, 0.1, 0.58, 0.22),
		"crack": Color(0.35, 0.3, 0.44, 0.16),
		"red": Color(0.66, 0.07, 0.07, 0.18),
	}
	match variant:
		"transition":
			colors["source"] = Color(0.44, 0.1, 0.62, 0.28)
		"recall":
			colors["floor"] = Color(0.026, 0.028, 0.038, 0.86)
			colors["source"] = Color(0.5, 0.11, 0.68, 0.32)
			colors["red"] = Color(0.72, 0.08, 0.08, 0.24)
		"signal":
			colors["source"] = Color(0.38, 0.12, 0.62, 0.24)
			colors["door_light"] = Color(0.24, 0.64, 0.9, 0.2)
		"antechamber":
			colors["floor"] = Color(0.024, 0.024, 0.032, 0.88)
			colors["source"] = Color(0.48, 0.1, 0.62, 0.36)
		"supply":
			colors["floor"] = Color(0.034, 0.038, 0.046, 0.82)
			colors["source"] = Color(0.38, 0.1, 0.54, 0.18)
		"boss":
			colors["floor"] = Color(0.02, 0.018, 0.027, 0.9)
			colors["source"] = Color(0.5, 0.1, 0.68, 0.38)
			colors["red"] = Color(0.72, 0.08, 0.08, 0.26)
			colors["door_light"] = Color(0.7, 0.08, 0.1, 0.22)
	return colors


func _add_rect(name_value: String, center: Vector2, size: Vector2, color: Color, z_value: int) -> Polygon2D:
	var half: Vector2 = size * 0.5
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = name_value
	polygon.z_index = z_value
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(polygon)
	return polygon


func _add_diamond(name_value: String, center: Vector2, size: Vector2, color: Color, z_value: int) -> Polygon2D:
	var half: Vector2 = size * 0.5
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = name_value
	polygon.z_index = z_value
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		center + Vector2(0, -half.y),
		center + Vector2(half.x, 0),
		center + Vector2(0, half.y),
		center + Vector2(-half.x, 0),
	])
	add_child(polygon)
	return polygon


func _add_octagon(name_value: String, center: Vector2, size: Vector2, color: Color, z_value: int) -> Polygon2D:
	var half: Vector2 = size * 0.5
	var cut: Vector2 = Vector2(size.x * 0.18, size.y * 0.18)
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = name_value
	polygon.z_index = z_value
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		center + Vector2(-half.x + cut.x, -half.y),
		center + Vector2(half.x - cut.x, -half.y),
		center + Vector2(half.x, -half.y + cut.y),
		center + Vector2(half.x, half.y - cut.y),
		center + Vector2(half.x - cut.x, half.y),
		center + Vector2(-half.x + cut.x, half.y),
		center + Vector2(-half.x, half.y - cut.y),
		center + Vector2(-half.x, -half.y + cut.y),
	])
	add_child(polygon)
	return polygon


func _add_line(name_value: String, points: PackedVector2Array, color: Color, width: float, z_value: int) -> Line2D:
	var line: Line2D = Line2D.new()
	line.name = name_value
	line.z_index = z_value
	line.width = width
	line.default_color = color
	line.points = points
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)
	return line


func _add_ring(name_value: String, center: Vector2, radius: float, color: Color, width: float, z_value: int) -> Line2D:
	var points: PackedVector2Array = PackedVector2Array()
	var segment_count: int = 48
	for index in range(segment_count + 1):
		var angle: float = TAU * float(index) / float(segment_count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return _add_line(name_value, points, color, width, z_value)
