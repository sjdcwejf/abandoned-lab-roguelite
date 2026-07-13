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


const ROOM_CENTER: Vector2 = Vector2(512, 300)
const FLOOR_CENTER: Vector2 = Vector2(512, 300)
const FLOOR_SIZE: Vector2 = Vector2(858, 398)
const WALL_TOP_Y: float = 66.0
const WALL_BOTTOM_Y: float = 534.0
const WALL_LEFT_X: float = 46.0
const WALL_RIGHT_X: float = 978.0
const INNER_TOP_Y: float = 102.0
const INNER_BOTTOM_Y: float = 498.0
const INNER_LEFT_X: float = 76.0
const INNER_RIGHT_X: float = 948.0
const BACKGROUND_VISUAL_Z := -2


func _ready() -> void:
	# Final chapter art must cover the inherited lab/factory backdrop while staying
	# behind gameplay actors and interactables.
	z_index = -2
	call_deferred("_build_hive_background")


func _build_hive_background() -> void:
	_hide_inherited_lab_art()
	var colors: Dictionary = _palette()
	_build_floor_system(colors)
	_build_wall_system(colors)
	_build_variant_template(colors)
	_build_subtle_pulses(colors)


func _hide_inherited_lab_art() -> void:
	var room := get_parent()
	if room == null:
		return
	var inherited_walls := room.get_node_or_null("RoomWalls") as CanvasItem
	if inherited_walls != null:
		_hide_canvas_tree(inherited_walls)
		if inherited_walls is Sprite2D:
			(inherited_walls as Sprite2D).texture = null


func _hide_canvas_tree(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	for child in node.get_children():
		_hide_canvas_tree(child)


func _build_floor_system(colors: Dictionary) -> void:
	_build_damaged_metal_floor(colors)
	_build_facility_residue_floor(colors)
	_build_source_corruption_floor(colors)
	_build_wall_floor_transition(colors)


func _build_damaged_metal_floor(colors: Dictionary) -> void:
	var floor_color: Color = colors.get("floor_base", Color(0.095, 0.105, 0.12, 0.98)) as Color
	var panel_a: Color = colors.get("floor_panel_a", Color(0.13, 0.142, 0.16, 0.74)) as Color
	var panel_b: Color = colors.get("floor_panel_b", Color(0.072, 0.082, 0.098, 0.64)) as Color
	var panel_c: Color = colors.get("floor_panel_c", Color(0.105, 0.114, 0.134, 0.58)) as Color
	var seam_color: Color = colors.get("floor_seam", Color(0.19, 0.215, 0.245, 0.34)) as Color

	_add_rect("FinalHiveDamagedMetalBase", FLOOR_CENTER, FLOOR_SIZE, floor_color, 0)

	for row in range(6):
		for column in range(11):
			var center: Vector2 = Vector2(102 + column * 82, 112 + row * 64)
			var panel_color: Color = panel_b
			if (row + column + _variant_seed()) % 5 == 0:
				panel_color = panel_a
			elif (row * 3 + column) % 4 == 0:
				panel_color = panel_c
			var size: Vector2 = Vector2(72, 54)
			if variant in ["antechamber", "boss"] and (row + column) % 3 == 0:
				size = Vector2(68, 50)
			_add_rect("FinalHiveMetalFloorTile", center, size, panel_color, 1)

	for x in range(102, 926, 82):
		_add_line("FinalHiveMetalFloorVerticalJoint", PackedVector2Array([Vector2(x, 104), Vector2(x, 496)]), seam_color, 1.0, 2)
	for y in range(112, 488, 64):
		_add_line("FinalHiveMetalFloorHorizontalJoint", PackedVector2Array([Vector2(84, y), Vector2(940, y)]), seam_color, 1.0, 2)

	_add_rect("FinalHiveOldFacilitySpine", Vector2(512, 300), Vector2(150, 330), colors.get("facility_spine", Color(0.04, 0.058, 0.078, 0.46)) as Color, 2)
	if variant in ["entrance", "supply", "signal"]:
		_add_rect("FinalHiveSurvivingDataDeck", Vector2(512, 300), Vector2(284, 112), colors.get("surviving_deck", Color(0.05, 0.064, 0.086, 0.46)) as Color, 2)


func _build_facility_residue_floor(colors: Dictionary) -> void:
	var damage_level: int = _damage_level()
	var data_color: Color = colors.get("data_line", Color(0.18, 0.48, 0.72, 0.32)) as Color
	var dead_data_color: Color = colors.get("dead_data_line", Color(0.1, 0.24, 0.34, 0.24)) as Color
	var repair_color: Color = colors.get("repair_plate", Color(0.13, 0.136, 0.15, 0.38)) as Color
	var crack_color: Color = colors.get("metal_crack", Color(0.02, 0.025, 0.034, 0.44)) as Color

	var repair_panels: Array[Dictionary] = [
		{"p": Vector2(244, 196), "s": Vector2(138, 34)},
		{"p": Vector2(764, 206), "s": Vector2(148, 36)},
		{"p": Vector2(286, 412), "s": Vector2(164, 36)},
		{"p": Vector2(738, 416), "s": Vector2(150, 34)},
		{"p": Vector2(512, 148), "s": Vector2(150, 30)},
		{"p": Vector2(512, 452), "s": Vector2(166, 34)},
	]
	for index in range(mini(damage_level + 1, repair_panels.size())):
		var panel: Dictionary = repair_panels[index] as Dictionary
		_add_rect("FinalHiveDamagedRepairPlate", panel.get("p", Vector2.ZERO) as Vector2, panel.get("s", Vector2.ZERO) as Vector2, repair_color, 3)

	var cracks: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(226, 152), Vector2(284, 184), Vector2(260, 230), Vector2(334, 270)]),
		PackedVector2Array([Vector2(786, 150), Vector2(724, 198), Vector2(752, 250), Vector2(684, 316)]),
		PackedVector2Array([Vector2(176, 360), Vector2(250, 376), Vector2(288, 446)]),
		PackedVector2Array([Vector2(856, 354), Vector2(786, 382), Vector2(748, 452)]),
		PackedVector2Array([Vector2(470, 142), Vector2(512, 208), Vector2(490, 278)]),
		PackedVector2Array([Vector2(544, 458), Vector2(510, 400), Vector2(536, 330)]),
	]
	for index in range(mini(damage_level + 1, cracks.size())):
		_add_line("FinalHiveMetalFloorCrack", cracks[index], crack_color, 4.0, 4)

	var data_paths: Array[PackedVector2Array] = _data_paths_for_variant()
	for index in range(data_paths.size()):
		var path_color: Color = data_color
		if index % 2 == 1:
			path_color = dead_data_color
		_add_line("FinalHivePurposefulDataLine", data_paths[index], path_color, 2.0, 5)


func _build_source_corruption_floor(colors: Dictionary) -> void:
	var source_level: int = _source_level()
	var source_patch: Color = colors.get("source_patch", Color(0.17, 0.036, 0.23, 0.44)) as Color
	var source_line: Color = colors.get("source_line", Color(0.42, 0.09, 0.57, 0.42)) as Color
	var source_glow: Color = colors.get("source_glow", Color(0.28, 0.05, 0.38, 0.28)) as Color
	var red: Color = colors.get("pulse_red", Color(0.62, 0.055, 0.055, 0.28)) as Color

	var patches: Array[Dictionary] = _source_patches_for_variant()
	for index in range(mini(source_level + 1, patches.size())):
		var patch: Dictionary = patches[index] as Dictionary
		_add_octagon("FinalHiveCorruptedMetalPatch", patch.get("p", Vector2.ZERO) as Vector2, patch.get("s", Vector2.ZERO) as Vector2, source_patch, 4)

	var veins: Array[PackedVector2Array] = _source_veins_for_variant()
	for index in range(mini(source_level + 2, veins.size())):
		var vein: PackedVector2Array = veins[index]
		_add_line("FinalHiveSourceVeinGlow", vein, source_glow, 8.0, 4)
		_add_line("FinalHiveSourceVein", vein, source_line, 2.8, 6)

	var pulse_points: Array[Vector2] = _floor_pulse_points_for_variant()
	for index in range(mini(maxi(source_level - 1, 0), pulse_points.size())):
		_add_rect("FinalHiveLowRedPulseKnot", pulse_points[index], Vector2(8, 8), red, 7)


