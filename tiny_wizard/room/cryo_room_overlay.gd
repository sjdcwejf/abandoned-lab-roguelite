class_name CryoRoomOverlay
extends Node2D


const CRYO_FLOOR_FOG_SCENE: PackedScene = preload("res://tiny_wizard/assets/effects/chapter3_cryo_mist/scenes/cryo_floor_fog_layer.tscn")
const CRYO_SMOKE_VENT_SCENE: PackedScene = preload("res://tiny_wizard/assets/effects/chapter3_cryo_mist/scenes/cryo_smoke_vent.tscn")
const LAND_PIXELS_FLOOR: Texture2D = preload("res://tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesFloor32.png")
const LAND_PIXELS_WALLS: Texture2D = preload("res://tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesWalls.png")
const LAND_PIXELS_STUFF: Texture2D = preload("res://tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png")
const SCI_FI_FACILITY_TILESET: Texture2D = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/tileset.png")
const SCI_FI_FACILITY_COMPUTER: Texture2D = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/computer_spritesheet.png")
const WARPED_LAB_TILESET: Texture2D = preload("res://tiny_wizard/assets/third_party/warped_top_down_lab/Tileset.png")

const ROOM_CENTER := Vector2(512, 300)
const FLOOR_MIN := Vector2(72, 92)
const FLOOR_MAX := Vector2(952, 508)
const LAND_TILE := Vector2(32, 32)
const SCI_FI_TILE := Vector2(16, 16)
const CRYO_FLOOR_BASE_REGION := Rect2(0, 0, 32, 32)
const CRYO_FLOOR_GRID_REGION := Rect2(32, 0, 32, 32)
const CRYO_FLOOR_PANEL_REGION := Rect2(64, 0, 32, 32)
const CRYO_WALL_PANEL_REGION := Rect2(0, 0, 32, 32)
const CRYO_WALL_INSULATED_REGION := Rect2(32, 0, 32, 32)
const CRYO_WALL_RIM_REGION := Rect2(64, 0, 32, 32)
const CRYO_STUFF_LOCKER_REGION := Rect2(256, 96, 32, 32)
const CRYO_STUFF_CABINET_REGION := Rect2(288, 96, 32, 32)
const SCI_FI_VENT_REGION := Rect2(0, 48, 16, 16)
const SCI_FI_PANEL_REGION := Rect2(16, 48, 16, 16)
const SCI_FI_PIPE_REGION := Rect2(32, 48, 16, 16)
const SCI_FI_CONTROL_REGION := Rect2(0, 0, 16, 16)
const WARPED_FALLBACK_WALL_REGION := Rect2(0, 32, 16, 16)
const BACKGROUND_VISUAL_Z := -2

const CHAPTER_3_CRYO_BACKGROUND_THEME := {
	"name": "chapter_3_cryo_background_theme",
	"floor_set": [
		"cryo_floor_base_cold_metal",
		"cryo_floor_panel_grid",
		"cryo_floor_coolant_channel",
		"cryo_floor_frost_edge",
		"cryo_floor_condensation",
		"cryo_floor_low_temp_marking",
	],
	"wall_set": [
		"cryo_wall_panel_standard",
		"cryo_wall_panel_insulated",
		"cryo_wall_vent",
		"cryo_wall_pipe",
		"cryo_wall_storage_locker",
		"cryo_wall_control_panel",
		"cryo_wall_frost_corner",
	],
	"door_set": [
		"frosted_cryo_door",
		"sealed_cryo_wall_segment",
	],
	"decal_set": [
		"frost_patch",
		"condensation_mark",
		"ice_crack",
		"coolant_line",
		"blue_white_warning_line",
	],
	"mist_set": [
		"CryoFloorFogLayer",
		"CryoSmokeVent",
	],
}

@export var variant := "combat"


func _ready() -> void:
	z_index = -2
	_build_after_room_doors_update()


func _build_after_room_doors_update() -> void:
	await get_tree().process_frame
	_build_cryo_background()


func _build_cryo_background() -> void:
	_hide_inherited_lab_art()
	var background_key: String = _resolve_background_key()
	var palette: Dictionary = _palette(background_key)
	_build_cryo_floor_system(background_key, palette)
	_build_cryo_wall_system(background_key, palette)
	_build_cryo_door_system(background_key, palette)
	_build_low_temp_labels(background_key, palette)
	_build_cryo_equipment(background_key, palette)
	_build_cryo_floor_decals(background_key, palette)
	_build_cryo_mist_effects(background_key, palette)


func _hide_inherited_lab_art() -> void:
	var room := get_parent()
	if room == null:
		return
	var inherited_walls := room.get_node_or_null("RoomWalls") as CanvasItem
	if inherited_walls != null:
		inherited_walls.visible = false


func _resolve_background_key() -> String:
	match variant:
		"start":
			return "cryo_control_room"
		"pod":
			return "cryo_storage_room"
		"vent":
			return "cryo_pipe_room"
		"reward", "elite":
			return "cryo_sample_warehouse"
		"boss":
			return "cryo_boss_room"
	return "cryo_combat_room"


func _palette(background_key: String) -> Dictionary:
	var palette: Dictionary = {
		"floor_base": Color(0.13, 0.165, 0.175, 0.98),
		"floor_panel": Color(0.18, 0.215, 0.218, 0.58),
		"floor_shadow": Color(0.055, 0.08, 0.09, 0.32),
		"frost": Color(0.76, 0.92, 0.96, 0.18),
		"frost_strong": Color(0.9, 0.98, 1.0, 0.26),
		"coolant": Color(0.55, 0.78, 0.84, 0.16),
		"coolant_bright": Color(0.78, 0.92, 0.96, 0.24),
		"wall": Color(0.11, 0.135, 0.145, 1.0),
		"wall_inner": Color(0.16, 0.19, 0.198, 0.98),
		"wall_rim": Color(0.19, 0.22, 0.225, 0.88),
		"door_dark": Color(0.07, 0.095, 0.105, 0.98),
		"door_light": Color(0.7, 0.9, 0.96, 0.22),
		"red_fault": Color(0.85, 0.2, 0.14, 0.26),
		"mist": Color(0.9, 0.97, 1.0, 0.13),
	}
	match background_key:
		"cryo_pipe_room":
			palette["coolant"] = Color(0.56, 0.8, 0.86, 0.22)
			palette["frost"] = Color(0.82, 0.96, 1.0, 0.24)
		"cryo_storage_room":
			palette["floor_panel"] = Color(0.09, 0.13, 0.145, 0.68)
			palette["mist"] = Color(0.94, 0.98, 1.0, 0.16)
		"cryo_sample_warehouse":
			palette["floor_panel"] = Color(0.095, 0.125, 0.132, 0.7)
		"cryo_boss_room":
			palette["wall"] = Color(0.095, 0.122, 0.135, 1.0)
			palette["coolant_bright"] = Color(0.84, 0.96, 1.0, 0.28)
			palette["red_fault"] = Color(0.9, 0.14, 0.1, 0.34)
	return palette


func _build_cryo_floor_system(background_key: String, palette: Dictionary) -> void:
	_add_rect("CryoColdMetalFloorBase", ROOM_CENTER, FLOOR_MAX - FLOOR_MIN, palette["floor_base"] as Color, 0)
	_build_cryo_floor_grid_v2(background_key, palette)
	_build_variant_floor_zones(background_key, palette)
	_build_low_temp_floor_markings(background_key, palette)
	_build_coolant_floor_lines(background_key, palette)
	_build_floor_edge_frost_v2(background_key, palette)


