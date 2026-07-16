class_name ExosuitFactoryOverlay
extends Node2D


const FACILITY_CRATES_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/crates_spritesheet.png")
const FACILITY_DOODADS_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/doodads_spritesheet.png")
const FACILITY_COMPUTER_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/computer_spritesheet.png")
const LAB_STUFF_TEXTURE = preload("res://tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png")
const ROBOT_FACTORY_PAGE_01 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png")
const ROBOT_FACTORY_PAGE_02 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_02.png")
const ROBOT_FACTORY_PAGE_03 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_03.png")
const ROBOT_FACTORY_PAGE_04 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_04.png")
const ROBOT_FACTORY_PAGE_05 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_05.png")

const ROOM_CENTER := Vector2(512, 300)
const FLOOR_CENTER := Vector2(512, 300)
const FLOOR_SIZE := Vector2(880, 416)
const FLOOR_TOP_LEFT := Vector2(72, 92)
const FLOOR_BOTTOM_RIGHT := Vector2(952, 508)
const BACKGROUND_VISUAL_Z := -2

@export var variant := "combat"


static func chapter_4_factory_background_theme() -> Dictionary:
	return {
		"name": "chapter_4_factory_background_theme",
		"floor_set": [
			"factory_floor_steel_plate",
			"factory_floor_assembly_line",
			"factory_floor_hangar_marking",
			"factory_floor_maintenance",
			"factory_floor_power_control",
			"factory_floor_weapon_test",
			"factory_floor_boss_arena",
		],
		"wall_set": [
			"factory_wall_assembly",
			"factory_wall_hangar",
			"factory_wall_weapon_test",
			"factory_wall_maintenance",
			"factory_wall_power_control",
			"factory_wall_heavy_metal",
			"factory_wall_boss_arena",
		],
		"door_set": [
			"factory_door_assembly",
			"factory_door_hangar",
			"factory_door_weapon_test",
			"factory_door_power",
			"factory_door_boss",
		],
		"corner_set": [
			"industrial_light_corner",
			"vented_corner",
			"rack_corner",
			"heavy_test_corner",
		],
		"border_set": [
			"heavy_metal_border",
			"assembly_rail_border",
			"hangar_bay_border",
			"test_warning_border",
		],
		"decal_set": [
			"oil_scuff",
			"welding_scars",
			"hangar_slot_line",
			"weapon_test_line",
			"power_cable_trench",
			"maintenance_tool_shadow",
		],
		"room_background_variants": [
			"factory_assembly_line_background",
			"factory_exoskeleton_hangar_background",
			"factory_weapon_test_background",
			"factory_weapon_quality_background",
			"factory_maintenance_workshop_background",
			"factory_power_control_background",
			"factory_armory_supply_background",
			"factory_heavy_cleaner_boss_background",
		],
	}


func _ready() -> void:
	z_index = -2
	_hide_inherited_lab_art()
	var background_key: String = _background_key()
	_build_factory_shell(background_key)
	match background_key:
		"assembly":
			_build_factory_assembly_line_background()
		"hangar":
			_build_factory_exoskeleton_hangar_background()
		"weapon_test":
			_build_factory_weapon_test_background(false)
		"weapon_quality":
			_build_factory_weapon_test_background(true)
		"maintenance":
			_build_factory_maintenance_workshop_background()
		"power_control":
			_build_factory_power_control_background()
		"armory_supply":
			_build_factory_armory_supply_background()
		"boss_arena":
			_build_factory_heavy_cleaner_boss_background()
		_:
			_build_factory_assembly_line_background()
	_build_variant_solid_blocking_props(background_key)


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


func _background_key() -> String:
	if variant in ["start", "power_control"]:
		return "power_control"
	if variant in ["combat", "assembly"]:
		return "assembly"
	if variant in ["drone", "maintenance"]:
		return "maintenance"
	if variant in ["test", "weapon_test"]:
		return "weapon_test"
	if variant in ["weapon", "weapon_quality"]:
		return "weapon_quality"
	if variant in ["elite", "hangar"]:
		return "hangar"
	if variant in ["merchant", "armory_supply"]:
		return "armory_supply"
	if variant in ["boss", "boss_arena"]:
		return "boss_arena"
	return "assembly"


func _build_factory_shell(background_key: String) -> void:
	_add_rect("FactoryBaseFloor", FLOOR_CENTER, FLOOR_SIZE, _floor_color(background_key), 0)
	_build_floor_plate_grid(background_key)
	_build_outer_walls(background_key)
	_build_wall_modules(background_key)


func _floor_color(background_key: String) -> Color:
	match background_key:
		"armory_supply":
			return Color(0.074, 0.078, 0.074, 0.94)
		"power_control":
			return Color(0.075, 0.086, 0.092, 0.92)
		"hangar":
			return Color(0.088, 0.086, 0.082, 0.92)
		"weapon_test", "weapon_quality":
			return Color(0.095, 0.086, 0.078, 0.92)
		"boss_arena":
			return Color(0.07, 0.064, 0.061, 0.94)
		"maintenance":
			return Color(0.082, 0.079, 0.073, 0.92)
	return Color(0.084, 0.088, 0.088, 0.92)


func _wall_color(background_key: String) -> Color:
	match background_key:
		"hangar":
			return Color(0.072, 0.074, 0.072, 0.94)
		"weapon_test", "weapon_quality":
			return Color(0.085, 0.07, 0.064, 0.94)
		"power_control":
			return Color(0.065, 0.076, 0.082, 0.94)
		"boss_arena":
			return Color(0.055, 0.052, 0.052, 0.96)
		"armory_supply":
			return Color(0.07, 0.078, 0.08, 0.94)
	return Color(0.065, 0.068, 0.068, 0.94)