func _build_wall_floor_transition(colors: Dictionary) -> void:
	var metal_transition: Color = colors.get("transition_metal", Color(0.09, 0.096, 0.112, 0.72)) as Color
	var corrupted_transition: Color = colors.get("transition_corrupted", Color(0.22, 0.04, 0.31, 0.44)) as Color
	var living_transition: Color = colors.get("transition_living", Color(0.12, 0.028, 0.15, 0.56)) as Color
	var transition_color: Color = metal_transition
	if _wall_grade() == "corrupted":
		transition_color = corrupted_transition
	elif _wall_grade() in ["living", "core"]:
		transition_color = living_transition

	_add_rect("FinalHiveWallFloorTransitionTop", Vector2(512, 116), Vector2(810, 34), transition_color, 8)
	_add_rect("FinalHiveWallFloorTransitionBottom", Vector2(512, 484), Vector2(810, 34), transition_color, 8)
	_add_rect("FinalHiveWallFloorTransitionLeft", Vector2(98, 300), Vector2(40, 340), transition_color, 8)
	_add_rect("FinalHiveWallFloorTransitionRight", Vector2(926, 300), Vector2(40, 340), transition_color, 8)

	var rim_color: Color = colors.get("inner_metal_rim", Color(0.15, 0.16, 0.178, 0.52)) as Color
	_add_rect("FinalHiveBrokenInnerRimTop", Vector2(512, 130), Vector2(760, 8), rim_color, 9)
	_add_rect("FinalHiveBrokenInnerRimBottom", Vector2(512, 470), Vector2(760, 8), rim_color, 9)
	_add_rect("FinalHiveBrokenInnerRimLeft", Vector2(118, 300), Vector2(8, 304), rim_color, 9)
	_add_rect("FinalHiveBrokenInnerRimRight", Vector2(906, 300), Vector2(8, 304), rim_color, 9)


func _build_wall_system(colors: Dictionary) -> void:
	_build_outer_walls(colors)
	_build_inner_wall_rims(colors)
	_build_corruption_bands(colors)
	_build_corner_pieces(colors)
	_build_wall_overlays(colors)


func _build_outer_walls(colors: Dictionary) -> void:
	var wall_color: Color = colors.get("wall_outer", Color(0.025, 0.03, 0.04, 0.98)) as Color
	var wall_shadow: Color = colors.get("wall_shadow", Color(0.006, 0.008, 0.012, 0.88)) as Color
	_add_rect("FinalHiveOuterWallTop", Vector2(512, WALL_TOP_Y), Vector2(1024, 116), wall_color, 20)
	_add_rect("FinalHiveOuterWallBottom", Vector2(512, WALL_BOTTOM_Y), Vector2(1024, 116), wall_color, 20)
	_add_rect("FinalHiveOuterWallLeft", Vector2(WALL_LEFT_X, 300), Vector2(92, 600), wall_color, 20)
	_add_rect("FinalHiveOuterWallRight", Vector2(WALL_RIGHT_X, 300), Vector2(92, 600), wall_color, 20)

	_add_rect("FinalHiveWallDeepShadowTop", Vector2(512, 18), Vector2(1024, 36), wall_shadow, 21)
	_add_rect("FinalHiveWallDeepShadowBottom", Vector2(512, 582), Vector2(1024, 36), wall_shadow, 21)
	_add_rect("FinalHiveWallDeepShadowLeft", Vector2(18, 300), Vector2(36, 600), wall_shadow, 21)
	_add_rect("FinalHiveWallDeepShadowRight", Vector2(1006, 300), Vector2(36, 600), wall_shadow, 21)


func _build_inner_wall_rims(colors: Dictionary) -> void:
	var rim: Color = colors.get("wall_rim", Color(0.105, 0.112, 0.128, 0.88)) as Color
	var broken: Color = colors.get("wall_rim_broken", Color(0.046, 0.052, 0.064, 0.72)) as Color
	_add_rect("FinalHiveInnerMetalRimTop", Vector2(512, INNER_TOP_Y), Vector2(760, 30), rim, 22)
	_add_rect("FinalHiveInnerMetalRimBottom", Vector2(512, INNER_BOTTOM_Y), Vector2(760, 30), rim, 22)
	_add_rect("FinalHiveInnerMetalRimLeft", Vector2(INNER_LEFT_X, 300), Vector2(30, 330), rim, 22)
	_add_rect("FinalHiveInnerMetalRimRight", Vector2(INNER_RIGHT_X, 300), Vector2(30, 330), rim, 22)

	var broken_segments: Array[Dictionary] = [
		{"p": Vector2(260, 102), "s": Vector2(96, 18)},
		{"p": Vector2(742, 102), "s": Vector2(112, 18)},
		{"p": Vector2(286, 498), "s": Vector2(110, 18)},
		{"p": Vector2(760, 498), "s": Vector2(104, 18)},
		{"p": Vector2(76, 206), "s": Vector2(18, 78)},
		{"p": Vector2(948, 386), "s": Vector2(18, 90)},
	]
	for segment_value in broken_segments:
		var segment: Dictionary = segment_value as Dictionary
		_add_rect("FinalHiveBrokenWallRimSegment", segment.get("p", Vector2.ZERO) as Vector2, segment.get("s", Vector2.ZERO) as Vector2, broken, 23)


func _build_corruption_bands(colors: Dictionary) -> void:
	var band: Color = colors.get("wall_corruption_band", Color(0.18, 0.035, 0.24, 0.42)) as Color
	var heavy_band: Color = colors.get("wall_corruption_heavy", Color(0.24, 0.045, 0.31, 0.54)) as Color
	var use_heavy: bool = _wall_grade() in ["living", "core"]
	var band_color: Color = heavy_band if use_heavy else band

	_add_octagon("FinalHiveWallCorruptionTopLeft", Vector2(158, 132), Vector2(172, 44), band_color, 24)
	_add_octagon("FinalHiveWallCorruptionTopRight", Vector2(846, 132), Vector2(172, 44), band_color, 24)
	_add_octagon("FinalHiveWallCorruptionBottomLeft", Vector2(164, 468), Vector2(180, 46), band_color, 24)
	_add_octagon("FinalHiveWallCorruptionBottomRight", Vector2(838, 468), Vector2(180, 46), band_color, 24)

	if _wall_grade() in ["corrupted", "living", "core"]:
		_add_octagon("FinalHiveWallCorruptionLeftCenter", Vector2(112, 300), Vector2(54, 186), band_color, 24)
		_add_octagon("FinalHiveWallCorruptionRightCenter", Vector2(912, 300), Vector2(54, 186), band_color, 24)
	if _wall_grade() in ["living", "core"]:
		_add_rect("FinalHiveLivingWallTopBand", Vector2(512, 128), Vector2(620, 26), colors.get("living_band", Color(0.16, 0.025, 0.18, 0.58)) as Color, 25)
		_add_rect("FinalHiveLivingWallBottomBand", Vector2(512, 472), Vector2(620, 26), colors.get("living_band", Color(0.16, 0.025, 0.18, 0.58)) as Color, 25)


func _build_corner_pieces(colors: Dictionary) -> void:
	var corner_color: Color = colors.get("corner_corruption", Color(0.22, 0.04, 0.29, 0.56)) as Color
	var metal_corner: Color = colors.get("corner_metal", Color(0.055, 0.062, 0.076, 0.84)) as Color
	var red: Color = colors.get("pulse_red", Color(0.62, 0.055, 0.055, 0.24)) as Color
	var corner_data: Array[Dictionary] = [
		{"p": Vector2(96, 108), "s": Vector2(92, 76), "r": 0},
		{"p": Vector2(928, 110), "s": Vector2(100, 78), "r": 1},
		{"p": Vector2(96, 490), "s": Vector2(96, 82), "r": 2},
		{"p": Vector2(928, 488), "s": Vector2(98, 80), "r": 3},
	]
	for index in range(corner_data.size()):
		var corner: Dictionary = corner_data[index] as Dictionary
		var corner_position: Vector2 = corner.get("p", Vector2.ZERO) as Vector2
		var corner_size: Vector2 = corner.get("s", Vector2.ZERO) as Vector2
		_add_octagon("FinalHiveBrokenCornerMetal", corner_position, corner_size, metal_corner, 26)
		if index <= _infection_level():
			_add_octagon("FinalHiveCorruptedCornerPiece", corner_position + Vector2((index % 2) * 14 - 7, 0), corner_size * 0.62, corner_color, 27)
			_add_rect("FinalHiveCornerPulse", corner_position + Vector2(0, 12), Vector2(7, 7), red, 30)