func _build_cryo_floor_grid_v2(background_key: String, palette: Dictionary) -> void:
	var panel_color: Color = palette["floor_panel"] as Color
	var shadow_color: Color = palette["floor_shadow"] as Color
	for x in range(112, 912, 64):
		for y in range(128, 480, 64):
			var center := Vector2(x + 32, y + 32)
			var color := panel_color
			if int((x + y) / 32) % 3 == 0:
				color = Color(panel_color.r * 0.82, panel_color.g * 0.86, panel_color.b * 0.9, panel_color.a)
			var region := CRYO_FLOOR_BASE_REGION
			if int((x + y) / 64) % 2 == 0:
				region = CRYO_FLOOR_GRID_REGION
			if background_key in ["cryo_storage_room", "cryo_sample_warehouse"] and (x < 256 or x > 736):
				region = CRYO_FLOOR_PANEL_REGION
			_add_atlas_tile("CryoFloorAtlasPanel", LAND_PIXELS_FLOOR, region, center, Vector2(64, 64), color, 1)
			if int((x + y) / 96) % 3 == 0:
				_add_line("CryoFinePanelSeam", PackedVector2Array([
					center + Vector2(-28, -18),
					center + Vector2(26, -18),
				]), Color(shadow_color.r, shadow_color.g, shadow_color.b, 0.22), 0.8, 2)


func _build_variant_floor_zones(background_key: String, palette: Dictionary) -> void:
	var zone_color := Color(0.105, 0.16, 0.175, 0.32)
	var frost_color: Color = palette["frost"] as Color
	match background_key:
		"cryo_control_room":
			_add_rect("CryoControlTerminalZone", Vector2(512, 176), Vector2(270, 78), zone_color, 2)
			_add_rect("CryoEntryColdMat", Vector2(512, 474), Vector2(210, 44), Color(0.15, 0.2, 0.212, 0.36), 2)
		"cryo_storage_room":
			_add_rect("CryoStorageLeftZone", Vector2(184, 304), Vector2(126, 310), zone_color, 2)
			_add_rect("CryoStorageRightZone", Vector2(840, 304), Vector2(126, 310), zone_color, 2)
			_add_rect("CryoStorageMainLane", ROOM_CENTER, Vector2(360, 312), Color(0.12, 0.16, 0.17, 0.28), 2)
		"cryo_pipe_room":
			_add_rect("CryoPipeTopServiceDeck", Vector2(512, 128), Vector2(620, 58), zone_color, 2)
			_add_rect("CryoPipeBottomServiceDeck", Vector2(512, 472), Vector2(620, 58), zone_color, 2)
		"cryo_sample_warehouse":
			_add_rect("CryoSampleLeftStorage", Vector2(216, 300), Vector2(168, 268), zone_color, 2)
			_add_rect("CryoSampleRightStorage", Vector2(808, 300), Vector2(168, 268), zone_color, 2)
			_add_rect("CryoSampleRewardLane", ROOM_CENTER, Vector2(330, 220), Color(0.12, 0.155, 0.165, 0.26), 2)
		"cryo_boss_room":
			_add_ring("CryoBossColdCoreRing", ROOM_CENTER, 118.0, palette["coolant_bright"] as Color, 3.0, 3)
			_add_ring("CryoBossOuterMoveRing", ROOM_CENTER, 188.0, Color(frost_color.r, frost_color.g, frost_color.b, 0.2), 2.0, 2)
			_add_rect("CryoBossOuterLane", ROOM_CENTER, Vector2(640, 320), Color(0.11, 0.15, 0.165, 0.26), 1)
		_:
			_add_rect("CryoCombatOpenLane", ROOM_CENTER, Vector2(500, 290), Color(0.12, 0.16, 0.172, 0.24), 2)


func _build_low_temp_floor_markings(background_key: String, palette: Dictionary) -> void:
	var coolant: Color = palette["coolant_bright"] as Color
	var line_color := Color(coolant.r, coolant.g, coolant.b, 0.18)
	for y in [154, 446]:
		_add_line("CryoBlueWhiteBoundaryLine", PackedVector2Array([Vector2(128, y), Vector2(896, y)]), line_color, 1.4, 5)
	for x in [184, 840]:
		_add_line("CryoSideStorageBoundaryLine", PackedVector2Array([Vector2(x, 160), Vector2(x, 440)]), Color(line_color.r, line_color.g, line_color.b, 0.12), 1.0, 5)
	match background_key:
		"cryo_storage_room":
			for y in [214, 306, 398]:
				_add_line("CryoStorageBayNumberLine", PackedVector2Array([Vector2(132, y), Vector2(266, y)]), line_color, 1.2, 5)
				_add_line("CryoStorageBayNumberLine", PackedVector2Array([Vector2(758, y), Vector2(892, y)]), line_color, 1.2, 5)
			_add_label("CryoFloorBayLabel", "STORAGE", Vector2(138, 166), Color(coolant.r, coolant.g, coolant.b, 0.36), 7)
		"cryo_pipe_room":
			for x in [286, 512, 738]:
				_add_rect("CryoCoolantChannelPlate", Vector2(x, 300), Vector2(42, 260), Color(0.07, 0.12, 0.14, 0.34), 3)
				_add_line("CryoCoolantChannelLight", PackedVector2Array([Vector2(x, 184), Vector2(x, 416)]), Color(coolant.r, coolant.g, coolant.b, 0.14), 1.2, 5)
		"cryo_sample_warehouse":
			for x in [176, 252, 772, 848]:
				_add_line("CryoWarehouseGridLine", PackedVector2Array([Vector2(x, 176), Vector2(x, 424)]), Color(line_color.r, line_color.g, line_color.b, 0.1), 0.8, 5)
			_add_label("CryoFloorBayLabel", "FREEZER UNIT", Vector2(420, 430), Color(coolant.r, coolant.g, coolant.b, 0.34), 7)
		"cryo_boss_room":
			_add_rect("CryoBossCoreBasePlate", ROOM_CENTER, Vector2(190, 118), Color(0.08, 0.135, 0.155, 0.34), 3)
			_add_label("CryoFloorBayLabel", "LOW TEMP", Vector2(472, 236), Color(coolant.r, coolant.g, coolant.b, 0.32), 7)


func _build_floor_edge_frost_v2(_background_key: String, palette: Dictionary) -> void:
	var frost: Color = palette["frost"] as Color
	_add_patch("CryoNorthFrostEdge", Vector2(512, 148), Vector2(760, 24), Color(frost.r, frost.g, frost.b, 0.12), 6)
	_add_patch("CryoSouthFrostEdge", Vector2(512, 452), Vector2(760, 24), Color(frost.r, frost.g, frost.b, 0.12), 6)
	_add_patch("CryoWestFrostEdge", Vector2(130, 300), Vector2(28, 270), Color(frost.r, frost.g, frost.b, 0.11), 6)
	_add_patch("CryoEastFrostEdge", Vector2(894, 300), Vector2(28, 270), Color(frost.r, frost.g, frost.b, 0.11), 6)