func _accent_color(background_key: String) -> Color:
	match background_key:
		"weapon_test", "weapon_quality", "boss_arena":
			return Color(0.95, 0.22, 0.12, 0.52)
		"power_control":
			return Color(0.32, 0.9, 1.0, 0.52)
		"armory_supply":
			return Color(0.32, 0.82, 1.0, 0.46)
		"hangar":
			return Color(0.95, 0.34, 0.18, 0.42)
	return Color(1.0, 0.62, 0.16, 0.42)


func _build_floor_plate_grid(background_key: String) -> void:
	var panel_color_a: Color = Color(0.14, 0.145, 0.145, 0.22)
	var panel_color_b: Color = Color(0.045, 0.048, 0.05, 0.24)
	if background_key in ["weapon_test", "weapon_quality"]:
		panel_color_a = Color(0.16, 0.13, 0.115, 0.22)
		panel_color_b = Color(0.06, 0.048, 0.044, 0.25)
	elif background_key == "hangar":
		panel_color_a = Color(0.145, 0.138, 0.12, 0.22)
		panel_color_b = Color(0.052, 0.05, 0.046, 0.25)
	elif background_key == "boss_arena":
		panel_color_a = Color(0.13, 0.10, 0.09, 0.18)
		panel_color_b = Color(0.045, 0.04, 0.038, 0.27)
	elif background_key == "armory_supply":
		panel_color_a = Color(0.112, 0.12, 0.108, 0.26)
		panel_color_b = Color(0.042, 0.048, 0.044, 0.28)

	for x in range(128, 912, 96):
		for y in range(128, 488, 96):
			var tile_index: int = int(x / 96) + int(y / 96)
			var color: Color = panel_color_a if tile_index % 2 == 0 else panel_color_b
			_add_rect("FactorySteelPlate", Vector2(x + 32, y + 32), Vector2(74, 74), color, 0)
	for x_line in range(128, 912, 64):
		_add_line(Vector2(x_line, 108), Vector2(x_line, 492), Color(0.28, 0.29, 0.28, 0.16), 1.0, 1)
	for y_line in range(128, 488, 64):
		_add_line(Vector2(92, y_line), Vector2(932, y_line), Color(0.28, 0.29, 0.28, 0.16), 1.0, 1)


func _build_outer_walls(background_key: String) -> void:
	var wall: Color = _wall_color(background_key)
	var rim: Color = Color(0.16, 0.17, 0.17, 0.54)
	if background_key == "boss_arena":
		rim = Color(0.24, 0.13, 0.105, 0.48)
	elif background_key == "weapon_test":
		rim = Color(0.24, 0.14, 0.09, 0.46)
	elif background_key == "power_control":
		rim = Color(0.10, 0.22, 0.24, 0.42)

	_add_rect("FactoryOuterWallTop", Vector2(512, 78), Vector2(928, 46), wall, 2)
	_add_rect("FactoryOuterWallBottom", Vector2(512, 522), Vector2(928, 46), wall, 2)
	_add_rect("FactoryOuterWallLeft", Vector2(48, 300), Vector2(50, 444), wall, 2)
	_add_rect("FactoryOuterWallRight", Vector2(976, 300), Vector2(50, 444), wall, 2)
	_add_rect("FactoryInnerMetalRimTop", Vector2(512, 104), Vector2(872, 18), rim, 2)
	_add_rect("FactoryInnerMetalRimBottom", Vector2(512, 496), Vector2(872, 18), rim, 2)
	_add_rect("FactoryInnerMetalRimLeft", Vector2(84, 300), Vector2(18, 392), rim, 2)
	_add_rect("FactoryInnerMetalRimRight", Vector2(940, 300), Vector2(18, 392), rim, 2)

	for corner_index in range(4):
		var corner_position: Vector2 = [
			Vector2(96, 112),
			Vector2(928, 112),
			Vector2(96, 488),
			Vector2(928, 488),
		][corner_index]
		var corner_color: Color = Color(0.23, 0.24, 0.23, 0.32)
		if background_key in ["weapon_test", "weapon_quality", "boss_arena"]:
			corner_color = Color(0.44, 0.16, 0.10, 0.32)
		elif background_key == "hangar":
			corner_color = Color(0.40, 0.24, 0.12, 0.30)
		_add_rect("FactoryCornerReinforcement", corner_position, Vector2(52, 34), corner_color, 3)


func _build_factory_door_frames(background_key: String) -> void:
	var door_color: Color = Color(0.13, 0.14, 0.14, 0.74)
	var light_color: Color = _accent_color(background_key)
	if background_key == "armory_supply":
		light_color = Color(0.22, 0.86, 1.0, 0.54)

	var doors: Array[Dictionary] = [
		{"dir": "up", "frame": Vector2(512, 104), "size": Vector2(186, 34), "a": Vector2(436, 104), "b": Vector2(588, 104)},
		{"dir": "down", "frame": Vector2(512, 496), "size": Vector2(186, 34), "a": Vector2(436, 496), "b": Vector2(588, 496)},
		{"dir": "left", "frame": Vector2(84, 300), "size": Vector2(34, 164), "a": Vector2(84, 238), "b": Vector2(84, 362)},
		{"dir": "right", "frame": Vector2(940, 300), "size": Vector2(34, 164), "a": Vector2(940, 238), "b": Vector2(940, 362)},
	]
	for door_value in doors:
		var door: Dictionary = door_value
		var direction := str(door.get("dir", ""))
		if _is_visual_door_hidden(direction):
			continue
		_add_rect("FactoryDoorFrame", door.get("frame", Vector2.ZERO) as Vector2, door.get("size", Vector2.ZERO) as Vector2, door_color, 5)
		_add_line(door.get("a", Vector2.ZERO) as Vector2, door.get("b", Vector2.ZERO) as Vector2, light_color, 3.0, 6)

	if background_key in ["weapon_test", "weapon_quality", "boss_arena"]:
		if not _is_visual_door_hidden("up"):
			_add_warning_strip(Vector2(512, 124), Vector2(150, 12), false, 0.32)
		if not _is_visual_door_hidden("down"):
			_add_warning_strip(Vector2(512, 476), Vector2(150, 12), false, 0.28)