func _build_wall_overlays(colors: Dictionary) -> void:
	var cracked: Color = colors.get("wall_crack", Color(0.34, 0.32, 0.44, 0.24)) as Color
	var data: Color = colors.get("wall_data", Color(0.14, 0.42, 0.62, 0.24)) as Color
	var source: Color = colors.get("wall_source_line", Color(0.38, 0.08, 0.52, 0.36)) as Color
	var red: Color = colors.get("pulse_red", Color(0.62, 0.055, 0.055, 0.22)) as Color

	var crack_paths: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(184, 100), Vector2(222, 124), Vector2(260, 116), Vector2(304, 134)]),
		PackedVector2Array([Vector2(832, 100), Vector2(794, 128), Vector2(742, 120), Vector2(710, 144)]),
		PackedVector2Array([Vector2(112, 394), Vector2(146, 364), Vector2(178, 370), Vector2(218, 342)]),
		PackedVector2Array([Vector2(908, 208), Vector2(870, 236), Vector2(842, 226), Vector2(800, 260)]),
	]
	for path in crack_paths:
		_add_line("FinalHiveWallCrackOverlay", path, cracked, 3.4, 29)

	match _wall_grade():
		"damaged":
			_add_line("FinalHiveBrokenBlueLightTop", PackedVector2Array([Vector2(316, 108), Vector2(440, 108)]), data, 3.0, 30)
			_add_line("FinalHiveBrokenBlueLightBottom", PackedVector2Array([Vector2(592, 492), Vector2(720, 492)]), data, 3.0, 30)
			_add_line("FinalHiveSmallRootOverlay", PackedVector2Array([Vector2(136, 132), Vector2(178, 158), Vector2(220, 178)]), source, 2.2, 30)
		"corrupted":
			_add_line("FinalHiveCorruptedWallRootLeft", PackedVector2Array([Vector2(110, 154), Vector2(170, 196), Vector2(222, 246), Vector2(284, 278)]), source, 4.0, 30)
			_add_line("FinalHiveBrokenWallCableRight", PackedVector2Array([Vector2(908, 160), Vector2(846, 190), Vector2(806, 238), Vector2(748, 256)]), data, 2.4, 30)
			_add_rect("FinalHiveCorruptedWallPulse", Vector2(164, 140), Vector2(8, 8), red, 31)
		"living":
			_add_line("FinalHiveLivingWallRootLeft", PackedVector2Array([Vector2(96, 166), Vector2(180, 220), Vector2(258, 296), Vector2(350, 326)]), source, 6.0, 30)
			_add_line("FinalHiveLivingWallRootRight", PackedVector2Array([Vector2(924, 428), Vector2(836, 382), Vector2(742, 322), Vector2(646, 300)]), source, 6.0, 30)
			for pulse_position in [Vector2(152, 174), Vector2(864, 414), Vector2(512, 126)]:
				_add_rect("FinalHiveLivingWallPulse", pulse_position, Vector2(9, 9), red, 31)
		"core":
			for start_position in [Vector2(142, 126), Vector2(882, 126), Vector2(142, 474), Vector2(882, 474), Vector2(512, 100), Vector2(512, 500)]:
				_add_line("FinalHiveCoreWallConduit", PackedVector2Array([start_position, ROOM_CENTER]), source, 3.2, 30)
			for pulse_position in [Vector2(150, 132), Vector2(874, 132), Vector2(150, 468), Vector2(874, 468), Vector2(512, 112), Vector2(512, 488)]:
				_add_rect("FinalHiveCoreWallPulse", pulse_position, Vector2(9, 9), red, 31)


func _build_door_system(colors: Dictionary) -> void:
	var door_dark: Color = colors.get("door_dark", Color(0.012, 0.014, 0.02, 0.92)) as Color
	var door_metal: Color = colors.get("door_metal", Color(0.075, 0.082, 0.096, 0.86)) as Color
	var door_corrupt: Color = colors.get("door_corrupt", Color(0.23, 0.045, 0.32, 0.46)) as Color
	var door_light: Color = colors.get("door_light", Color(0.18, 0.55, 0.82, 0.32)) as Color
	var red: Color = colors.get("pulse_red", Color(0.62, 0.055, 0.055, 0.24)) as Color

	var doors: Array[Dictionary] = [
		{"p": Vector2(512, 86), "s": Vector2(172, 70), "dir": "up", "light_p": Vector2(512, 122), "light_s": Vector2(82, 4)},
		{"p": Vector2(512, 514), "s": Vector2(172, 70), "dir": "down", "light_p": Vector2(512, 478), "light_s": Vector2(82, 4)},
		{"p": Vector2(64, 300), "s": Vector2(70, 164), "dir": "left", "light_p": Vector2(106, 300), "light_s": Vector2(4, 78)},
		{"p": Vector2(960, 300), "s": Vector2(70, 164), "dir": "right", "light_p": Vector2(918, 300), "light_s": Vector2(4, 78)},
	]
	for door_value in doors:
		var door: Dictionary = door_value as Dictionary
		var direction: String = door.get("dir", "") as String
		var center: Vector2 = door.get("p", Vector2.ZERO) as Vector2
		var size: Vector2 = door.get("s", Vector2.ZERO) as Vector2
		var light_position: Vector2 = door.get("light_p", Vector2.ZERO) as Vector2
		var light_size: Vector2 = door.get("light_s", Vector2.ZERO) as Vector2
		if _is_visual_door_hidden(direction):
			continue
		_add_rect("FinalHiveDoorVoid", center, size, door_dark, 32)
		_add_octagon("FinalHiveDoorBrokenMetalFrame", center, size + Vector2(24, 18), door_metal, 33)
		_add_rect("FinalHiveDoorOpeningRecess", center, size * 0.72, door_dark, 34)
		_add_rect("FinalHiveDoorDeadLight", light_position, light_size, door_light, 35)

		if _wall_grade() in ["corrupted", "living", "core"]:
			_add_line("FinalHiveDoorRootConnection", _door_root_path(direction), door_corrupt, 3.0, 36)
		if variant == "recall":
			_add_rect("FinalHiveRecallDoorMark", light_position, light_size + Vector2(12, 2), red, 36)
		elif variant == "boss":
			_add_ring("FinalHiveCoreDoorSigil", light_position, 28.0, door_corrupt, 2.2, 36)


func _is_visual_door_hidden(direction: String) -> bool:
	var room := get_parent()
	if room == null:
		return false
	match direction:
		"up":
			return room.get("hide_up_door") == true
		"down":
			return room.get("hide_down_door") == true
		"left":
			return room.get("hide_left_door") == true
		"right":
			return room.get("hide_right_door") == true
	return false