func _build_coolant_floor_lines(background_key: String, palette: Dictionary) -> void:
	var coolant: Color = palette["coolant"] as Color
	var bright: Color = palette["coolant_bright"] as Color
	match background_key:
		"cryo_control_room":
			_add_line("CryoControlCoolantGroove", PackedVector2Array([Vector2(512, 112), Vector2(512, 190), Vector2(512, 248)]), coolant, 1.4, 4)
			_add_line("CryoControlLeftGroove", PackedVector2Array([Vector2(108, 300), Vector2(310, 300), Vector2(430, 232)]), Color(coolant.r, coolant.g, coolant.b, 0.14), 1.1, 4)
			_add_line("CryoControlRightGroove", PackedVector2Array([Vector2(916, 300), Vector2(714, 300), Vector2(594, 232)]), Color(coolant.r, coolant.g, coolant.b, 0.14), 1.1, 4)
		"cryo_storage_room":
			for x in [244, 780]:
				_add_line("CryoStorageCoolantGroove", PackedVector2Array([Vector2(x, 132), Vector2(x, 468)]), coolant, 1.4, 4)
			_add_line("CryoStorageMainLaneGroove", PackedVector2Array([Vector2(512, 130), Vector2(512, 470)]), Color(bright.r, bright.g, bright.b, 0.1), 1.0, 4)
		"cryo_pipe_room":
			for y in [138, 462]:
				_add_line("CryoPipeCoolantGroove", PackedVector2Array([Vector2(116, y), Vector2(300, y), Vector2(512, y + 26), Vector2(728, y), Vector2(910, y)]), Color(bright.r, bright.g, bright.b, 0.18), 1.6, 4)
			_add_line("CryoPipeBrokenGroove", PackedVector2Array([Vector2(240, 220), Vector2(398, 256), Vector2(544, 244), Vector2(690, 284), Vector2(812, 260)]), Color(coolant.r, coolant.g, coolant.b, 0.12), 1.0, 4)
		"cryo_sample_warehouse":
			for y in [202, 300, 398]:
				_add_line("CryoSampleRackGuide", PackedVector2Array([Vector2(150, y), Vector2(340, y)]), Color(coolant.r, coolant.g, coolant.b, 0.12), 1.0, 4)
				_add_line("CryoSampleRackGuide", PackedVector2Array([Vector2(684, y), Vector2(874, y)]), Color(coolant.r, coolant.g, coolant.b, 0.12), 1.0, 4)
		"cryo_boss_room":
			for target in [Vector2(512, 114), Vector2(512, 486), Vector2(96, 300), Vector2(928, 300)]:
				_add_line("CryoBossCoreCoolantGroove", PackedVector2Array([target, ROOM_CENTER]), Color(bright.r, bright.g, bright.b, 0.13), 1.4, 4)
		_:
			_add_line("CryoCombatCoolantGroove", PackedVector2Array([Vector2(120, 300), Vector2(326, 300), Vector2(512, 238), Vector2(698, 300), Vector2(904, 300)]), Color(coolant.r, coolant.g, coolant.b, 0.12), 1.0, 4)


func _build_cryo_wall_system(background_key: String, palette: Dictionary) -> void:
	var wall: Color = palette["wall"] as Color
	var inner: Color = palette["wall_inner"] as Color
	var rim: Color = palette["wall_rim"] as Color
	var frost: Color = palette["frost"] as Color
	_add_rect("CryoOuterWallTop", Vector2(512, 52), Vector2(1024, 104), wall, 12)
	_add_rect("CryoOuterWallBottom", Vector2(512, 548), Vector2(1024, 104), wall, 12)
	_add_rect("CryoOuterWallLeft", Vector2(42, 300), Vector2(84, 496), wall, 12)
	_add_rect("CryoOuterWallRight", Vector2(982, 300), Vector2(84, 496), wall, 12)

	_add_rect("CryoInnerWallRimTop", Vector2(512, 104), Vector2(900, 36), inner, 13)
	_add_rect("CryoInnerWallRimBottom", Vector2(512, 496), Vector2(900, 36), inner, 13)
	_add_rect("CryoInnerWallRimLeft", Vector2(84, 300), Vector2(36, 400), inner, 13)
	_add_rect("CryoInnerWallRimRight", Vector2(940, 300), Vector2(36, 400), inner, 13)

	_add_rect("CryoWallFloorTransitionTop", Vector2(512, 126), Vector2(860, 26), rim, 14)
	_add_rect("CryoWallFloorTransitionBottom", Vector2(512, 474), Vector2(860, 26), rim, 14)
	_add_rect("CryoWallFloorTransitionLeft", Vector2(106, 300), Vector2(26, 350), rim, 14)
	_add_rect("CryoWallFloorTransitionRight", Vector2(918, 300), Vector2(26, 350), rim, 14)

	_build_wall_modules(background_key, palette)
	_build_corner_frost(background_key, frost)


func _build_wall_modules(background_key: String, palette: Dictionary) -> void:
	var coolant: Color = palette["coolant"] as Color
	var light: Color = palette["coolant_bright"] as Color
	var fault: Color = palette["red_fault"] as Color
	var top_y := 98.0
	var bottom_y := 502.0
	var left_x := 92.0
	var right_x := 932.0
	for x in [146, 226, 306, 386, 638, 718, 798, 878]:
		_add_cryo_wall_panel_standard(Vector2(x, top_y), "top", palette)
		_add_cryo_wall_panel_insulated(Vector2(x, bottom_y), "bottom", palette)
	for x in [246, 512, 778]:
		_add_cryo_wall_vent(Vector2(x, top_y + 8), "top", palette)
		_add_cryo_wall_pipe(Vector2(x, bottom_y - 8), "bottom", palette)
	for y in [164, 226, 374, 436]:
		_add_cryo_wall_pipe(Vector2(left_x, y), "left", palette)
	for y in [164, 226, 374, 436]:
		_add_cryo_wall_storage_locker(Vector2(right_x, y), "right", palette)

	match background_key:
		"cryo_pipe_room":
			for x in [176, 318, 706, 850]:
				_add_cryo_wall_pipe(Vector2(x, top_y + 24), "top", palette, Vector2(96, 26))
				_add_cryo_wall_vent(Vector2(x, bottom_y - 24), "bottom", palette, Vector2(88, 24))
			for y in [214, 300, 386]:
				_add_cryo_wall_pipe(Vector2(left_x + 22, y), "left", palette, Vector2(28, 96))
		"cryo_control_room":
			_add_cryo_wall_control_panel(Vector2(512, 104), "LOW TEMP", palette)
			_add_cryo_wall_control_panel(Vector2(150, 300), "-80C", palette)
			_add_cryo_wall_control_panel(Vector2(874, 300), "COOLANT", palette)
		"cryo_sample_warehouse":
			for y in [206, 300, 394]:
				_add_cryo_wall_storage_locker(Vector2(right_x - 22, y), "right", palette, Vector2(40, 70))
				_add_cryo_wall_storage_locker(Vector2(left_x + 22, y), "left", palette, Vector2(40, 70))
			_add_cryo_wall_control_panel(Vector2(266, bottom_y - 18), "STORAGE", palette)
			_add_cryo_wall_control_panel(Vector2(760, bottom_y - 18), "CRYO", palette)
		"cryo_storage_room":
			for y in [206, 300, 394]:
				_add_cryo_wall_storage_locker(Vector2(right_x - 20, y), "right", palette, Vector2(42, 76))
			for x in [226, 798]:
				_add_cryo_wall_control_panel(Vector2(x, top_y + 20), "STORAGE", palette)
		"cryo_boss_room":
			for p in [Vector2(150, 126), Vector2(874, 126), Vector2(150, 474), Vector2(874, 474)]:
				_add_rect("CryoBossFaultLight", p, Vector2(20, 10), fault, 19)
				_add_line("CryoBossWallConduit", PackedVector2Array([p, ROOM_CENTER]), Color(light.r, light.g, light.b, 0.08), 1.0, 18)
			for x in [286, 512, 738]:
				_add_cryo_wall_vent(Vector2(x, top_y + 16), "top", palette, Vector2(108, 24))
				_add_cryo_wall_pipe(Vector2(x, bottom_y - 16), "bottom", palette, Vector2(118, 24))
		_:
			_add_cryo_wall_control_panel(Vector2(512, top_y + 18), "CRYO", palette)