func _is_visual_door_hidden(direction: String) -> bool:
	var room := get_parent()
	if room == null:
		return false
	match direction:
		"up":
			if room.get("hide_up_door") == true:
				return true
		"down":
			if room.get("hide_down_door") == true:
				return true
		"left":
			if room.get("hide_left_door") == true:
				return true
		"right":
			if room.get("hide_right_door") == true:
				return true
	return false


func _build_wall_modules(background_key: String) -> void:
	var accent: Color = _accent_color(background_key)
	for index in range(4):
		var x_position: float = 222.0 + index * 188.0
		_add_rect("FactoryWallVentTop", Vector2(x_position, 82), Vector2(58, 12), Color(0.30, 0.33, 0.32, 0.28), 6)
		_add_rect("FactoryWallVentBottom", Vector2(x_position + 48.0, 518), Vector2(58, 12), Color(0.30, 0.33, 0.32, 0.24), 6)

	match background_key:
		"assembly":
			_add_line(Vector2(142, 112), Vector2(882, 112), Color(0.86, 0.46, 0.12, 0.22), 5.0, 4)
			_add_line(Vector2(142, 488), Vector2(882, 488), Color(0.86, 0.46, 0.12, 0.18), 4.0, 4)
		"hangar":
			for y in [178, 256, 334, 412]:
				_add_rect("HangarWallDockLeft", Vector2(84, y), Vector2(20, 48), Color(0.52, 0.25, 0.10, 0.28), 6)
				_add_rect("HangarWallDockRight", Vector2(940, y), Vector2(20, 48), Color(0.52, 0.25, 0.10, 0.28), 6)
		"maintenance":
			for y in [180, 244, 372, 436]:
				_add_rect("MaintenanceToolBoard", Vector2(84, y), Vector2(18, 42), Color(0.38, 0.28, 0.14, 0.30), 6)
				_add_rect("MaintenanceCoolantPort", Vector2(940, y + 18), Vector2(18, 42), Color(0.10, 0.30, 0.32, 0.28), 6)
		"power_control":
			for x in [220, 512, 804]:
				_add_line(Vector2(x, 100), Vector2(x, 146), accent, 3.0, 5)
				_add_line(Vector2(x, 454), Vector2(x, 500), accent, 3.0, 5)
		"boss_arena":
			_add_line(Vector2(134, 118), Vector2(890, 118), Color(0.92, 0.20, 0.12, 0.34), 5.0, 5)
			_add_line(Vector2(134, 482), Vector2(890, 482), Color(0.92, 0.20, 0.12, 0.30), 5.0, 5)
			_add_line(Vector2(112, 156), Vector2(112, 444), Color(0.92, 0.20, 0.12, 0.26), 4.0, 5)
			_add_line(Vector2(912, 156), Vector2(912, 444), Color(0.92, 0.20, 0.12, 0.26), 4.0, 5)
		_:
			_add_line(Vector2(160, 112), Vector2(864, 112), accent, 2.0, 4)


func _build_factory_assembly_line_background() -> void:
	_add_rect("AssemblyConveyorBed", ROOM_CENTER, Vector2(552, 72), Color(0.055, 0.058, 0.056, 0.92), 2)
	_add_rect("AssemblyConveyorBelt", ROOM_CENTER, Vector2(528, 40), Color(0.025, 0.03, 0.032, 0.86), 3)
	for x in range(270, 760, 70):
		_add_line(Vector2(x, 280), Vector2(x + 34, 320), Color(0.56, 0.58, 0.55, 0.32), 2.0, 4)
	_add_warning_strip(Vector2(512, 252), Vector2(522, 12), false, 0.34)
	_add_warning_strip(Vector2(512, 348), Vector2(522, 12), false, 0.30)

	_add_rect("AssemblyLeftWorkLane", Vector2(250, 300), Vector2(176, 272), Color(0.115, 0.112, 0.10, 0.34), 1)
	_add_rect("AssemblyRightWorkLane", Vector2(774, 300), Vector2(176, 272), Color(0.115, 0.112, 0.10, 0.30), 1)
	_add_machine_base(Vector2(238, 236), Vector2(112, 82), "机械臂 A")
	_add_machine_base(Vector2(786, 364), Vector2(112, 82), "机械臂 B")
	_add_machine_base(Vector2(512, 202), Vector2(198, 52), "半成品外骨骼")
	_add_asset_sprite(ROBOT_FACTORY_PAGE_03, Rect2(250, 100, 500, 92), Vector2(512, 150), Vector2(0.82, 0.82), Color(1, 1, 1, 0.82), 4)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 0, 184, 110), Vector2(238, 238), Vector2(0.54, 0.54), Color(1, 1, 1, 0.86), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 106, 184, 118), Vector2(786, 364), Vector2(0.54, 0.54), Color(1, 1, 1, 0.86), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_01, Rect2(370, 530, 260, 88), Vector2(512, 214), Vector2(0.76, 0.76), Color(1, 1, 1, 0.78), 4)
	_add_oil_scuff(Vector2(350, 402), Vector2(146, 36), 0.22)
	_add_oil_scuff(Vector2(678, 224), Vector2(120, 30), 0.18)
	_add_line(Vector2(178, 432), Vector2(440, 432), Color(0.30, 0.72, 0.76, 0.18), 3.0, 2)
	_add_line(Vector2(584, 168), Vector2(846, 168), Color(0.30, 0.72, 0.76, 0.18), 3.0, 2)