func _build_sealed_wall_patch(direction: String, center: Vector2, size: Vector2, colors: Dictionary) -> void:
	var wall_plate: Color = colors.get("wall_outer", Color(0.025, 0.03, 0.04, 0.98)) as Color
	var rim: Color = colors.get("wall_rim", Color(0.105, 0.112, 0.128, 0.88)) as Color
	var broken: Color = colors.get("wall_rim_broken", Color(0.046, 0.052, 0.064, 0.72)) as Color
	var corruption: Color = colors.get("wall_corruption_band", Color(0.18, 0.035, 0.24, 0.42)) as Color
	var crack: Color = colors.get("wall_crack", Color(0.34, 0.32, 0.44, 0.24)) as Color
	var data: Color = colors.get("wall_data", Color(0.14, 0.42, 0.62, 0.24)) as Color
	var patch_name := "FinalHiveSealedWall_%s" % direction

	if direction in ["up", "down"]:
		var rim_offset := 34.0 if direction == "up" else -34.0
		_add_rect("%sPlate" % patch_name, center, Vector2(286, size.y + 8.0), wall_plate, 32)
		_add_rect("%sMetalRim" % patch_name, center + Vector2(0, rim_offset), Vector2(248, 14), rim, 33)
		_add_rect("%sBrokenPanelLeft" % patch_name, center + Vector2(-92, rim_offset * 0.35), Vector2(74, 26), broken, 34)
		_add_rect("%sBrokenPanelRight" % patch_name, center + Vector2(94, -rim_offset * 0.25), Vector2(82, 22), broken, 34)
		_add_line(
			"%sCrack" % patch_name,
			PackedVector2Array([
				center + Vector2(-112, -12),
				center + Vector2(-52, 6),
				center + Vector2(18, -8),
				center + Vector2(88, 10),
			]),
			crack,
			2.4,
			35
		)
		_add_line(
			"%sDeadCable" % patch_name,
			PackedVector2Array([
				center + Vector2(-122, rim_offset * 0.55),
				center + Vector2(-48, rim_offset * 0.38),
				center + Vector2(26, rim_offset * 0.48),
			]),
			data,
			1.6,
			35
		)
		_add_octagon("%sCorruption" % patch_name, center + Vector2(118, rim_offset * 0.18), Vector2(76, 26), corruption, 35)
	else:
		var rim_offset := 34.0 if direction == "left" else -34.0
		_add_rect("%sPlate" % patch_name, center, Vector2(size.x + 8.0, 246), wall_plate, 32)
		_add_rect("%sMetalRim" % patch_name, center + Vector2(rim_offset, 0), Vector2(14, 208), rim, 33)
		_add_rect("%sBrokenPanelTop" % patch_name, center + Vector2(rim_offset * 0.35, -78), Vector2(24, 68), broken, 34)
		_add_rect("%sBrokenPanelBottom" % patch_name, center + Vector2(-rim_offset * 0.22, 84), Vector2(22, 78), broken, 34)
		_add_line(
			"%sCrack" % patch_name,
			PackedVector2Array([
				center + Vector2(-8, -104),
				center + Vector2(8, -44),
				center + Vector2(-6, 22),
				center + Vector2(10, 92),
			]),
			crack,
			2.4,
			35
		)
		_add_line(
			"%sDeadCable" % patch_name,
			PackedVector2Array([
				center + Vector2(rim_offset * 0.55, -110),
				center + Vector2(rim_offset * 0.42, -38),
				center + Vector2(rim_offset * 0.48, 36),
			]),
			data,
			1.6,
			35
		)
		_add_octagon("%sCorruption" % patch_name, center + Vector2(rim_offset * 0.28, 108), Vector2(28, 78), corruption, 35)


func _door_root_path(direction: String) -> PackedVector2Array:
	match direction:
		"up":
			return PackedVector2Array([Vector2(512, 116), Vector2(512, 156), Vector2(536, 198)])
		"down":
			return PackedVector2Array([Vector2(512, 484), Vector2(512, 444), Vector2(488, 398)])
		"left":
			return PackedVector2Array([Vector2(104, 300), Vector2(158, 296), Vector2(216, 320)])
		"right":
			return PackedVector2Array([Vector2(920, 300), Vector2(866, 304), Vector2(808, 280)])
	return PackedVector2Array([Vector2.ZERO, Vector2.ZERO])


func _build_variant_template(colors: Dictionary) -> void:
	match variant:
		"transition":
			_build_entropy_corridor_template(colors)
		"recall":
			_build_relic_recall_template(colors)
		"signal":
			_build_mother_signal_template(colors)
		"antechamber":
			_build_hive_antechamber_template(colors)
		"supply":
			_build_raven_final_supply_template(colors)
		"boss":
			_build_mother_core_boss_template(colors)
		_:
			_build_mother_hive_entrance_template(colors)


func _build_mother_hive_entrance_template(colors: Dictionary) -> void:
	_build_entrance_wall_structure(colors)
	_build_entrance_broken_data_channel(colors)
	_build_entrance_signal_route(colors)
	_build_entrance_source_intrusion(colors)
	_build_entrance_corner_details(colors)


func _build_entrance_wall_structure(colors: Dictionary) -> void:
	var outer_wall: Color = Color(0.026, 0.034, 0.046, 0.96)
	var wall_plate: Color = Color(0.07, 0.082, 0.102, 0.68)
	var broken_rim: Color = Color(0.13, 0.14, 0.158, 0.62)
	var rim_shadow: Color = Color(0.026, 0.03, 0.04, 0.72)
	var corruption: Color = colors.get("source_patch", Color(0.14, 0.03, 0.2, 0.34)) as Color
	var weak_light: Color = colors.get("door_light", Color(0.18, 0.55, 0.82, 0.24)) as Color

	_add_rect("MotherHiveEntranceTopFacilityWallOverride", Vector2(512, 86), Vector2(770, 64), outer_wall, 15)
	_add_rect("MotherHiveEntranceBottomFacilityWallOverride", Vector2(512, 514), Vector2(770, 64), outer_wall, 15)
	_add_rect("MotherHiveEntranceLeftFacilityWallOverride", Vector2(76, 300), Vector2(46, 330), outer_wall, 15)
	_add_rect("MotherHiveEntranceRightFacilityWallOverride", Vector2(948, 300), Vector2(46, 330), outer_wall, 15)

	_add_rect("MotherHiveEntranceTopBrokenMetalRim", Vector2(512, 124), Vector2(730, 18), broken_rim, 16)
	_add_rect("MotherHiveEntranceBottomBrokenMetalRim", Vector2(512, 476), Vector2(730, 18), broken_rim, 16)
	_add_rect("MotherHiveEntranceLeftBrokenMetalRim", Vector2(112, 300), Vector2(18, 296), broken_rim, 16)
	_add_rect("MotherHiveEntranceRightBrokenMetalRim", Vector2(912, 300), Vector2(18, 296), broken_rim, 16)

	if not _is_visual_door_hidden("up"):
		_add_rect("MotherHiveEntranceTopDoorThresholdMask", Vector2(512, 128), Vector2(330, 26), rim_shadow, 17)
		_add_rect("MotherHiveEntranceTopDoorDamagedLip", Vector2(512, 140), Vector2(236, 8), wall_plate, 18)
		_add_rect("MotherHiveEntranceTopDeadAccessLight", Vector2(512, 146), Vector2(104, 3), weak_light, 19)
		_add_octagon("MotherHiveEntranceTopDoorCorruptionLeft", Vector2(392, 138), Vector2(78, 32), corruption, 18)
	if not _is_visual_door_hidden("down"):
		_add_rect("MotherHiveEntranceBottomDoorThresholdMask", Vector2(512, 472), Vector2(330, 26), rim_shadow, 17)
		_add_rect("MotherHiveEntranceBottomDoorDamagedLip", Vector2(512, 460), Vector2(236, 8), wall_plate, 18)
		_add_rect("MotherHiveEntranceBottomDeadAccessLight", Vector2(512, 454), Vector2(104, 3), weak_light, 19)
		_add_octagon("MotherHiveEntranceBottomDoorCorruptionRight", Vector2(632, 462), Vector2(84, 34), corruption, 18)