func _add_cryo_wall_panel_standard(center: Vector2, direction: String, palette: Dictionary, size := Vector2(76, 30)) -> void:
	var tint := Color(0.48, 0.62, 0.66, 0.46)
	_add_atlas_tile("CryoWallPanelStandard", LAND_PIXELS_WALLS, CRYO_WALL_PANEL_REGION, center, size, tint, 16)
	_add_rect("CryoWallPanelColdInset", center, size * Vector2(0.78, 0.18), Color(0.7, 0.9, 0.96, 0.07), 17)
	if direction in ["top", "bottom"]:
		_add_line("CryoWallPanelColdSeam", PackedVector2Array([
			center + Vector2(-size.x * 0.42, size.y * 0.3),
			center + Vector2(size.x * 0.42, size.y * 0.3),
		]), palette["coolant"] as Color, 0.8, 18)


func _add_cryo_wall_panel_insulated(center: Vector2, direction: String, palette: Dictionary, size := Vector2(76, 30)) -> void:
	var tint := Color(0.55, 0.66, 0.68, 0.5)
	_add_atlas_tile("CryoWallPanelInsulated", LAND_PIXELS_WALLS, CRYO_WALL_INSULATED_REGION, center, size, tint, 16)
	_add_rect("CryoInsulatedWallRib", center, size * Vector2(0.12, 0.72), Color(0.08, 0.12, 0.13, 0.34), 17)
	if direction in ["top", "bottom"]:
		_add_line("CryoInsulatedWallFrostSeam", PackedVector2Array([
			center + Vector2(-size.x * 0.38, -size.y * 0.3),
			center + Vector2(size.x * 0.38, -size.y * 0.3),
		]), Color(0.86, 0.96, 1.0, 0.09), 0.8, 18)


func _add_cryo_wall_vent(center: Vector2, direction: String, palette: Dictionary, size := Vector2(78, 24)) -> void:
	_add_rect("CryoVentWallBackplate", center, size + Vector2(10, 8), Color(0.07, 0.105, 0.115, 0.84), 17)
	_add_atlas_tile("CryoWallVentAtlas", SCI_FI_FACILITY_TILESET, SCI_FI_VENT_REGION, center, size, Color(0.62, 0.78, 0.8, 0.5), 18)
	var horizontal := direction in ["top", "bottom"]
	if horizontal:
		for offset in [-7, 0, 7]:
			_add_line("CryoVentSlat", PackedVector2Array([
				center + Vector2(-size.x * 0.34, offset),
				center + Vector2(size.x * 0.34, offset),
			]), Color(0.82, 0.96, 1.0, 0.13), 0.8, 19)
	else:
		for offset in [-7, 0, 7]:
			_add_line("CryoVentSlat", PackedVector2Array([
				center + Vector2(offset, -size.y * 0.34),
				center + Vector2(offset, size.y * 0.34),
			]), Color(0.82, 0.96, 1.0, 0.13), 0.8, 19)


func _add_cryo_wall_pipe(center: Vector2, direction: String, palette: Dictionary, size := Vector2(68, 30)) -> void:
	_add_rect("CryoPipeWallBackplate", center, size + Vector2(10, 8), Color(0.06, 0.095, 0.105, 0.78), 17)
	_add_atlas_tile("CryoPipeWallAtlas", SCI_FI_FACILITY_TILESET, SCI_FI_PIPE_REGION, center, size, Color(0.58, 0.78, 0.82, 0.46), 18)
	var coolant: Color = palette["coolant"] as Color
	if direction in ["left", "right"]:
		for offset in [-8, 8]:
			_add_line("CryoVerticalWallPipe", PackedVector2Array([
				center + Vector2(offset, -size.y * 0.44),
				center + Vector2(offset, size.y * 0.44),
			]), Color(coolant.r, coolant.g, coolant.b, 0.16), 1.2, 19)
	else:
		for offset in [-6, 6]:
			_add_line("CryoHorizontalWallPipe", PackedVector2Array([
				center + Vector2(-size.x * 0.44, offset),
				center + Vector2(size.x * 0.44, offset),
			]), Color(coolant.r, coolant.g, coolant.b, 0.15), 1.2, 19)


func _add_cryo_wall_storage_locker(center: Vector2, direction: String, palette: Dictionary, size := Vector2(42, 68)) -> void:
	_add_rect("CryoStorageLockerWallBackplate", center, size + Vector2(10, 8), Color(0.075, 0.105, 0.112, 0.84), 17)
	_add_atlas_tile("CryoStorageLockerAtlas", LAND_PIXELS_STUFF, CRYO_STUFF_LOCKER_REGION, center, size, Color(0.62, 0.78, 0.82, 0.48), 18)
	var light: Color = palette["coolant_bright"] as Color
	var sign_pos := center + (Vector2(-size.x * 0.22, 0) if direction == "right" else Vector2(size.x * 0.22, 0))
	_add_rect("CryoStorageLockerTempLight", sign_pos, Vector2(4, size.y * 0.52), Color(light.r, light.g, light.b, 0.14), 19)


func _add_cryo_wall_control_panel(center: Vector2, text: String, palette: Dictionary) -> void:
	var light: Color = palette["coolant_bright"] as Color
	_add_rect("CryoWallControlPanelBack", center, Vector2(104, 26), Color(0.055, 0.09, 0.1, 0.84), 18)
	_add_atlas_tile("CryoWallControlPanelAtlas", SCI_FI_FACILITY_COMPUTER, Rect2(0, 0, 16, 16), center + Vector2(-36, 0), Vector2(26, 22), Color(0.58, 0.8, 0.84, 0.48), 19)
	_add_line("CryoWallControlPanelStatus", PackedVector2Array([
		center + Vector2(-14, -2),
		center + Vector2(36, -2),
	]), Color(light.r, light.g, light.b, 0.2), 1.1, 20)
	_add_label("CryoWallStatusLabel", text, center + Vector2(-28, 4), Color(light.r, light.g, light.b, 0.42), 7)


func _build_corner_frost(background_key: String, frost_color: Color) -> void:
	var strong := Color(frost_color.r, frost_color.g, frost_color.b, min(frost_color.a + 0.12, 0.5))
	_add_atlas_tile("CryoFrostCornerWallNW", LAND_PIXELS_WALLS, CRYO_WALL_RIM_REGION, Vector2(116, 126), Vector2(76, 38), Color(0.62, 0.78, 0.82, 0.42), 17)
	_add_atlas_tile("CryoFrostCornerWallNE", LAND_PIXELS_WALLS, CRYO_WALL_RIM_REGION, Vector2(908, 128), Vector2(70, 38), Color(0.58, 0.75, 0.8, 0.38), 17)
	_add_atlas_tile("CryoFrostCornerWallSW", LAND_PIXELS_WALLS, CRYO_WALL_RIM_REGION, Vector2(118, 474), Vector2(72, 40), Color(0.58, 0.75, 0.8, 0.38), 17)
	_add_atlas_tile("CryoFrostCornerWallSE", LAND_PIXELS_WALLS, CRYO_WALL_RIM_REGION, Vector2(906, 474), Vector2(78, 42), Color(0.62, 0.78, 0.82, 0.42), 17)
	_add_patch("CryoCornerFrostNW", Vector2(116, 126), Vector2(76, 30), strong, 18)
	_add_patch("CryoCornerFrostNE", Vector2(908, 128), Vector2(68, 28), frost_color, 18)
	_add_patch("CryoCornerFrostSW", Vector2(118, 474), Vector2(72, 30), frost_color, 18)
	_add_patch("CryoCornerFrostSE", Vector2(906, 474), Vector2(78, 32), strong, 18)
	if background_key == "cryo_boss_room":
		for p in [Vector2(116, 126), Vector2(908, 128), Vector2(118, 474), Vector2(906, 474)]:
			_add_ring("CryoBossCornerFreezeLock", p, 24.0, Color(0.56, 0.96, 1.0, 0.24), 1.4, 19, 18)