func _build_factory_exoskeleton_hangar_background() -> void:
	_add_rect("HangarLeftRackZone", Vector2(238, 300), Vector2(244, 320), Color(0.115, 0.10, 0.078, 0.42), 1)
	_add_rect("HangarRightRackZone", Vector2(786, 300), Vector2(244, 320), Color(0.115, 0.10, 0.078, 0.38), 1)
	_add_rect("HangarCentralClearLane", ROOM_CENTER, Vector2(314, 352), Color(0.075, 0.078, 0.075, 0.72), 2)
	_add_line(Vector2(356, 132), Vector2(356, 468), Color(0.95, 0.38, 0.10, 0.24), 2.0, 3)
	_add_line(Vector2(668, 132), Vector2(668, 468), Color(0.95, 0.38, 0.10, 0.24), 2.0, 3)

	for index in range(3):
		var y_position: float = 178.0 + index * 104.0
		_add_rect("HangarLeftRackPad", Vector2(226, y_position), Vector2(178, 64), Color(0.19, 0.15, 0.095, 0.28), 2)
		_add_rect("HangarRightRackPad", Vector2(798, y_position + 34.0), Vector2(178, 64), Color(0.19, 0.15, 0.095, 0.26), 2)
		_add_line(Vector2(148, y_position), Vector2(304, y_position), Color(0.72, 0.42, 0.18, 0.36), 2.0, 3)
		_add_line(Vector2(720, y_position + 34.0), Vector2(876, y_position + 34.0), Color(0.72, 0.42, 0.18, 0.34), 2.0, 3)
		_add_floor_label("H-%02d" % [index + 1], Vector2(146, y_position - 20.0), Color(0.88, 0.56, 0.22, 0.30))
		_add_floor_label("R-%02d" % [index + 1], Vector2(818, y_position + 14.0), Color(0.88, 0.56, 0.22, 0.28))

	_add_equipment_frame(Vector2(188, 216), Vector2(128, 88), "外骨骼挂架")
	_add_equipment_frame(Vector2(188, 384), Vector2(128, 88), "挂架锁定")
	_add_equipment_frame(Vector2(836, 216), Vector2(128, 88), "维修吊臂")
	_add_equipment_frame(Vector2(836, 384), Vector2(128, 88), "军械货架")
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 520, 256, 170), Vector2(190, 314), Vector2(0.54, 0.54), Color(1, 1, 1, 0.88), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 520, 256, 170), Vector2(834, 314), Vector2(-0.54, 0.54), Color(1, 1, 1, 0.84), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_03, Rect2(376, 0, 376, 110), Vector2(512, 142), Vector2(0.88, 0.82), Color(1, 1, 1, 0.78), 4)
	_add_warning_light(Vector2(122, 132))
	_add_warning_light(Vector2(902, 468))


func _build_factory_weapon_test_background(quality_room: bool) -> void:
	if quality_room:
		_add_rect("WeaponQualityBenchZone", Vector2(512, 236), Vector2(260, 70), Color(0.12, 0.08, 0.058, 0.48), 2)
		_add_rect("WeaponQualityBallisticLane", Vector2(512, 354), Vector2(510, 58), Color(0.07, 0.055, 0.048, 0.72), 2)
		_add_line(Vector2(270, 354), Vector2(754, 354), Color(0.95, 0.26, 0.12, 0.38), 3.0, 3)
		_add_line(Vector2(326, 326), Vector2(698, 382), Color(0.95, 0.60, 0.20, 0.22), 2.0, 3)
		_add_equipment_frame(Vector2(512, 236), Vector2(210, 54), "质检台")
		_add_equipment_frame(Vector2(228, 304), Vector2(116, 232), "武器架")
		_add_equipment_frame(Vector2(796, 304), Vector2(116, 232), "弹道架")
		_add_asset_sprite(LAB_STUFF_TEXTURE, Rect2(882, 304, 80, 56), Vector2(512, 224), Vector2(1.0, 1.0), Color(1.0, 0.82, 0.55, 0.92), 5)
		_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 0, 184, 110), Vector2(230, 292), Vector2(0.52, 0.52), Color(1, 1, 1, 0.82), 5)
		_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 106, 184, 118), Vector2(796, 292), Vector2(0.52, 0.52), Color(1, 1, 1, 0.82), 5)
	else:
		_add_rect("WeaponTestPlatform", ROOM_CENTER, Vector2(300, 184), Color(0.10, 0.068, 0.052, 0.54), 2)
		_add_rect("WeaponTestTargetRange", Vector2(512, 300), Vector2(608, 48), Color(0.045, 0.04, 0.036, 0.76), 2)
		for offset in [-96, 0, 96]:
			_add_line(Vector2(216, 300 + offset), Vector2(808, 300 + offset), Color(0.94, 0.22, 0.10, 0.24), 2.0, 3)
		_add_warning_strip(Vector2(512, 176), Vector2(330, 14), false, 0.32)
		_add_warning_strip(Vector2(512, 424), Vector2(330, 14), false, 0.28)
		_add_equipment_frame(Vector2(188, 302), Vector2(98, 242), "测试靶列")
		_add_equipment_frame(Vector2(836, 302), Vector2(98, 242), "弹痕墙")
		_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(396, 318, 180, 82), Vector2(512, 214), Vector2(0.76, 0.76), Color(1, 1, 1, 0.84), 5)

	for mark_x in [330, 512, 694]:
		_add_line(Vector2(mark_x, 150), Vector2(mark_x + 36, 188), Color(1.0, 0.34, 0.15, 0.26), 2.0, 3)
		_add_line(Vector2(mark_x, 412), Vector2(mark_x + 36, 450), Color(1.0, 0.34, 0.15, 0.22), 2.0, 3)
	_add_asset_sprite(FACILITY_DOODADS_TEXTURE, Rect2(0, 16, 16, 16), Vector2(512, 152), Vector2(1.6, 1.6), Color(1.0, 0.45, 0.28, 0.88), 5)
	_add_warning_light(Vector2(146, 150))
	_add_warning_light(Vector2(878, 450))