func _build_entrance_broken_data_channel(colors: Dictionary) -> void:
	var deck_plate: Color = Color(0.112, 0.124, 0.142, 0.56)
	var deck_plate_dark: Color = Color(0.064, 0.078, 0.098, 0.48)
	var damaged_edge: Color = Color(0.026, 0.036, 0.052, 0.48)
	var seam: Color = colors.get("floor_seam", Color(0.19, 0.215, 0.245, 0.28)) as Color

	var plate_positions: Array[Vector2] = [
		Vector2(512, 168),
		Vector2(512, 236),
		Vector2(512, 304),
		Vector2(512, 372),
		Vector2(512, 440),
	]
	for index in range(plate_positions.size()):
		var plate_color: Color = deck_plate if index % 2 == 0 else deck_plate_dark
		var plate_size: Vector2 = Vector2(138, 54)
		if index == 0 or index == plate_positions.size() - 1:
			plate_size = Vector2(126, 48)
		_add_rect("MotherHiveEntranceBrokenChannelPlate", plate_positions[index], plate_size, plate_color, 10)
		_add_line(
			"MotherHiveEntranceChannelPlateCrack",
			PackedVector2Array([
				plate_positions[index] + Vector2(-44, -12),
				plate_positions[index] + Vector2(-10, 4),
				plate_positions[index] + Vector2(28, -6),
			]),
			Color(0.018, 0.026, 0.036, 0.42),
			2.2,
			11
		)

	_add_rect("MotherHiveEntranceChannelLeftBrokenEdge", Vector2(432, 304), Vector2(10, 302), damaged_edge, 11)
	_add_rect("MotherHiveEntranceChannelRightBrokenEdge", Vector2(592, 296), Vector2(10, 294), damaged_edge, 11)
	_add_line("MotherHiveEntranceChannelLeftSeam", PackedVector2Array([Vector2(434, 146), Vector2(426, 236), Vector2(438, 328), Vector2(430, 456)]), seam, 1.4, 12)
	_add_line("MotherHiveEntranceChannelRightSeam", PackedVector2Array([Vector2(590, 144), Vector2(598, 228), Vector2(586, 322), Vector2(594, 456)]), seam, 1.4, 12)


func _build_entrance_signal_route(colors: Dictionary) -> void:
	var data: Color = colors.get("data_line", Color(0.2, 0.56, 0.82, 0.32)) as Color
	var dead_data: Color = colors.get("dead_data_line", Color(0.1, 0.24, 0.34, 0.24)) as Color
	_add_line(
		"MotherHiveEntranceSignalPullMain",
		PackedVector2Array([Vector2(512, 132), Vector2(512, 194), Vector2(512, 258), Vector2(512, 338), Vector2(512, 468)]),
		data,
		2.4,
		13
	)
	_add_line(
		"MotherHiveEntranceSignalPullBreakA",
		PackedVector2Array([Vector2(512, 214), Vector2(496, 238), Vector2(512, 260)]),
		dead_data,
		1.4,
		13
	)
	_add_line(
		"MotherHiveEntranceLeftWallDataFeed",
		PackedVector2Array([Vector2(154, 176), Vector2(246, 190), Vector2(340, 212), Vector2(430, 244)]),
		dead_data,
		1.8,
		13
	)
	_add_line(
		"MotherHiveEntranceRightWallDataFeed",
		PackedVector2Array([Vector2(874, 424), Vector2(766, 404), Vector2(662, 382), Vector2(590, 354)]),
		dead_data,
		1.8,
		13
	)


func _build_entrance_source_intrusion(colors: Dictionary) -> void:
	var source: Color = colors.get("source_line", Color(0.38, 0.08, 0.52, 0.26)) as Color
	var source_glow: Color = colors.get("source_glow", Color(0.28, 0.05, 0.38, 0.2)) as Color
	var source_patch: Color = colors.get("source_patch", Color(0.14, 0.03, 0.2, 0.3)) as Color

	var veins: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(124, 138), Vector2(178, 164), Vector2(246, 202), Vector2(334, 248), Vector2(430, 266)]),
		PackedVector2Array([Vector2(900, 142), Vector2(828, 176), Vector2(762, 218), Vector2(666, 252), Vector2(592, 274)]),
		PackedVector2Array([Vector2(124, 456), Vector2(204, 424), Vector2(300, 388), Vector2(430, 354)]),
		PackedVector2Array([Vector2(900, 462), Vector2(820, 428), Vector2(724, 392), Vector2(594, 346)]),
	]
	for vein in veins:
		_add_line("MotherHiveEntranceSourceGrowthGlow", vein, source_glow, 5.2, 12)
		_add_line("MotherHiveEntranceSourceGrowth", vein, source, 2.0, 14)

	_add_octagon("MotherHiveEntranceSourcePatchTopLeft", Vector2(138, 142), Vector2(96, 42), source_patch, 12)
	_add_octagon("MotherHiveEntranceSourcePatchBottomRight", Vector2(888, 456), Vector2(112, 46), source_patch, 12)


func _build_entrance_corner_details(colors: Dictionary) -> void:
	var wall_plate: Color = Color(0.076, 0.086, 0.104, 0.68)
	var data: Color = colors.get("wall_data", Color(0.14, 0.42, 0.62, 0.24)) as Color
	var source: Color = colors.get("wall_source_line", Color(0.38, 0.08, 0.52, 0.28)) as Color
	var red: Color = colors.get("pulse_red", Color(0.62, 0.055, 0.055, 0.22)) as Color

	_add_octagon("MotherHiveEntranceCornerTopLeftRootMass", Vector2(106, 122), Vector2(108, 74), Color(0.15, 0.03, 0.2, 0.42), 15)
	_add_line("MotherHiveEntranceCornerTopLeftBrokenCable", PackedVector2Array([Vector2(118, 116), Vector2(164, 138), Vector2(210, 132)]), data, 2.2, 16)

	_add_line("MotherHiveEntranceCornerTopRightCrack", PackedVector2Array([Vector2(908, 102), Vector2(858, 130), Vector2(806, 124), Vector2(760, 148)]), Color(0.018, 0.022, 0.032, 0.48), 3.0, 16)
	_add_line("MotherHiveEntranceCornerTopRightDeadLight", PackedVector2Array([Vector2(742, 118), Vector2(834, 118)]), data, 2.2, 16)
	_add_line("MotherHiveEntranceCornerTopRightCreep", PackedVector2Array([Vector2(902, 138), Vector2(846, 162), Vector2(792, 190)]), source, 2.0, 16)

	_add_rect("MotherHiveEntranceCornerBottomLeftBrokenPanel", Vector2(142, 472), Vector2(128, 42), wall_plate, 15)
	_add_line("MotherHiveEntranceCornerBottomLeftCreep", PackedVector2Array([Vector2(122, 460), Vector2(190, 432), Vector2(276, 402), Vector2(358, 376)]), source, 2.0, 16)

	_add_octagon("MotherHiveEntranceCornerBottomRightSourceMass", Vector2(900, 470), Vector2(118, 54), Color(0.17, 0.034, 0.23, 0.46), 15)
	_add_line("MotherHiveEntranceCornerBottomRightCreep", PackedVector2Array([Vector2(900, 460), Vector2(820, 432), Vector2(742, 402)]), source, 2.0, 16)
	_add_rect("MotherHiveEntranceCornerBottomRightPulse", Vector2(872, 456), Vector2(7, 7), red, 17)


func _build_entropy_corridor_template(colors: Dictionary) -> void:
	var source: Color = colors.get("source_line", Color(0.45, 0.09, 0.62, 0.42)) as Color
	var data: Color = colors.get("data_line", Color(0.18, 0.5, 0.76, 0.26)) as Color
	_add_diamond("EntropyCorridorSkewedZoneA", Vector2(338, 268), Vector2(310, 150), Color(0.042, 0.038, 0.062, 0.38), 10)
	_add_diamond("EntropyCorridorSkewedZoneB", Vector2(686, 344), Vector2(330, 160), Color(0.035, 0.032, 0.054, 0.42), 10)
	_add_line("EntropyCorridorBrokenCable", PackedVector2Array([Vector2(156, 180), Vector2(282, 218), Vector2(404, 206), Vector2(474, 286), Vector2(642, 282), Vector2(836, 374)]), data, 2.1, 12)
	_add_line("EntropyCorridorSourceTear", PackedVector2Array([Vector2(238, 148), Vector2(318, 238), Vector2(440, 284), Vector2(562, 350), Vector2(742, 448)]), source, 3.4, 13)
	_add_line("EntropyCorridorSecondaryTear", PackedVector2Array([Vector2(790, 154), Vector2(712, 230), Vector2(726, 306), Vector2(650, 396)]), source, 2.2, 13)