func _build_cryo_door_system(background_key: String, palette: Dictionary) -> void:
	var doors: Array[Dictionary] = [
		{"dir": "up", "center": Vector2(512, 72), "size": Vector2(218, 72), "light": Vector2(512, 122), "light_size": Vector2(116, 4)},
		{"dir": "down", "center": Vector2(512, 528), "size": Vector2(218, 72), "light": Vector2(512, 478), "light_size": Vector2(116, 4)},
		{"dir": "left", "center": Vector2(64, 300), "size": Vector2(76, 192), "light": Vector2(106, 300), "light_size": Vector2(4, 106)},
		{"dir": "right", "center": Vector2(960, 300), "size": Vector2(76, 192), "light": Vector2(918, 300), "light_size": Vector2(4, 106)},
	]
	for door_value in doors:
		var door: Dictionary = door_value
		var direction := String(door.get("dir", ""))
		var center: Vector2 = door.get("center", Vector2.ZERO) as Vector2
		var size: Vector2 = door.get("size", Vector2.ZERO) as Vector2
		if _is_visual_door_hidden(direction):
			_add_sealed_cryo_wall_segment(direction, center, size, background_key, palette)
		else:
			var light: Vector2 = door.get("light", Vector2.ZERO) as Vector2
			var light_size: Vector2 = door.get("light_size", Vector2.ZERO) as Vector2
			_add_cryo_door_frame(direction, center, size, light, light_size, background_key, palette)


func _is_visual_door_hidden(direction: String) -> bool:
	var room := get_parent()
	if room == null:
		return false
	var door_node_name := ""
	match direction:
		"up":
			door_node_name = "UpDoor"
			if room.get("hide_up_door") == true:
				return true
		"down":
			door_node_name = "DownDoor"
			if room.get("hide_down_door") == true:
				return true
		"left":
			door_node_name = "LeftDoor"
			if room.get("hide_left_door") == true:
				return true
		"right":
			door_node_name = "RightDoor"
			if room.get("hide_right_door") == true:
				return true
	if door_node_name != "":
		var inherited_door := room.get_node_or_null("RoomWalls/%s" % door_node_name) as CanvasItem
		if inherited_door != null and inherited_door.visible == false:
			return true
	return false


func _add_cryo_door_frame(direction: String, center: Vector2, size: Vector2, light: Vector2, light_size: Vector2, _background_key: String, palette: Dictionary) -> void:
	var frame_extra := Vector2(32, 18) if direction in ["up", "down"] else Vector2(18, 32)
	_add_rect("CryoDoorHazardCover", center, size + frame_extra, Color(0.065, 0.085, 0.092, 1.0), 24)
	_add_rect("CryoDoorColdRecess", center, size * 0.72, palette["door_dark"] as Color, 25)
	_add_rect("CryoDoorFrostedFrame", center, size + frame_extra * 0.6, Color(0.12, 0.155, 0.16, 0.96), 23)
	if direction in ["up", "down"]:
		for x_offset in [-64, 0, 64]:
			_add_atlas_tile("CryoDoorInsulatedAtlas", LAND_PIXELS_WALLS, CRYO_WALL_INSULATED_REGION, center + Vector2(x_offset, 0), Vector2(58, 42), Color(0.5, 0.66, 0.7, 0.38), 24)
	else:
		for y_offset in [-58, 0, 58]:
			_add_atlas_tile("CryoDoorInsulatedAtlas", LAND_PIXELS_WALLS, CRYO_WALL_INSULATED_REGION, center + Vector2(0, y_offset), Vector2(40, 58), Color(0.5, 0.66, 0.7, 0.38), 24)
	_add_rect("CryoDoorColdLight", light, light_size, palette["door_light"] as Color, 26)
	var frost_size := Vector2(size.x + 28, 10) if direction in ["up", "down"] else Vector2(10, size.y + 28)
	_add_rect("CryoDoorFrostThreshold", light, frost_size, Color(0.86, 0.96, 1.0, 0.12), 26)
	_add_rect("CryoDoorTempPanel", _door_panel_position(direction, center), Vector2(34, 16), Color(0.09, 0.13, 0.135, 0.92), 26)


func _add_sealed_cryo_wall_segment(direction: String, center: Vector2, size: Vector2, background_key: String, palette: Dictionary) -> void:
	var wall_color := palette["wall_inner"] as Color
	var rim_color := palette["wall_rim"] as Color
	if direction in ["up", "down"]:
		var segment_size := Vector2(size.x + 86, 76)
		_add_rect("CryoSealedInsulatedWallFill", center, segment_size, wall_color, 24)
		for x_offset in [-96, -32, 32, 96]:
			_add_atlas_tile("CryoSealedTopBottomWallAtlas", LAND_PIXELS_WALLS, CRYO_WALL_INSULATED_REGION, center + Vector2(x_offset, 0), Vector2(62, 58), Color(0.55, 0.68, 0.7, 0.5), 25)
		if background_key in ["cryo_storage_room", "cryo_sample_warehouse"]:
			_add_cryo_wall_storage_locker(center + Vector2(-92, 0), direction, palette, Vector2(42, 44))
			_add_cryo_wall_storage_locker(center + Vector2(92, 0), direction, palette, Vector2(42, 44))
		else:
			_add_cryo_wall_vent(center + Vector2(-86, 0), direction, palette, Vector2(74, 20))
			_add_cryo_wall_pipe(center + Vector2(86, 0), direction, palette, Vector2(74, 20))
	else:
		var segment_size := Vector2(86, size.y + 112)
		_add_rect("CryoSealedSideWallFill", center, segment_size, wall_color, 24)
		for y_offset in [-122, -70, -18, 34, 86, 138]:
			_add_atlas_tile("CryoSealedSideWallAtlas", LAND_PIXELS_WALLS, CRYO_WALL_INSULATED_REGION, center + Vector2(0, y_offset), Vector2(52, 46), Color(0.55, 0.68, 0.7, 0.48), 25)
		var rim_x := 28.0 if direction == "left" else -28.0
		_add_rect("CryoSealedSideWallColdRimTop", center + Vector2(rim_x, -104), Vector2(10, 72), rim_color, 26)
		_add_rect("CryoSealedSideWallColdRimBottom", center + Vector2(rim_x, 104), Vector2(10, 72), rim_color, 26)
		if direction == "left":
			_add_cryo_wall_pipe(center + Vector2(22, -104), direction, palette, Vector2(28, 62))
			_add_cryo_wall_pipe(center + Vector2(22, 104), direction, palette, Vector2(28, 62))
		else:
			_add_cryo_wall_storage_locker(center + Vector2(-20, -104), direction, palette, Vector2(38, 58))
			_add_cryo_wall_storage_locker(center + Vector2(-20, 104), direction, palette, Vector2(38, 58))
	_add_patch("CryoSealedWallFrostEdge", center + (Vector2(0, 30) if direction == "up" else Vector2(0, -30) if direction == "down" else Vector2(34, 0) if direction == "left" else Vector2(-34, 0)), size * 0.32, palette["frost"] as Color, 27)


func _door_panel_position(direction: String, center: Vector2) -> Vector2:
	match direction:
		"up":
			return center + Vector2(72, 18)
		"down":
			return center + Vector2(-72, -18)
		"left":
			return center + Vector2(18, -72)
		"right":
			return center + Vector2(-18, 72)
	return center


func _build_low_temp_labels(background_key: String, palette: Dictionary) -> void:
	var color: Color = palette["coolant_bright"] as Color
	_add_label("CryoLabelNorth", "LOW TEMP", Vector2(468, 132), color, 8)
	_add_label("CryoLabelSouth", "-80C", Vector2(500, 458), Color(color.r, color.g, color.b, 0.42), 8)
	match background_key:
		"cryo_storage_room":
			_add_label("CryoStorageLabel", "STORAGE", Vector2(160, 146), color, 8)
			_add_label("CryoStorageLabel", "CRYO", Vector2(790, 146), color, 8)
		"cryo_pipe_room":
			_add_label("CryoPipeLabel", "COOLANT", Vector2(470, 144), color, 8)
		"cryo_sample_warehouse":
			_add_label("CryoSampleLabel", "FREEZER UNIT", Vector2(442, 430), color, 8)