func _build_factory_maintenance_workshop_background() -> void:
	_add_rect("MaintenanceDirtyWorkZoneLeft", Vector2(250, 300), Vector2(250, 292), Color(0.10, 0.085, 0.065, 0.38), 1)
	_add_rect("MaintenanceDirtyWorkZoneRight", Vector2(774, 300), Vector2(250, 292), Color(0.10, 0.085, 0.065, 0.34), 1)
	_add_rect("MaintenanceCentralCombatSpace", ROOM_CENTER, Vector2(314, 322), Color(0.072, 0.074, 0.070, 0.66), 2)
	_add_equipment_frame(Vector2(230, 232), Vector2(152, 68), "维修台")
	_add_equipment_frame(Vector2(794, 366), Vector2(152, 68), "工具柜")
	_add_equipment_frame(Vector2(512, 142), Vector2(290, 42), "冷却管线")
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(576, 408, 132, 112), Vector2(334, 410), Vector2(0.72, 0.72), Color(1, 1, 1, 0.82), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(344, 522, 128, 96), Vector2(686, 204), Vector2(0.72, 0.72), Color(1, 1, 1, 0.80), 5)
	_add_asset_sprite(FACILITY_DOODADS_TEXTURE, Rect2(32, 0, 16, 16), Vector2(360, 384), Vector2(1.7, 1.7), Color(1.0, 0.72, 0.4, 0.9), 5)
	_add_oil_scuff(Vector2(280, 404), Vector2(180, 46), 0.30)
	_add_oil_scuff(Vector2(730, 246), Vector2(140, 42), 0.24)
	_add_line(Vector2(162, 448), Vector2(394, 448), Color(0.24, 0.9, 1.0, 0.16), 3.0, 2)
	_add_line(Vector2(630, 168), Vector2(862, 168), Color(0.24, 0.9, 1.0, 0.16), 3.0, 2)


func _build_factory_power_control_background() -> void:
	_add_rect("PowerControlCorePad", ROOM_CENTER, Vector2(250, 164), Color(0.045, 0.074, 0.080, 0.68), 2)
	_add_rect("PowerControlInnerCore", ROOM_CENTER, Vector2(132, 86), Color(0.055, 0.11, 0.125, 0.70), 3)
	_add_line(Vector2(512, 130), Vector2(512, 470), Color(0.25, 0.92, 1.0, 0.38), 4.0, 3)
	_add_line(Vector2(174, 300), Vector2(850, 300), Color(0.25, 0.92, 1.0, 0.28), 3.0, 3)
	_add_line(Vector2(312, 188), Vector2(712, 412), Color(1.0, 0.58, 0.12, 0.20), 2.0, 3)
	_add_line(Vector2(312, 412), Vector2(712, 188), Color(1.0, 0.58, 0.12, 0.18), 2.0, 3)
	_add_equipment_frame(Vector2(208, 300), Vector2(120, 238), "高压管线")
	_add_equipment_frame(Vector2(816, 300), Vector2(120, 238), "电源柜")
	_add_equipment_frame(ROOM_CENTER, Vector2(126, 86), "动力核心")
	_add_asset_sprite(FACILITY_COMPUTER_TEXTURE, Rect2(0, 0, 16, 16), Vector2(512, 132), Vector2(1.8, 1.8), Color(1.0, 0.86, 0.65, 0.9), 5)
	_add_warning_strip(Vector2(512, 202), Vector2(210, 14), false, 0.24)
	_add_warning_strip(Vector2(512, 398), Vector2(210, 14), false, 0.22)
	_add_floor_label("HV", Vector2(472, 286), Color(0.9, 0.58, 0.16, 0.34))
	_add_floor_label("COOLANT", Vector2(552, 334), Color(0.35, 0.95, 1.0, 0.28))