func _build_relic_recall_template(colors: Dictionary) -> void:
	var source: Color = colors.get("source_line", Color(0.52, 0.1, 0.7, 0.46)) as Color
	var red: Color = colors.get("pulse_red", Color(0.66, 0.055, 0.055, 0.3)) as Color
	_add_ring("RelicRecallProtocolOuter", ROOM_CENTER, 150.0, Color(0.46, 0.12, 0.66, 0.32), 3.0, 12)
	_add_ring("RelicRecallProtocolInner", ROOM_CENTER, 88.0, Color(0.68, 0.08, 0.12, 0.18), 2.0, 12)
	var nodes: Array[Vector2] = [Vector2(384, 222), Vector2(640, 222), Vector2(512, 392)]
	for node_position in nodes:
		_add_octagon("RelicRecallNodePadFloor", node_position, Vector2(82, 82), Color(0.13, 0.04, 0.18, 0.5), 10)
		_add_ring("RelicRecallNodePadRing", node_position, 42.0, source, 2.0, 13)
		_add_line("RelicRecallProtocolConnector", PackedVector2Array([node_position, ROOM_CENTER]), source, 2.2, 11)
	_add_rect("RelicRecallCenterPulse", ROOM_CENTER, Vector2(30, 30), red, 14)


func _build_mother_signal_template(colors: Dictionary) -> void:
	var data: Color = colors.get("data_line", Color(0.22, 0.62, 0.88, 0.34)) as Color
	var source: Color = colors.get("source_line", Color(0.42, 0.1, 0.62, 0.3)) as Color
	_add_octagon("MotherSignalReceiverFloor", Vector2(512, 276), Vector2(286, 158), Color(0.028, 0.045, 0.074, 0.48), 10)
	_add_rect("MotherSignalArchivePlatformGround", Vector2(512, 410), Vector2(280, 78), Color(0.034, 0.027, 0.055, 0.48), 11)
	_add_ring("MotherSignalPlatformRecallTrace", Vector2(512, 410), 76.0, Color(0.46, 0.1, 0.64, 0.24), 2.2, 12)
	for start_position in [Vector2(142, 142), Vector2(882, 142), Vector2(142, 456), Vector2(882, 456)]:
		_add_line("MotherSignalWallFeed", PackedVector2Array([start_position, Vector2(512, 276), Vector2(512, 410)]), data, 1.8, 12)
	_add_line("MotherSignalSourceNeuralTrace", PackedVector2Array([Vector2(250, 202), Vector2(346, 238), Vector2(430, 226), Vector2(512, 276), Vector2(626, 252), Vector2(760, 302)]), source, 2.2, 13)


func _build_hive_antechamber_template(colors: Dictionary) -> void:
	var source: Color = colors.get("source_line", Color(0.54, 0.1, 0.7, 0.5)) as Color
	_add_diamond("HiveAntechamberPressureFloor", ROOM_CENTER, Vector2(390, 240), Color(0.085, 0.024, 0.105, 0.46), 10)
	_add_rect("HiveAntechamberCombatRoute", ROOM_CENTER, Vector2(190, 336), Color(0.075, 0.078, 0.094, 0.42), 11)
	_add_line("HiveAntechamberMainDataRoute", PackedVector2Array([Vector2(512, 126), Vector2(506, 222), Vector2(558, 296), Vector2(506, 380), Vector2(512, 474)]), Color(0.2, 0.46, 0.68, 0.18), 2.4, 12)
	for root in [
		PackedVector2Array([Vector2(116, 286), Vector2(220, 278), Vector2(332, 312), Vector2(444, 288)]),
		PackedVector2Array([Vector2(908, 326), Vector2(800, 340), Vector2(690, 318), Vector2(578, 354)]),
		PackedVector2Array([Vector2(210, 456), Vector2(326, 408), Vector2(468, 394)]),
	]:
		_add_line("HiveAntechamberLivingRootFloor", root, source, 4.6, 13)


func _build_raven_final_supply_template(colors: Dictionary) -> void:
	var safe_color: Color = Color(0.044, 0.052, 0.062, 0.58)
	var data: Color = colors.get("data_line", Color(0.2, 0.54, 0.8, 0.28)) as Color
	_add_rect("RavenFinalSupplySafeFloor", Vector2(512, 310), Vector2(392, 186), safe_color, 10)
	_add_rect("RavenFinalSupplyMerchantPad", Vector2(608, 300), Vector2(142, 86), Color(0.052, 0.062, 0.08, 0.46), 11)
	_add_rect("RavenFinalSupplyTerminalPad", Vector2(416, 336), Vector2(142, 82), Color(0.04, 0.052, 0.072, 0.42), 11)
	_add_line("RavenFinalSupplyWeakGuideLine", PackedVector2Array([Vector2(512, 474), Vector2(512, 390), Vector2(416, 336), Vector2(608, 300)]), data, 1.9, 12)
	_add_line("RavenFinalSupplyContainedRoot", PackedVector2Array([Vector2(828, 448), Vector2(770, 410), Vector2(706, 386)]), colors.get("source_line", Color(0.38, 0.09, 0.54, 0.2)) as Color, 2.4, 12)


func _build_mother_core_boss_template(colors: Dictionary) -> void:
	var source: Color = colors.get("source_line", Color(0.58, 0.1, 0.74, 0.52)) as Color
	var red: Color = colors.get("pulse_red", Color(0.72, 0.06, 0.06, 0.34)) as Color
	_add_octagon("MotherCoreOuterPlayableRing", ROOM_CENTER, Vector2(500, 330), Color(0.064, 0.058, 0.08, 0.5), 10)
	_add_octagon("MotherCoreInnerHiveFloor", ROOM_CENTER, Vector2(286, 210), Color(0.12, 0.026, 0.14, 0.58), 11)
	_add_ring("MotherCoreProtocolOuterRing", ROOM_CENTER, 182.0, source, 3.0, 12)
	_add_ring("MotherCoreProtocolMiddleRing", ROOM_CENTER, 124.0, Color(0.66, 0.08, 0.13, 0.24), 2.4, 12)
	_add_ring("MotherCoreProtocolInnerRing", ROOM_CENTER, 58.0, Color(0.24, 0.36, 0.8, 0.2), 2.0, 12)
	for start_position in [Vector2(512, 126), Vector2(512, 474), Vector2(118, 300), Vector2(906, 300), Vector2(210, 150), Vector2(814, 450)]:
		_add_line("MotherCoreRadialSourceLine", PackedVector2Array([start_position, ROOM_CENTER]), source, 2.8, 13)
	_add_rect("MotherCoreLowPulse", ROOM_CENTER, Vector2(40, 40), red, 14)


func _build_subtle_pulses(colors: Dictionary) -> void:
	var red: Color = colors.get("pulse_red", Color(0.65, 0.055, 0.055, 0.24)) as Color
	var positions: Array[Vector2] = _pulse_positions()
	for pulse_position in positions:
		_add_rect("FinalHiveSubtlePulseDot", pulse_position, Vector2(8, 8), red, 40)


func _data_paths_for_variant() -> Array[PackedVector2Array]:
	match variant:
		"entrance":
			return [
				PackedVector2Array([Vector2(512, 130), Vector2(512, 208), Vector2(512, 304), Vector2(512, 470)]),
				PackedVector2Array([Vector2(156, 174), Vector2(272, 198), Vector2(420, 242)]),
				PackedVector2Array([Vector2(868, 424), Vector2(752, 398), Vector2(592, 354)]),
			]
		"transition":
			return [
				PackedVector2Array([Vector2(160, 182), Vector2(282, 216), Vector2(402, 208), Vector2(476, 286), Vector2(642, 282)]),
				PackedVector2Array([Vector2(832, 438), Vector2(704, 392), Vector2(596, 400)]),
			]
		"recall":
			return [
				PackedVector2Array([Vector2(512, 130), Vector2(512, 210), ROOM_CENTER]),
				PackedVector2Array([Vector2(118, 300), Vector2(260, 300), ROOM_CENTER, Vector2(764, 300), Vector2(906, 300)]),
			]
		"signal":
			return [
				PackedVector2Array([Vector2(512, 130), Vector2(512, 250), Vector2(512, 410)]),
				PackedVector2Array([Vector2(136, 440), Vector2(286, 410), Vector2(512, 410), Vector2(742, 410), Vector2(888, 440)]),
			]
		"antechamber":
			return [
				PackedVector2Array([Vector2(512, 130), Vector2(512, 224), Vector2(558, 300), Vector2(512, 470)]),
			]
		"supply":
			return [
				PackedVector2Array([Vector2(512, 470), Vector2(512, 390), Vector2(416, 336), Vector2(608, 300)]),
				PackedVector2Array([Vector2(180, 156), Vector2(310, 166), Vector2(432, 210)]),
			]
		"boss":
			return [
				PackedVector2Array([Vector2(512, 126), ROOM_CENTER, Vector2(512, 474)]),
				PackedVector2Array([Vector2(118, 300), ROOM_CENTER, Vector2(906, 300)]),
			]
	return []