func _build_cryo_equipment(background_key: String, palette: Dictionary) -> void:
	for spec in _equipment_specs(background_key):
		var kind := String(spec.get("kind", "unit"))
		var position: Vector2 = spec.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = spec.get("size", Vector2(80, 40)) as Vector2
		match kind:
			"pod":
				_add_cryo_pod(position, size, palette)
			"cabinet":
				_add_sample_cabinet(position, size, palette)
			"terminal":
				_add_temperature_terminal(position, size, palette)
			"pipe_bank":
				_add_pipe_bank(position, size, palette)
			"freezer_unit":
				_add_freezer_unit(position, size, palette)
			_:
				_add_freezer_unit(position, size, palette)


func _equipment_specs(background_key: String) -> Array[Dictionary]:
	match background_key:
		"cryo_control_room":
			return [
				{"kind": "terminal", "position": Vector2(512, 168), "size": Vector2(150, 58)},
				{"kind": "freezer_unit", "position": Vector2(214, 226), "size": Vector2(126, 54)},
				{"kind": "freezer_unit", "position": Vector2(810, 374), "size": Vector2(126, 54)},
			]
		"cryo_storage_room":
			return [
				{"kind": "pod", "position": Vector2(180, 224), "size": Vector2(74, 112)},
				{"kind": "pod", "position": Vector2(180, 376), "size": Vector2(74, 112)},
				{"kind": "pod", "position": Vector2(844, 224), "size": Vector2(74, 112)},
				{"kind": "pod", "position": Vector2(844, 376), "size": Vector2(74, 112)},
				{"kind": "terminal", "position": Vector2(512, 140), "size": Vector2(130, 44)},
			]
		"cryo_pipe_room":
			return [
				{"kind": "pipe_bank", "position": Vector2(512, 132), "size": Vector2(610, 42)},
				{"kind": "pipe_bank", "position": Vector2(512, 468), "size": Vector2(610, 42)},
				{"kind": "freezer_unit", "position": Vector2(220, 226), "size": Vector2(120, 46)},
				{"kind": "freezer_unit", "position": Vector2(804, 374), "size": Vector2(120, 46)},
			]
		"cryo_sample_warehouse":
			return [
				{"kind": "cabinet", "position": Vector2(190, 232), "size": Vector2(108, 92)},
				{"kind": "cabinet", "position": Vector2(190, 374), "size": Vector2(108, 92)},
				{"kind": "cabinet", "position": Vector2(834, 232), "size": Vector2(108, 92)},
				{"kind": "cabinet", "position": Vector2(834, 374), "size": Vector2(108, 92)},
				{"kind": "terminal", "position": Vector2(512, 132), "size": Vector2(126, 42)},
			]
		"cryo_boss_room":
			return [
				{"kind": "freezer_unit", "position": Vector2(512, 124), "size": Vector2(320, 50)},
				{"kind": "pipe_bank", "position": Vector2(512, 476), "size": Vector2(360, 44)},
				{"kind": "freezer_unit", "position": Vector2(180, 172), "size": Vector2(120, 50)},
				{"kind": "freezer_unit", "position": Vector2(844, 428), "size": Vector2(120, 50)},
			]
	return [
		{"kind": "freezer_unit", "position": Vector2(210, 206), "size": Vector2(126, 52)},
		{"kind": "freezer_unit", "position": Vector2(814, 394), "size": Vector2(126, 52)},
		{"kind": "terminal", "position": Vector2(512, 132), "size": Vector2(130, 42)},
	]


func _add_cryo_pod(center: Vector2, size: Vector2, palette: Dictionary) -> void:
	var body := Color(0.045, 0.075, 0.082, 0.86)
	var glass := Color(0.48, 0.86, 1.0, 0.42)
	var frost: Color = palette["frost_strong"] as Color
	_add_rect("CryoPodBase", center + Vector2(0, size.y * 0.42), Vector2(size.x * 1.12, 18), Color(0.02, 0.04, 0.05, 0.74), 28)
	_add_rect("CryoPodBody", center, size, body, 28)
	_add_rect("CryoPodGlass", center + Vector2(0, -size.y * 0.08), Vector2(size.x * 0.62, size.y * 0.66), glass, 29)
	_add_line("CryoPodHighlight", PackedVector2Array([
		center + Vector2(-size.x * 0.2, -size.y * 0.36),
		center + Vector2(size.x * 0.18, -size.y * 0.36),
	]), Color(0.82, 0.96, 1.0, 0.22), 1.4, 30)
	_add_patch("CryoPodFrostEdge", center + Vector2(0, size.y * 0.18), Vector2(size.x * 0.9, 24), frost, 30)
	_add_rect("CryoPodTemperaturePanel", center + Vector2(size.x * 0.26, -size.y * 0.22), Vector2(10, 24), Color(0.66, 0.9, 0.96, 0.28), 30)


func _add_sample_cabinet(center: Vector2, size: Vector2, palette: Dictionary) -> void:
	_add_rect("CryoSampleCabinet", center, size, Color(0.055, 0.08, 0.09, 0.86), 27)
	_add_rect("CryoSampleCabinetGlass", center + Vector2(0, -size.y * 0.08), size * Vector2(0.76, 0.52), Color(0.5, 0.86, 1.0, 0.28), 28)
	_add_line("CryoSampleCabinetRack", PackedVector2Array([
		center + Vector2(-size.x * 0.36, 0),
		center + Vector2(size.x * 0.36, 0),
	]), Color(0.62, 0.82, 0.86, 0.16), 1.1, 29)
	_add_label("CryoSampleCabinetLabel", "CRYO", center + Vector2(-22, size.y * 0.3), palette["coolant_bright"] as Color, 7)


func _add_temperature_terminal(center: Vector2, size: Vector2, palette: Dictionary) -> void:
	_add_rect("CryoTemperatureTerminal", center, size, Color(0.04, 0.07, 0.08, 0.86), 28)
	_add_rect("CryoTemperatureScreen", center + Vector2(0, -size.y * 0.05), size * Vector2(0.64, 0.42), Color(0.24, 0.75, 0.92, 0.36), 29)
	_add_line("CryoTerminalStatusLine", PackedVector2Array([
		center + Vector2(-size.x * 0.24, -size.y * 0.06),
		center + Vector2(size.x * 0.24, -size.y * 0.06),
	]), Color(0.72, 0.9, 0.94, 0.22), 1.4, 30)
	_add_label("CryoTerminalLabel", "-80C", center + Vector2(-18, size.y * 0.22), palette["coolant_bright"] as Color, 7)


func _add_pipe_bank(center: Vector2, size: Vector2, palette: Dictionary) -> void:
	_add_rect("CryoPipeBankShadow", center, size, Color(0.02, 0.04, 0.05, 0.66), 25)
	var coolant: Color = palette["coolant"] as Color
	for offset in [-12, 0, 12]:
		_add_line("CryoPipeBankLine", PackedVector2Array([
			center + Vector2(-size.x * 0.45, offset),
			center + Vector2(size.x * 0.45, offset),
		]), Color(coolant.r, coolant.g, coolant.b, 0.18), 1.5, 27)