func _build_factory_armory_supply_background() -> void:
	_add_rect("ArmoryHangarBackplate", ROOM_CENTER, Vector2(766, 362), Color(0.055, 0.050, 0.042, 0.78), 1)
	_add_rect("ArmoryCentralServiceLane", ROOM_CENTER, Vector2(438, 332), Color(0.035, 0.034, 0.030, 0.86), 2)
	_add_rect("ArmoryLeftMechReserve", Vector2(250, 330), Vector2(246, 238), Color(0.115, 0.088, 0.054, 0.46), 2)
	_add_rect("ArmoryRightMechReserve", Vector2(774, 330), Vector2(246, 238), Color(0.115, 0.088, 0.054, 0.44), 2)
	_add_rect("ArmoryMerchantSafeZone", Vector2(328, 424), Vector2(178, 58), Color(0.050, 0.076, 0.078, 0.46), 2)
	_add_rect("ArmoryTerminalZone", Vector2(696, 424), Vector2(178, 58), Color(0.086, 0.064, 0.042, 0.44), 2)

	_add_line(Vector2(356, 138), Vector2(356, 462), Color(0.95, 0.42, 0.10, 0.26), 2.0, 3)
	_add_line(Vector2(668, 138), Vector2(668, 462), Color(0.95, 0.42, 0.10, 0.24), 2.0, 3)
	for y in [200, 304, 408]:
		_add_line(Vector2(134, y), Vector2(328, y), Color(0.78, 0.46, 0.16, 0.32), 2.0, 3)
		_add_line(Vector2(696, y), Vector2(890, y), Color(0.78, 0.46, 0.16, 0.30), 2.0, 3)
	_add_line(Vector2(328, 424), Vector2(696, 424), Color(0.28, 0.82, 0.88, 0.22), 2.0, 3)

	_add_equipment_frame(Vector2(512, 156), Vector2(360, 76), "补给缓存控制台")
	_add_equipment_frame(Vector2(190, 328), Vector2(124, 116), "左侧安保机甲")
	_add_equipment_frame(Vector2(834, 328), Vector2(124, 116), "右侧安保机甲")
	_add_equipment_frame(Vector2(328, 424), Vector2(174, 58), "商人安全区")
	_add_equipment_frame(Vector2(696, 424), Vector2(174, 58), "终端维护区")

	_add_asset_sprite(ROBOT_FACTORY_PAGE_03, Rect2(376, 0, 376, 110), Vector2(512, 146), Vector2(0.84, 0.78), Color(1, 1, 1, 0.82), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 520, 256, 170), Vector2(190, 328), Vector2(0.50, 0.50), Color(1, 1, 1, 0.88), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 520, 256, 170), Vector2(834, 328), Vector2(-0.50, 0.50), Color(1, 1, 1, 0.86), 5)
	_add_asset_sprite(LAB_STUFF_TEXTURE, Rect2(882, 304, 80, 56), Vector2(512, 166), Vector2(0.86, 0.86), Color(1.0, 0.82, 0.55, 0.86), 5)
	_add_asset_sprite(FACILITY_CRATES_TEXTURE, Rect2(32, 48, 16, 16), Vector2(266, 216), Vector2(1.35, 1.35), Color.WHITE, 5)
	_add_asset_sprite(FACILITY_CRATES_TEXTURE, Rect2(32, 48, 16, 16), Vector2(758, 216), Vector2(1.35, 1.35), Color.WHITE, 5)
	_add_warning_light(Vector2(122, 160))
	_add_warning_light(Vector2(902, 440))


func _build_factory_heavy_cleaner_boss_background() -> void:
	_add_rect("BossOuterMovementRing", ROOM_CENTER, Vector2(650, 332), Color(0.075, 0.064, 0.058, 0.56), 1)
	_add_rect("BossLaunchPlatform", ROOM_CENTER, Vector2(292, 188), Color(0.095, 0.052, 0.042, 0.72), 2)
	_add_rect("BossLaunchInnerPad", ROOM_CENTER, Vector2(176, 104), Color(0.045, 0.035, 0.032, 0.78), 3)
	_add_warning_strip(Vector2(512, 202), Vector2(330, 14), false, 0.34)
	_add_warning_strip(Vector2(512, 398), Vector2(330, 14), false, 0.30)
	_add_warning_strip(Vector2(360, 300), Vector2(210, 12), true, 0.26)
	_add_warning_strip(Vector2(664, 300), Vector2(210, 12), true, 0.24)
	_add_line(Vector2(248, 300), Vector2(776, 300), Color(0.92, 0.18, 0.12, 0.44), 4.0, 4)
	_add_line(Vector2(512, 174), Vector2(512, 426), Color(0.92, 0.18, 0.12, 0.30), 3.0, 4)
	_add_equipment_frame(Vector2(184, 302), Vector2(108, 300), "左侧维修轨")
	_add_equipment_frame(Vector2(840, 302), Vector2(108, 300), "右侧维修轨")
	_add_equipment_frame(Vector2(512, 130), Vector2(420, 80), "重装机闸门")
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 520, 256, 170), Vector2(190, 314), Vector2(0.55, 0.55), Color(1, 1, 1, 0.86), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_04, Rect2(0, 520, 256, 170), Vector2(834, 314), Vector2(-0.55, 0.55), Color(1, 1, 1, 0.86), 5)
	_add_asset_sprite(ROBOT_FACTORY_PAGE_03, Rect2(376, 0, 376, 110), Vector2(512, 146), Vector2(0.92, 0.92), Color(1, 1, 1, 0.84), 5)
	_add_warning_light(Vector2(166, 142))
	_add_warning_light(Vector2(858, 142))
	_add_warning_light(Vector2(166, 458))
	_add_warning_light(Vector2(858, 458))