func _source_patches_for_variant() -> Array[Dictionary]:
	match variant:
		"entrance":
			return [
				{"p": Vector2(132, 144), "s": Vector2(98, 42)},
				{"p": Vector2(892, 150), "s": Vector2(104, 44)},
				{"p": Vector2(132, 454), "s": Vector2(112, 48)},
				{"p": Vector2(890, 458), "s": Vector2(116, 50)},
			]
		"supply":
			return [
				{"p": Vector2(864, 438), "s": Vector2(124, 58)},
				{"p": Vector2(140, 152), "s": Vector2(98, 48)},
				{"p": Vector2(908, 150), "s": Vector2(92, 42)},
			]
		"transition":
			return [
				{"p": Vector2(130, 152), "s": Vector2(126, 62)},
				{"p": Vector2(886, 454), "s": Vector2(142, 72)},
				{"p": Vector2(514, 452), "s": Vector2(166, 52)},
				{"p": Vector2(890, 150), "s": Vector2(114, 54)},
			]
		"recall":
			return [
				{"p": Vector2(384, 222), "s": Vector2(116, 92)},
				{"p": Vector2(640, 222), "s": Vector2(116, 92)},
				{"p": Vector2(512, 392), "s": Vector2(126, 96)},
				{"p": ROOM_CENTER, "s": Vector2(210, 150)},
			]
		"signal":
			return [
				{"p": Vector2(512, 410), "s": Vector2(210, 90)},
				{"p": Vector2(130, 152), "s": Vector2(108, 52)},
				{"p": Vector2(892, 446), "s": Vector2(120, 58)},
			]
		"antechamber":
			return [
				{"p": Vector2(130, 150), "s": Vector2(138, 70)},
				{"p": Vector2(894, 150), "s": Vector2(144, 72)},
				{"p": Vector2(132, 450), "s": Vector2(150, 76)},
				{"p": Vector2(890, 450), "s": Vector2(150, 76)},
				{"p": ROOM_CENTER, "s": Vector2(330, 210)},
			]
		"boss":
			return [
				{"p": ROOM_CENTER, "s": Vector2(390, 270)},
				{"p": Vector2(132, 150), "s": Vector2(160, 82)},
				{"p": Vector2(890, 150), "s": Vector2(160, 82)},
				{"p": Vector2(132, 450), "s": Vector2(160, 82)},
				{"p": Vector2(890, 450), "s": Vector2(160, 82)},
				{"p": Vector2(512, 128), "s": Vector2(180, 54)},
			]
	return []


func _source_veins_for_variant() -> Array[PackedVector2Array]:
	match variant:
		"entrance":
			return [
				PackedVector2Array([Vector2(128, 144), Vector2(196, 174), Vector2(286, 218), Vector2(430, 266)]),
				PackedVector2Array([Vector2(890, 150), Vector2(820, 184), Vector2(728, 236), Vector2(592, 274)]),
				PackedVector2Array([Vector2(130, 454), Vector2(216, 420), Vector2(320, 384), Vector2(430, 354)]),
			]
		"supply":
			return [
				PackedVector2Array([Vector2(862, 440), Vector2(780, 406), Vector2(708, 386)]),
				PackedVector2Array([Vector2(140, 152), Vector2(196, 178), Vector2(250, 194)]),
			]
		"transition":
			return [
				PackedVector2Array([Vector2(130, 152), Vector2(218, 208), Vector2(326, 246), Vector2(438, 286)]),
				PackedVector2Array([Vector2(890, 454), Vector2(780, 410), Vector2(688, 352), Vector2(590, 334)]),
				PackedVector2Array([Vector2(512, 450), Vector2(482, 398), Vector2(520, 330)]),
			]
		"recall":
			return [
				PackedVector2Array([Vector2(384, 222), ROOM_CENTER]),
				PackedVector2Array([Vector2(640, 222), ROOM_CENTER]),
				PackedVector2Array([Vector2(512, 392), ROOM_CENTER]),
				PackedVector2Array([Vector2(130, 152), Vector2(230, 206), Vector2(334, 244)]),
			]
		"signal":
			return [
				PackedVector2Array([Vector2(138, 152), Vector2(258, 210), Vector2(386, 286), Vector2(512, 410)]),
				PackedVector2Array([Vector2(886, 448), Vector2(760, 402), Vector2(628, 362), Vector2(512, 410)]),
			]
		"antechamber":
			return [
				PackedVector2Array([Vector2(128, 152), Vector2(220, 218), Vector2(326, 284), Vector2(444, 310)]),
				PackedVector2Array([Vector2(896, 150), Vector2(802, 214), Vector2(696, 276), Vector2(580, 306)]),
				PackedVector2Array([Vector2(128, 450), Vector2(250, 420), Vector2(384, 370)]),
				PackedVector2Array([Vector2(892, 450), Vector2(772, 414), Vector2(640, 366)]),
			]
		"boss":
			return [
				PackedVector2Array([Vector2(128, 150), Vector2(256, 220), ROOM_CENTER]),
				PackedVector2Array([Vector2(892, 150), Vector2(768, 220), ROOM_CENTER]),
				PackedVector2Array([Vector2(128, 450), Vector2(256, 380), ROOM_CENTER]),
				PackedVector2Array([Vector2(892, 450), Vector2(768, 380), ROOM_CENTER]),
				PackedVector2Array([Vector2(512, 126), ROOM_CENTER]),
				PackedVector2Array([Vector2(512, 474), ROOM_CENTER]),
			]
	return []


func _floor_pulse_points_for_variant() -> Array[Vector2]:
	match variant:
		"recall":
			return [ROOM_CENTER, Vector2(384, 222), Vector2(640, 222), Vector2(512, 392)]
		"signal":
			return [Vector2(512, 410), Vector2(512, 276)]
		"antechamber":
			return [Vector2(220, 218), Vector2(802, 214), Vector2(640, 366)]
		"boss":
			return [ROOM_CENTER, Vector2(256, 220), Vector2(768, 220), Vector2(256, 380), Vector2(768, 380), Vector2(512, 126), Vector2(512, 474)]
	return []


func _pulse_positions() -> Array[Vector2]:
	match variant:
		"boss":
			return [Vector2(150, 132), Vector2(874, 132), Vector2(150, 468), Vector2(874, 468), ROOM_CENTER]
		"recall":
			return [ROOM_CENTER, Vector2(384, 222), Vector2(640, 222), Vector2(512, 392)]
		"transition", "antechamber":
			return [Vector2(210, 178), Vector2(804, 420)]
	return []


func _wall_grade() -> String:
	match variant:
		"entrance", "supply":
			return "damaged"
		"transition", "recall", "signal":
			return "corrupted"
		"antechamber":
			return "living"
		"boss":
			return "core"
	return "damaged"


func _infection_level() -> int:
	match variant:
		"entrance":
			return 1
		"supply":
			return 1
		"transition":
			return 2
		"recall", "signal":
			return 3
		"antechamber":
			return 4
		"boss":
			return 5
	return 1


func _damage_level() -> int:
	match variant:
		"entrance":
			return 2
		"supply":
			return 2
		"signal", "recall":
			return 3
		"transition", "antechamber":
			return 4
		"boss":
			return 5
	return 2