func _add_freezer_unit(center: Vector2, size: Vector2, palette: Dictionary) -> void:
	_add_rect("CryoFreezerUnit", center, size, Color(0.045, 0.075, 0.085, 0.82), 27)
	_add_rect("CryoFreezerUnitPanel", center + Vector2(0, -size.y * 0.22), size * Vector2(0.7, 0.18), Color(0.1, 0.18, 0.19, 0.72), 28)
	_add_line("CryoFreezerUnitColdLight", PackedVector2Array([
		center + Vector2(-size.x * 0.3, -size.y * 0.22),
		center + Vector2(size.x * 0.3, -size.y * 0.22),
	]), Color(0.72, 0.9, 0.94, 0.2), 1.4, 29)
	_add_patch("CryoFreezerUnitFrost", center + Vector2(0, size.y * 0.36), Vector2(size.x * 0.86, 22), palette["frost"] as Color, 29)


func _build_cryo_floor_decals(background_key: String, palette: Dictionary) -> void:
	var frost: Color = palette["frost"] as Color
	var strong: Color = palette["frost_strong"] as Color
	for patch in _frost_patch_specs(background_key):
		var position: Vector2 = patch.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = patch.get("size", Vector2(90, 40)) as Vector2
		var alpha := float(patch.get("alpha", frost.a))
		_add_patch("CryoFrostPatch", position, size, Color(frost.r, frost.g, frost.b, alpha), 7)
	for crack in _ice_crack_specs(background_key):
		_add_line("CryoIceCrack", PackedVector2Array(crack), Color(0.8, 0.94, 0.98, 0.22), 1.0, 8)
	for spot in _condensation_specs(background_key):
		var position: Vector2 = spot.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = spot.get("size", Vector2(54, 18)) as Vector2
		_add_patch("CryoCondensation", position, size, Color(strong.r, strong.g, strong.b, 0.14), 6)


func _frost_patch_specs(background_key: String) -> Array[Dictionary]:
	var specs: Array[Dictionary] = [
		{"position": Vector2(150, 150), "size": Vector2(120, 42), "alpha": 0.24},
		{"position": Vector2(870, 450), "size": Vector2(124, 46), "alpha": 0.24},
		{"position": Vector2(512, 482), "size": Vector2(184, 32), "alpha": 0.16},
	]
	match background_key:
		"cryo_storage_room":
			specs.append_array([
				{"position": Vector2(180, 292), "size": Vector2(128, 72), "alpha": 0.3},
				{"position": Vector2(844, 292), "size": Vector2(128, 72), "alpha": 0.3},
			])
		"cryo_pipe_room":
			specs.append_array([
				{"position": Vector2(512, 136), "size": Vector2(420, 38), "alpha": 0.24},
				{"position": Vector2(512, 464), "size": Vector2(420, 38), "alpha": 0.24},
			])
		"cryo_boss_room":
			specs.append_array([
				{"position": ROOM_CENTER, "size": Vector2(260, 104), "alpha": 0.18},
				{"position": Vector2(512, 130), "size": Vector2(310, 44), "alpha": 0.22},
			])
	return specs


func _ice_crack_specs(background_key: String) -> Array[Array]:
	var cracks: Array[Array] = [
		[Vector2(312, 154), Vector2(344, 168), Vector2(360, 196), Vector2(390, 204)],
		[Vector2(680, 420), Vector2(710, 402), Vector2(740, 410), Vector2(770, 386)],
		[Vector2(472, 238), Vector2(486, 266), Vector2(516, 274), Vector2(532, 300)],
	]
	if background_key == "cryo_pipe_room":
		cracks.append([Vector2(224, 384), Vector2(278, 354), Vector2(322, 360), Vector2(368, 330)])
	if background_key == "cryo_boss_room":
		cracks.append([Vector2(420, 300), Vector2(470, 282), Vector2(512, 300), Vector2(562, 278), Vector2(618, 300)])
	return cracks


func _condensation_specs(background_key: String) -> Array[Dictionary]:
	var specs: Array[Dictionary] = [
		{"position": Vector2(260, 430), "size": Vector2(92, 28)},
		{"position": Vector2(742, 174), "size": Vector2(86, 26)},
	]
	if background_key in ["cryo_storage_room", "cryo_sample_warehouse"]:
		specs.append_array([
			{"position": Vector2(184, 440), "size": Vector2(110, 32)},
			{"position": Vector2(840, 440), "size": Vector2(110, 32)},
		])
	return specs


func _build_cryo_mist_effects(background_key: String, palette: Dictionary) -> void:
	for spec in _mist_specs(background_key):
		var kind := String(spec.get("kind", "ground"))
		var position: Vector2 = spec.get("position", Vector2.ZERO) as Vector2
		match kind:
			"ground":
				var size: Vector2 = spec.get("size", Vector2(520, 92)) as Vector2
				var drift: Vector2 = spec.get("drift", Vector2(18, -2)) as Vector2
				var alpha := float(spec.get("alpha", 0.1))
				var seconds := float(spec.get("seconds", 10.0))
				_add_cryo_floor_fog_layer(position, size, alpha, drift, seconds)
			"vent", "pod", "pipe":
				var direction: Vector2 = spec.get("direction", Vector2.DOWN) as Vector2
				var group := String(spec.get("group", "smoke_middle_gray"))
				var smoke := String(spec.get("smoke", "smoke9"))
				var alpha := float(spec.get("alpha", 0.22))
				var scale_value: Vector2 = spec.get("scale", Vector2(0.75, 0.75)) as Vector2
				var speed := float(spec.get("speed", 0.55))
				var intermittent := bool(spec.get("intermittent", false))
				var active := float(spec.get("active", 2.4))
				var pause := float(spec.get("pause", 2.8))
				_add_cryo_smoke_vent(position, direction, group, smoke, alpha, scale_value, speed, intermittent, active, pause)