func _build_variant_solid_blocking_props(background_key: String) -> void:
	var props: Array[Dictionary] = []
	match background_key:
		"assembly":
			props = [
				{"name": "LeftRobotArmBase", "position": Vector2(238, 236), "size": Vector2(84, 76)},
				{"name": "RightRobotArmBase", "position": Vector2(786, 364), "size": Vector2(84, 76)},
				{"name": "NorthAssemblyBridge", "position": Vector2(512, 150), "size": Vector2(370, 42)},
				{"name": "CenterPartsBench", "position": Vector2(512, 202), "size": Vector2(190, 46)},
			]
		"hangar":
			props = [
				{"name": "LeftHangarFrameA", "position": Vector2(188, 216), "size": Vector2(106, 82)},
				{"name": "LeftHangarFrameB", "position": Vector2(188, 384), "size": Vector2(106, 82)},
				{"name": "RightHangarFrameA", "position": Vector2(836, 216), "size": Vector2(106, 82)},
				{"name": "RightHangarFrameB", "position": Vector2(836, 384), "size": Vector2(106, 82)},
				{"name": "NorthCraneBridge", "position": Vector2(512, 142), "size": Vector2(350, 50)},
			]
		"weapon_test":
			props = [
				{"name": "LeftTestBay", "position": Vector2(188, 302), "size": Vector2(92, 240)},
				{"name": "RightTestBay", "position": Vector2(836, 302), "size": Vector2(92, 240)},
			]
		"weapon_quality":
			props = [
				{"name": "LeftQualityRack", "position": Vector2(228, 304), "size": Vector2(104, 210)},
				{"name": "RightQualityRack", "position": Vector2(796, 304), "size": Vector2(104, 210)},
				{"name": "QualityTerminal", "position": Vector2(512, 236), "size": Vector2(168, 54)},
				{"name": "QualityPartsBin", "position": Vector2(650, 404), "size": Vector2(106, 52)},
			]
		"maintenance":
			props = [
				{"name": "MaintenanceWorkbench", "position": Vector2(230, 232), "size": Vector2(142, 64)},
				{"name": "MaintenanceToolCabinet", "position": Vector2(794, 366), "size": Vector2(142, 64)},
				{"name": "MaintenanceCoolantPipe", "position": Vector2(512, 142), "size": Vector2(290, 38)},
			]
		"power_control":
			props = [
				{"name": "LeftPowerPipeBank", "position": Vector2(208, 300), "size": Vector2(112, 236)},
				{"name": "RightPowerCabinet", "position": Vector2(816, 300), "size": Vector2(112, 236)},
				{"name": "NorthPowerGate", "position": Vector2(512, 120), "size": Vector2(260, 44)},
			]
		"armory_supply":
			props = [
				{"name": "NorthArmoryCounter", "position": Vector2(512, 224), "size": Vector2(320, 76)},
				{"name": "LeftArmoryRack", "position": Vector2(216, 390), "size": Vector2(118, 140)},
				{"name": "RightArmoryRack", "position": Vector2(808, 390), "size": Vector2(118, 140)},
			]
		"boss_arena":
			props = [
				{"name": "BossLeftMechRail", "position": Vector2(184, 302), "size": Vector2(100, 300)},
				{"name": "BossRightMechRail", "position": Vector2(840, 302), "size": Vector2(100, 300)},
				{"name": "BossNorthHeavyGate", "position": Vector2(512, 130), "size": Vector2(420, 80)},
			]

	for prop in props:
		var position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = prop.get("size", Vector2(64, 64)) as Vector2
		var name_suffix: String = str(prop.get("name", "Factory"))
		_add_solid_blocking_prop(name_suffix, position, size)


func _add_warning_strip(center: Vector2, size: Vector2, vertical: bool = false, alpha: float = 0.42) -> void:
	var half: Vector2 = size * 0.5
	var body := Polygon2D.new()
	body.name = "FactoryWarningStrip"
	body.z_as_relative = false
	body.z_index = BACKGROUND_VISUAL_Z
	body.color = Color(0.62, 0.38, 0.08, alpha)
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

	var stripe_count := 7
	for i in range(stripe_count):
		var offset: float = -half.x + i * (size.x / float(stripe_count))
		if vertical:
			_add_line(center + Vector2(-half.y, offset), center + Vector2(half.y, offset + 18), Color(1.0, 0.68, 0.12, alpha + 0.10), 2.0, 3)
		else:
			_add_line(center + Vector2(offset, -half.y), center + Vector2(offset + 18, half.y), Color(1.0, 0.68, 0.12, alpha + 0.10), 2.0, 3)


func _add_rect(rect_name: String, center: Vector2, size: Vector2, color: Color, z_value: int = 0) -> void:
	var half: Vector2 = size * 0.5
	var rect := Polygon2D.new()
	rect.name = rect_name
	rect.z_as_relative = false
	rect.z_index = BACKGROUND_VISUAL_Z
	rect.color = color
	rect.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(rect)


func _add_oil_scuff(center: Vector2, size: Vector2, alpha: float) -> void:
	var half: Vector2 = size * 0.5
	var scuff := Polygon2D.new()
	scuff.name = "FactoryOilScuff"
	scuff.z_as_relative = false
	scuff.z_index = BACKGROUND_VISUAL_Z
	scuff.color = Color(0.01, 0.01, 0.012, alpha)
	scuff.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y * 0.2),
		center + Vector2(-half.x * 0.42, -half.y),
		center + Vector2(half.x * 0.76, -half.y * 0.55),
		center + Vector2(half.x, half.y * 0.12),
		center + Vector2(half.x * 0.34, half.y),
		center + Vector2(-half.x * 0.7, half.y * 0.62),
	])
	add_child(scuff)


func _add_asset_sprite(texture: Texture2D, region: Rect2, position: Vector2, scale_value: Vector2, color: Color, z_value: int = 4) -> void:
	if texture == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.name = "FactoryAssetProp"
	sprite.texture = atlas
	sprite.position = position
	sprite.scale = scale_value
	sprite.modulate = color
	sprite.z_as_relative = false
	sprite.z_index = BACKGROUND_VISUAL_Z
	add_child(sprite)