func _source_level() -> int:
	match variant:
		"entrance":
			return 1
		"supply":
			return 2
		"transition", "signal":
			return 3
		"recall":
			return 4
		"antechamber":
			return 5
		"boss":
			return 6
	return 1


func _variant_seed() -> int:
	match variant:
		"entrance":
			return 1
		"transition":
			return 2
		"recall":
			return 3
		"signal":
			return 4
		"antechamber":
			return 5
		"supply":
			return 6
		"boss":
			return 7
	return 0


func _palette() -> Dictionary:
	var colors: Dictionary = {
		"floor_base": Color(0.096, 0.106, 0.122, 0.98),
		"floor_panel_a": Color(0.13, 0.142, 0.16, 0.74),
		"floor_panel_b": Color(0.072, 0.082, 0.098, 0.64),
		"floor_panel_c": Color(0.105, 0.114, 0.134, 0.58),
		"floor_seam": Color(0.19, 0.215, 0.245, 0.34),
		"facility_spine": Color(0.04, 0.058, 0.078, 0.46),
		"surviving_deck": Color(0.05, 0.064, 0.086, 0.46),
		"data_line": Color(0.18, 0.5, 0.76, 0.3),
		"dead_data_line": Color(0.1, 0.24, 0.34, 0.24),
		"repair_plate": Color(0.13, 0.136, 0.15, 0.38),
		"metal_crack": Color(0.02, 0.025, 0.034, 0.44),
		"source_patch": Color(0.17, 0.036, 0.23, 0.44),
		"source_line": Color(0.42, 0.09, 0.57, 0.42),
		"source_glow": Color(0.28, 0.05, 0.38, 0.28),
		"pulse_red": Color(0.62, 0.055, 0.055, 0.28),
		"transition_metal": Color(0.09, 0.096, 0.112, 0.72),
		"transition_corrupted": Color(0.22, 0.04, 0.31, 0.44),
		"transition_living": Color(0.12, 0.028, 0.15, 0.56),
		"inner_metal_rim": Color(0.15, 0.16, 0.178, 0.52),
		"wall_outer": Color(0.025, 0.03, 0.04, 0.98),
		"wall_shadow": Color(0.006, 0.008, 0.012, 0.88),
		"wall_rim": Color(0.105, 0.112, 0.128, 0.88),
		"wall_rim_broken": Color(0.046, 0.052, 0.064, 0.72),
		"wall_corruption_band": Color(0.18, 0.035, 0.24, 0.42),
		"wall_corruption_heavy": Color(0.24, 0.045, 0.31, 0.54),
		"living_band": Color(0.16, 0.025, 0.18, 0.58),
		"corner_corruption": Color(0.22, 0.04, 0.29, 0.56),
		"corner_metal": Color(0.055, 0.062, 0.076, 0.84),
		"wall_crack": Color(0.34, 0.32, 0.44, 0.24),
		"wall_data": Color(0.14, 0.42, 0.62, 0.24),
		"wall_source_line": Color(0.38, 0.08, 0.52, 0.36),
		"door_dark": Color(0.012, 0.014, 0.02, 0.92),
		"door_metal": Color(0.075, 0.082, 0.096, 0.86),
		"door_corrupt": Color(0.23, 0.045, 0.32, 0.46),
		"door_light": Color(0.18, 0.55, 0.82, 0.32),
		"functional_pad": Color(0.035, 0.058, 0.08, 0.54),
	}

	match variant:
		"entrance":
			colors["floor_base"] = Color(0.112, 0.124, 0.14, 0.98)
			colors["floor_panel_a"] = Color(0.15, 0.164, 0.184, 0.68)
			colors["source_patch"] = Color(0.14, 0.03, 0.2, 0.34)
			colors["source_line"] = Color(0.34, 0.075, 0.48, 0.3)
			colors["wall_outer"] = Color(0.032, 0.04, 0.052, 0.98)
		"transition":
			colors["floor_base"] = Color(0.088, 0.094, 0.112, 0.98)
			colors["source_patch"] = Color(0.2, 0.04, 0.29, 0.5)
			colors["source_line"] = Color(0.48, 0.1, 0.66, 0.46)
			colors["wall_outer"] = Color(0.025, 0.03, 0.044, 0.98)
		"recall":
			colors["floor_base"] = Color(0.082, 0.084, 0.1, 0.98)
			colors["floor_panel_a"] = Color(0.12, 0.105, 0.135, 0.62)
			colors["source_patch"] = Color(0.22, 0.045, 0.32, 0.56)
			colors["source_line"] = Color(0.54, 0.11, 0.72, 0.5)
			colors["pulse_red"] = Color(0.72, 0.06, 0.06, 0.32)
		"signal":
			colors["floor_base"] = Color(0.092, 0.1, 0.12, 0.98)
			colors["data_line"] = Color(0.24, 0.6, 0.88, 0.36)
			colors["source_patch"] = Color(0.17, 0.035, 0.26, 0.42)
			colors["source_line"] = Color(0.42, 0.1, 0.62, 0.34)
			colors["door_light"] = Color(0.24, 0.64, 0.92, 0.32)
		"antechamber":
			colors["floor_base"] = Color(0.078, 0.076, 0.092, 0.98)
			colors["floor_panel_a"] = Color(0.106, 0.08, 0.124, 0.58)
			colors["source_patch"] = Color(0.25, 0.045, 0.34, 0.58)
			colors["source_line"] = Color(0.56, 0.11, 0.72, 0.54)
			colors["wall_outer"] = Color(0.022, 0.018, 0.03, 0.98)
		"supply":
			colors["floor_base"] = Color(0.108, 0.118, 0.134, 0.97)
			colors["floor_panel_a"] = Color(0.148, 0.164, 0.18, 0.58)
			colors["source_patch"] = Color(0.14, 0.03, 0.2, 0.34)
			colors["source_line"] = Color(0.36, 0.08, 0.5, 0.26)
			colors["data_line"] = Color(0.22, 0.56, 0.82, 0.32)
		"boss":
			colors["floor_base"] = Color(0.07, 0.064, 0.086, 0.98)
			colors["floor_panel_a"] = Color(0.098, 0.072, 0.122, 0.62)
			colors["source_patch"] = Color(0.28, 0.045, 0.38, 0.62)
			colors["source_line"] = Color(0.62, 0.12, 0.78, 0.56)
			colors["pulse_red"] = Color(0.76, 0.06, 0.06, 0.36)
			colors["door_light"] = Color(0.68, 0.08, 0.1, 0.3)
			colors["wall_outer"] = Color(0.018, 0.012, 0.026, 0.98)

	return colors


func _add_rect(name_value: String, center: Vector2, size: Vector2, color: Color, _z_value: int) -> Polygon2D:
	var half: Vector2 = size * 0.5
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = name_value
	polygon.z_as_relative = false
	polygon.z_index = BACKGROUND_VISUAL_Z
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(polygon)
	return polygon


func _add_diamond(name_value: String, center: Vector2, size: Vector2, color: Color, _z_value: int) -> Polygon2D:
	var half: Vector2 = size * 0.5
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = name_value
	polygon.z_as_relative = false
	polygon.z_index = BACKGROUND_VISUAL_Z
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		center + Vector2(0, -half.y),
		center + Vector2(half.x, 0),
		center + Vector2(0, half.y),
		center + Vector2(-half.x, 0),
	])
	add_child(polygon)
	return polygon


func _add_octagon(name_value: String, center: Vector2, size: Vector2, color: Color, _z_value: int) -> Polygon2D:
	var half: Vector2 = size * 0.5
	var cut: Vector2 = Vector2(size.x * 0.18, size.y * 0.18)
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = name_value
	polygon.z_as_relative = false
	polygon.z_index = BACKGROUND_VISUAL_Z
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


func _add_line(name_value: String, points: PackedVector2Array, color: Color, width: float, _z_value: int) -> Line2D:
	var line: Line2D = Line2D.new()
	line.name = name_value
	line.z_as_relative = false
	line.z_index = BACKGROUND_VISUAL_Z
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
	var segment_count: int = 56
	for index in range(segment_count + 1):
		var angle: float = TAU * float(index) / float(segment_count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return _add_line(name_value, points, color, width, z_value)