func _mist_specs(background_key: String) -> Array[Dictionary]:
	match background_key:
		"cryo_control_room":
			return [
				{"kind": "ground", "position": Vector2(512, 414), "size": Vector2(650, 118), "alpha": 0.16, "drift": Vector2(24, -2), "seconds": 13.0},
				{"kind": "vent", "position": Vector2(214, 250), "direction": Vector2(0.2, 1), "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.32, "scale": Vector2(0.68, 0.48), "speed": 0.48},
				{"kind": "vent", "position": Vector2(810, 400), "direction": Vector2(-0.2, 1), "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.32, "scale": Vector2(0.68, 0.48), "speed": 0.5},
				{"kind": "vent", "position": Vector2(512, 142), "direction": Vector2.DOWN, "group": "smoke_bright_gray", "smoke": "smoke9", "alpha": 0.3, "scale": Vector2(0.64, 0.44), "speed": 0.44, "intermittent": true, "active": 2.2, "pause": 2.6},
			]
		"cryo_storage_room":
			return [
				{"kind": "ground", "position": Vector2(512, 424), "size": Vector2(620, 110), "alpha": 0.17, "drift": Vector2(18, -2), "seconds": 13.0},
				{"kind": "pod", "position": Vector2(180, 286), "direction": Vector2.DOWN, "group": "smoke_bright_gray", "smoke": "smoke10", "alpha": 0.36, "scale": Vector2(0.62, 0.46), "speed": 0.46},
				{"kind": "pod", "position": Vector2(180, 438), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.34, "scale": Vector2(0.62, 0.46), "speed": 0.44},
				{"kind": "pod", "position": Vector2(844, 286), "direction": Vector2.DOWN, "group": "smoke_bright_gray", "smoke": "smoke10", "alpha": 0.36, "scale": Vector2(0.62, 0.46), "speed": 0.48},
				{"kind": "pod", "position": Vector2(844, 438), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.34, "scale": Vector2(0.62, 0.46), "speed": 0.44},
			]
		"cryo_pipe_room":
			return [
				{"kind": "ground", "position": Vector2(512, 408), "size": Vector2(650, 108), "alpha": 0.15, "drift": Vector2(-20, -2), "seconds": 12.0},
				{"kind": "pipe", "position": Vector2(330, 150), "direction": Vector2(1, 0.12), "group": "smoke_bright_gray", "smoke": "smoke9", "alpha": 0.34, "scale": Vector2(0.58, 0.38), "speed": 0.42, "intermittent": true, "active": 2.2, "pause": 2.4},
				{"kind": "pipe", "position": Vector2(702, 450), "direction": Vector2(-1, -0.08), "group": "smoke_middle_gray", "smoke": "smoke9", "alpha": 0.36, "scale": Vector2(0.58, 0.38), "speed": 0.46, "intermittent": true, "active": 2.2, "pause": 2.6},
				{"kind": "vent", "position": Vector2(210, 142), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.34, "scale": Vector2(0.66, 0.44), "speed": 0.48, "intermittent": true, "active": 2.2, "pause": 2.8},
				{"kind": "vent", "position": Vector2(812, 458), "direction": Vector2.UP, "group": "smoke_bright_gray", "smoke": "smoke10", "alpha": 0.32, "scale": Vector2(0.66, 0.44), "speed": 0.46, "intermittent": true, "active": 2.0, "pause": 2.6},
			]
		"cryo_sample_warehouse":
			return [
				{"kind": "ground", "position": Vector2(512, 420), "size": Vector2(700, 116), "alpha": 0.16, "drift": Vector2(18, -2), "seconds": 12.0},
				{"kind": "pod", "position": Vector2(190, 282), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.32, "scale": Vector2(0.6, 0.42), "speed": 0.46},
				{"kind": "pod", "position": Vector2(190, 424), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke9", "alpha": 0.3, "scale": Vector2(0.58, 0.4), "speed": 0.44},
				{"kind": "pod", "position": Vector2(834, 282), "direction": Vector2.DOWN, "group": "smoke_bright_gray", "smoke": "smoke10", "alpha": 0.32, "scale": Vector2(0.6, 0.42), "speed": 0.48},
				{"kind": "pod", "position": Vector2(834, 424), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke9", "alpha": 0.3, "scale": Vector2(0.58, 0.4), "speed": 0.44},
			]
		"cryo_boss_room":
			return [
				{"kind": "ground", "position": Vector2(512, 420), "size": Vector2(760, 140), "alpha": 0.16, "drift": Vector2(22, -2), "seconds": 13.0},
				{"kind": "vent", "position": Vector2(320, 142), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.34, "scale": Vector2(0.68, 0.46), "speed": 0.46, "intermittent": true, "active": 2.2, "pause": 2.8},
				{"kind": "vent", "position": Vector2(704, 458), "direction": Vector2.UP, "group": "smoke_bright_gray", "smoke": "smoke10", "alpha": 0.34, "scale": Vector2(0.68, 0.46), "speed": 0.48, "intermittent": true, "active": 2.0, "pause": 2.6},
				{"kind": "pipe", "position": Vector2(176, 224), "direction": Vector2.RIGHT, "group": "smoke_middle_gray", "smoke": "smoke9", "alpha": 0.32, "scale": Vector2(0.58, 0.38), "speed": 0.44},
				{"kind": "pipe", "position": Vector2(848, 376), "direction": Vector2.LEFT, "group": "smoke_middle_gray", "smoke": "smoke9", "alpha": 0.32, "scale": Vector2(0.58, 0.38), "speed": 0.44},
				{"kind": "pod", "position": Vector2(512, 150), "direction": Vector2.DOWN, "group": "smoke_bright_gray", "smoke": "smoke10", "alpha": 0.36, "scale": Vector2(0.62, 0.42), "speed": 0.46},
			]
	return [
		{"kind": "ground", "position": Vector2(512, 412), "size": Vector2(650, 112), "alpha": 0.15, "drift": Vector2(18, -2), "seconds": 12.0},
		{"kind": "vent", "position": Vector2(210, 232), "direction": Vector2.DOWN, "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.3, "scale": Vector2(0.6, 0.44), "speed": 0.46},
		{"kind": "vent", "position": Vector2(814, 420), "direction": Vector2.UP, "group": "smoke_middle_gray", "smoke": "smoke10", "alpha": 0.3, "scale": Vector2(0.6, 0.44), "speed": 0.46},
		{"kind": "pipe", "position": Vector2(872, 256), "direction": Vector2.LEFT, "group": "smoke_bright_gray", "smoke": "smoke9", "alpha": 0.28, "scale": Vector2(0.52, 0.34), "speed": 0.42, "intermittent": true, "active": 2.0, "pause": 2.6},
	]


func _add_cryo_floor_fog_layer(position: Vector2, size: Vector2, alpha: float, drift: Vector2, seconds: float) -> void:
	var fog := CRYO_FLOOR_FOG_SCENE.instantiate() as CryoFloorFogLayer
	fog.name = "CryoFloorFogLayer"
	fog.position = position
	fog.z_as_relative = false
	fog.z_index = BACKGROUND_VISUAL_Z
	fog.configure(size, alpha, drift, Color(0.88, 0.96, 1.0, 1.0), seconds)
	add_child(fog)


func _add_cryo_smoke_vent(position: Vector2, direction: Vector2, group: String, smoke: String, alpha: float, scale_value: Vector2, speed: float, intermittent: bool, active: float, pause: float) -> void:
	var vent := CRYO_SMOKE_VENT_SCENE.instantiate() as CryoSmokeVent
	vent.name = "CryoSmokeVent"
	vent.position = position
	vent.rotation = direction.angle()
	vent.z_as_relative = false
	vent.z_index = BACKGROUND_VISUAL_Z
	vent.configure(group, smoke, alpha, scale_value, speed, Color(0.92, 0.98, 1.0, 1.0), intermittent, active, pause)
	add_child(vent)


func _add_atlas_tile(node_name: String, texture: Texture2D, region: Rect2, center: Vector2, target_size: Vector2, tint: Color, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = true
	sprite.position = center
	sprite.z_as_relative = false
	sprite.z_index = BACKGROUND_VISUAL_Z
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var region_size := region.size
	if region_size.x > 0.0 and region_size.y > 0.0:
		sprite.scale = Vector2(target_size.x / region_size.x, target_size.y / region_size.y)
	add_child(sprite)
	return sprite


func _add_rect(node_name: String, center: Vector2, size: Vector2, color: Color, z: int) -> Polygon2D:
	var half := size * 0.5
	var rect := Polygon2D.new()
	rect.name = node_name
	rect.color = color
	rect.z_as_relative = false
	rect.z_index = BACKGROUND_VISUAL_Z
	rect.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(rect)
	return rect


func _add_patch(node_name: String, center: Vector2, size: Vector2, color: Color, z: int) -> Polygon2D:
	var patch := Polygon2D.new()
	patch.name = node_name
	patch.color = color
	patch.z_as_relative = false
	patch.z_index = BACKGROUND_VISUAL_Z
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
	return patch


func _add_line(node_name: String, points: PackedVector2Array, color: Color, width: float, z: int) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.z_as_relative = false
	line.z_index = BACKGROUND_VISUAL_Z
	line.width = width
	line.default_color = color
	line.points = points
	add_child(line)
	return line


func _add_ring(node_name: String, center: Vector2, radius: float, color: Color, width: float, z: int, segments: int = 48) -> Line2D:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return _add_line(node_name, points, color, width, z)


func _add_wall_panel(position: Vector2, text: String, color: Color, z: int) -> void:
	_add_rect("CryoWallStatusPanel", position, Vector2(88, 22), Color(0.035, 0.065, 0.07, 0.72), z)
	_add_label("CryoWallStatusLabel", text, position + Vector2(-34, -8), color, 7)


func _add_label(node_name: String, text: String, position: Vector2, color: Color, size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = position
	label.z_as_relative = false
	label.z_index = BACKGROUND_VISUAL_Z
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