func _add_solid_blocking_prop(name_suffix: String, center: Vector2, size: Vector2) -> void:
	var pieces := _route_safe_blocking_rects(center, size)
	if pieces.is_empty():
		return

	var body := StaticBody2D.new()
	body.name = "SolidBlocker%s" % name_suffix
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 15
	body.add_to_group("solid_blocking_prop")
	body.set_meta("solid_blocking_prop", true)

	for piece in pieces:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = piece.size
		shape.position = piece.position + piece.size * 0.5 - center
		shape.shape = rect
		body.add_child(shape)
	add_child(body)


func _route_safe_blocking_rects(center: Vector2, size: Vector2) -> Array[Rect2]:
	var source := Rect2(center - size * 0.5, size)
	var pieces: Array[Rect2] = [source]
	for clearance in _door_clearance_rects():
		var next_pieces: Array[Rect2] = []
		for piece in pieces:
			if _rects_overlap(piece, clearance):
				next_pieces.append_array(_split_blocking_rect(piece, clearance))
			else:
				next_pieces.append(piece)
		pieces = next_pieces
	return pieces


func _door_clearance_rects() -> Array[Rect2]:
	return [
		Rect2(Vector2(448, 72), Vector2(128, 144)),
		Rect2(Vector2(448, 384), Vector2(128, 144)),
		Rect2(Vector2(32, 236), Vector2(192, 128)),
		Rect2(Vector2(800, 236), Vector2(192, 128)),
	]


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.position.x + b.size.x 		and a.position.x + a.size.x > b.position.x 		and a.position.y < b.position.y + b.size.y 		and a.position.y + a.size.y > b.position.y


func _split_blocking_rect(source: Rect2, clearance: Rect2) -> Array[Rect2]:
	var ix1: float = max(source.position.x, clearance.position.x)
	var iy1: float = max(source.position.y, clearance.position.y)
	var ix2: float = min(source.position.x + source.size.x, clearance.position.x + clearance.size.x)
	var iy2: float = min(source.position.y + source.size.y, clearance.position.y + clearance.size.y)
	if ix1 >= ix2 or iy1 >= iy2:
		return [source]
	var pieces: Array[Rect2] = []
	_append_blocking_piece(pieces, Rect2(Vector2(source.position.x, source.position.y), Vector2(ix1 - source.position.x, source.size.y)))
	_append_blocking_piece(pieces, Rect2(Vector2(ix2, source.position.y), Vector2(source.position.x + source.size.x - ix2, source.size.y)))
	_append_blocking_piece(pieces, Rect2(Vector2(ix1, source.position.y), Vector2(ix2 - ix1, iy1 - source.position.y)))
	_append_blocking_piece(pieces, Rect2(Vector2(ix1, iy2), Vector2(ix2 - ix1, source.position.y + source.size.y - iy2)))
	return pieces


func _append_blocking_piece(pieces: Array[Rect2], piece: Rect2) -> void:
	if piece.size.x >= 12.0 and piece.size.y >= 12.0:
		pieces.append(piece)


func _add_equipment_frame(center: Vector2, size: Vector2, frame_label: String) -> void:
	var half: Vector2 = size * 0.5
	_add_rect("FactoryEquipment%s" % frame_label, center, size, Color(0.055, 0.062, 0.064, 0.82), 4)
	var rim_color := Color(0.70, 0.48, 0.20, 0.46)
	if frame_label.find("动力") >= 0 or frame_label.find("终端") >= 0:
		rim_color = Color(0.32, 0.92, 1.0, 0.52)
	elif frame_label.find("Boss") >= 0 or frame_label.find("重装") >= 0:
		rim_color = Color(0.94, 0.22, 0.12, 0.54)
	_add_line(center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), rim_color, 2.0, 5)
	_add_line(center + Vector2(half.x, -half.y), center + Vector2(half.x, half.y), rim_color, 2.0, 5)
	_add_line(center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y), rim_color, 2.0, 5)
	_add_line(center + Vector2(-half.x, half.y), center + Vector2(-half.x, -half.y), rim_color, 2.0, 5)
	_add_line(center + Vector2(-half.x * 0.58, 0), center + Vector2(half.x * 0.58, 0), rim_color.darkened(0.2), 2.0, 5)


func _add_machine_base(center: Vector2, size: Vector2, machine_label: String) -> void:
	_add_equipment_frame(center, size, machine_label)
	_add_line(center + Vector2(-size.x * 0.32, -size.y * 0.25), center + Vector2(size.x * 0.34, size.y * 0.26), Color(0.94, 0.52, 0.16, 0.34), 3.0, 5)
	_add_line(center + Vector2(-size.x * 0.26, size.y * 0.25), center + Vector2(size.x * 0.30, -size.y * 0.20), Color(0.28, 0.86, 0.90, 0.24), 2.0, 5)


func _add_warning_light(position: Vector2) -> void:
	_add_rect("FactoryWarningLight", position, Vector2(20, 14), Color(0.95, 0.18, 0.08, 0.44), 6)
	_add_line(position + Vector2(-8, 0), position + Vector2(8, 0), Color(1.0, 0.28, 0.10, 0.62), 2.0, 7)


func _add_floor_label(text: String, position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.name = "FactoryFloorMarking"
	label.text = text
	label.position = position
	label.modulate = color
	label.z_as_relative = false
	label.z_index = BACKGROUND_VISUAL_Z
	label.scale = Vector2(0.55, 0.55)
	add_child(label)


func _add_line(from: Vector2, to: Vector2, color: Color, width: float, z_value: int = 1) -> void:
	var line := Line2D.new()
	line.name = "FactoryLine"
	line.z_as_relative = false
	line.z_index = BACKGROUND_VISUAL_Z
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	add_child(line)
