class_name ChapterDoorTheme
extends RefCounted


const STATE_NORMAL := "normal"
const STATE_COMBAT_LOCKED := "combat_locked"
const STATE_EVENT_LOCKED := "event_locked"
const STATE_SUPPLY := "supply"
const STATE_BOSS := "boss"

const CHAPTER_FINAL_ID := 99

const LAB_STUFF: Texture2D = preload("res://tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png")
const LAB_WALLS: Texture2D = preload("res://tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesWalls.png")
const GREENHOUSE_TILES: Texture2D = preload("res://tiny_wizard/assets/third_party/mars_greenhouse/tilesets_32x32.png")
const ROBOT_FACTORY_PAGE_01: Texture2D = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png")
const CYBERPUNK_DOORS: Texture2D = preload("res://tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_DOORS.png")
const CYBERPUNK_WALLS: Texture2D = preload("res://tiny_wizard/assets/third_party/cyberpunk_interiors_16x16/Cyberpunk_Interiors_Walls.png")
const SCI_FI_PORTAL: Texture2D = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/portal_spritesheet.png")

const LAB_BLUE_DOOR := Rect2(0, 96, 176, 96)
const LAB_RED_DOOR := Rect2(0, 224, 176, 96)
const LAB_PANEL_DOOR := Rect2(352, 256, 96, 64)
const LAB_SEALED_WALL := Rect2(0, 0, 128, 128)
const LAB_LOCKER_WALL := Rect2(256, 96, 96, 96)

const GREENHOUSE_GLASS_DOOR := Rect2(384, 32, 128, 128)
const GREENHOUSE_CONTROL_DOOR := Rect2(512, 32, 96, 128)
const GREENHOUSE_SEALED_WALL := Rect2(640, 32, 128, 128)

const FACTORY_STANDARD_GATE := Rect2(544, 384, 128, 112)
const FACTORY_HEAVY_GATE := Rect2(288, 352, 160, 128)
const FACTORY_SUPPLY_GATE := Rect2(96, 448, 128, 96)
const FACTORY_SEALED_WALL := Rect2(384, 0, 224, 160)

const DATA_DOOR_BLUE := Rect2(0, 0, 16, 64)
const DATA_DOOR_DARK := Rect2(16, 0, 16, 64)
const DATA_DOOR_ORANGE := Rect2(32, 0, 16, 64)
const DATA_DOOR_BROKEN := Rect2(48, 0, 16, 64)
const DATA_SEALED_WALL := Rect2(0, 0, 64, 64)
const PORTAL_STATUS := Rect2(0, 0, 16, 16)


static func get_theme(chapter_id: int) -> Dictionary:
	match chapter_id:
		2:
			return _greenhouse_theme()
		3:
			return _cryo_theme()
		4:
			return _factory_theme()
		5:
			return _data_core_theme()
		CHAPTER_FINAL_ID:
			return _final_hive_theme()
		_:
			return _lab_theme()


static func resolve_door_state(room: Node) -> String:
	if room == null:
		return STATE_NORMAL

	var room_type := str(room.get("lab_room_type"))
	if room_type in ["merchant", "tutorial_merchant"]:
		return STATE_SUPPLY
	if room_type == "boss":
		return STATE_BOSS
	if bool(room.get("is_cleared")):
		return STATE_NORMAL
	if room_type in ["weapon", "reward"]:
		if _room_has_enemies(room):
			return STATE_COMBAT_LOCKED
		return STATE_SUPPLY

	var objective_type := ""
	if room.has_method("get_room_objective_type"):
		objective_type = str(room.call("get_room_objective_type"))
	if objective_type in [
		"DESTROY_TARGETS",
		"INTERACT_TARGETS",
		"READ_ARCHIVE",
		"CHOOSE_REWARD",
	]:
		return STATE_EVENT_LOCKED
	if room_type in [
		"pollution",
		"data_comm",
		"data_comm_control",
		"cryo_pod",
		"cryo_vent",
		"archive",
		"final_core_interference",
		"final_signal",
	]:
		return STATE_EVENT_LOCKED
	if _room_has_enemies(room):
		return STATE_COMBAT_LOCKED
	if room.has_method("has_pending_room_event_objectives") and bool(room.call("has_pending_room_event_objectives")):
		return STATE_EVENT_LOCKED
	return STATE_NORMAL


static func get_state_asset_key(state: String) -> String:
	if state == STATE_COMBAT_LOCKED:
		return "combat_locked_door"
	if state == STATE_EVENT_LOCKED:
		return "event_locked_door"
	if state == STATE_SUPPLY:
		return "supply_door"
	if state == STATE_BOSS:
		return "boss_door"
	return "normal_door"


static func _room_has_enemies(room: Node) -> bool:
	if room.has_method("get_remaining_enemy_count"):
		return int(room.call("get_remaining_enemy_count")) > 0
	if room.has_node("Enemies"):
		return room.get_node("Enemies").get_child_count() > 0
	return false


static func _lab_theme() -> Dictionary:
	return {
		"name": "chapter1_lab_door_theme",
		"chapter_label": "第一章：标准实验室气密门",
		"normal_door": _door("chapter1_lab_door_normal", LAB_STUFF, LAB_BLUE_DOOR, Color(0.72, 0.9, 1.0, 0.98), Color(0.34, 0.78, 1.0, 0.95)),
		"combat_locked_door": _door("chapter1_lab_door_combat_locked", LAB_STUFF, LAB_RED_DOOR, Color(1.0, 0.78, 0.74, 0.98), Color(1.0, 0.22, 0.16, 0.95), true),
		"event_locked_door": _door("chapter1_lab_door_event_locked", LAB_STUFF, LAB_PANEL_DOOR, Color(0.76, 0.88, 1.0, 0.98), Color(0.95, 0.62, 0.18, 0.95), true),
		"supply_door": _door("chapter1_lab_door_supply", LAB_STUFF, LAB_BLUE_DOOR, Color(0.82, 0.96, 1.0, 0.98), Color(0.2, 0.92, 0.78, 0.95)),
		"boss_door": _door("chapter1_lab_door_boss", LAB_STUFF, LAB_RED_DOOR, Color(0.92, 0.84, 0.82, 1.0), Color(1.0, 0.16, 0.12, 0.98), true, 1.18),
		"sealed_wall": _sealed("chapter1_lab_sealed_wall", LAB_WALLS, LAB_SEALED_WALL, Color(0.50, 0.50, 0.68, 1.0)),
	}


static func _greenhouse_theme() -> Dictionary:
	return {
		"name": "chapter2_greenhouse_door_theme",
		"chapter_label": "第二章：生态温室隔离门",
		"normal_door": _door("chapter2_greenhouse_door_normal", GREENHOUSE_TILES, GREENHOUSE_GLASS_DOOR, Color(0.82, 1.0, 0.84, 0.98), Color(0.28, 0.92, 0.38, 0.95)),
		"combat_locked_door": _door("chapter2_greenhouse_door_combat_locked", GREENHOUSE_TILES, GREENHOUSE_CONTROL_DOOR, Color(1.0, 0.82, 0.78, 0.98), Color(1.0, 0.24, 0.14, 0.95), true),
		"event_locked_door": _door("chapter2_greenhouse_door_event_locked", GREENHOUSE_TILES, GREENHOUSE_CONTROL_DOOR, Color(0.86, 1.0, 0.82, 0.98), Color(0.95, 0.72, 0.18, 0.95), true),
		"supply_door": _door("chapter2_greenhouse_door_supply", GREENHOUSE_TILES, GREENHOUSE_GLASS_DOOR, Color(0.92, 1.0, 0.88, 0.98), Color(0.35, 1.0, 0.58, 0.95)),
		"boss_door": _door("chapter2_greenhouse_door_boss", GREENHOUSE_TILES, GREENHOUSE_CONTROL_DOOR, Color(0.78, 0.95, 0.76, 1.0), Color(1.0, 0.18, 0.12, 0.98), true, 1.18),
		"sealed_wall": _sealed("chapter2_greenhouse_sealed_wall", GREENHOUSE_TILES, GREENHOUSE_SEALED_WALL, Color(0.62, 0.88, 0.64, 1.0), false, true),
	}


static func _cryo_theme() -> Dictionary:
	return {
		"name": "chapter3_cryo_door_theme",
		"chapter_label": "第三章：低温封存隔热门",
		"normal_door": _door("chapter3_cryo_door_normal", LAB_STUFF, LAB_BLUE_DOOR, Color(0.78, 0.94, 1.0, 0.98), Color(0.56, 0.92, 1.0, 0.95)),
		"combat_locked_door": _door("chapter3_cryo_door_combat_locked", LAB_STUFF, LAB_RED_DOOR, Color(0.92, 0.96, 1.0, 0.98), Color(0.94, 0.18, 0.14, 0.95), true),
		"event_locked_door": _door("chapter3_cryo_door_event_locked", LAB_STUFF, LAB_BLUE_DOOR, Color(0.76, 0.94, 1.0, 0.98), Color(0.96, 0.68, 0.18, 0.95), true),
		"supply_door": _door("chapter3_cryo_door_supply", LAB_STUFF, LAB_BLUE_DOOR, Color(0.88, 0.98, 1.0, 0.98), Color(0.62, 1.0, 0.96, 0.95)),
		"boss_door": _door("chapter3_cryo_door_boss", LAB_STUFF, LAB_RED_DOOR, Color(0.84, 0.94, 1.0, 1.0), Color(0.98, 0.16, 0.12, 0.98), true, 1.18),
		"sealed_wall": _sealed("chapter3_cryo_sealed_wall", LAB_WALLS, LAB_LOCKER_WALL, Color(0.56, 0.70, 0.76, 1.0)),
	}


static func _factory_theme() -> Dictionary:
	return {
		"name": "chapter4_factory_door_theme",
		"chapter_label": "第四章：外骨骼工厂重型闸门",
		"normal_door": _door("chapter4_factory_door_normal", ROBOT_FACTORY_PAGE_01, FACTORY_STANDARD_GATE, Color(0.82, 0.73, 0.64, 0.98), Color(0.92, 0.58, 0.22, 0.95)),
		"combat_locked_door": _door("chapter4_factory_door_combat_locked", ROBOT_FACTORY_PAGE_01, FACTORY_HEAVY_GATE, Color(0.94, 0.68, 0.52, 0.98), Color(1.0, 0.18, 0.12, 0.95), true),
		"event_locked_door": _door("chapter4_factory_door_event_locked", ROBOT_FACTORY_PAGE_01, FACTORY_STANDARD_GATE, Color(0.88, 0.76, 0.64, 0.98), Color(1.0, 0.68, 0.18, 0.95), true),
		"supply_door": _door("chapter4_factory_door_supply", ROBOT_FACTORY_PAGE_01, FACTORY_SUPPLY_GATE, Color(0.9, 0.78, 0.62, 0.98), Color(0.35, 0.95, 0.92, 0.95)),
		"boss_door": _door("chapter4_factory_door_boss", ROBOT_FACTORY_PAGE_01, FACTORY_HEAVY_GATE, Color(0.86, 0.68, 0.54, 1.0), Color(1.0, 0.14, 0.08, 0.98), true, 1.22),
		"sealed_wall": _sealed("chapter4_factory_sealed_wall", ROBOT_FACTORY_PAGE_01, FACTORY_SEALED_WALL, Color(0.72, 0.62, 0.52, 1.0)),
	}


static func _data_core_theme() -> Dictionary:
	return {
		"name": "chapter5_data_door_theme",
		"chapter_label": "第五章：数据中枢高权限电子门",
		"normal_door": _door("chapter5_data_door_normal", CYBERPUNK_DOORS, DATA_DOOR_BLUE, Color(0.68, 0.9, 1.0, 0.98), Color(0.22, 0.9, 1.0, 0.95)),
		"combat_locked_door": _door("chapter5_data_door_combat_locked", CYBERPUNK_DOORS, DATA_DOOR_ORANGE, Color(1.0, 0.76, 0.58, 0.98), Color(1.0, 0.18, 0.12, 0.95), true),
		"event_locked_door": _door("chapter5_data_door_event_locked", CYBERPUNK_DOORS, DATA_DOOR_DARK, Color(0.72, 0.9, 1.0, 0.98), Color(0.95, 0.62, 0.18, 0.95), true),
		"supply_door": _door("chapter5_data_door_supply", CYBERPUNK_DOORS, DATA_DOOR_BLUE, Color(0.8, 0.98, 1.0, 0.98), Color(0.2, 1.0, 0.9, 0.95)),
		"boss_door": _door("chapter5_data_door_boss", CYBERPUNK_DOORS, DATA_DOOR_ORANGE, Color(1.0, 0.78, 0.62, 1.0), Color(1.0, 0.16, 0.10, 0.98), true, 1.2),
		"sealed_wall": _sealed("chapter5_data_sealed_wall", CYBERPUNK_WALLS, DATA_SEALED_WALL, Color(0.34, 0.52, 0.66, 1.0)),
	}


static func _final_hive_theme() -> Dictionary:
	return {
		"name": "final_hive_door_theme",
		"chapter_label": "最终章：母巢侵蚀核心门",
		"normal_door": _door("final_hive_door_normal", CYBERPUNK_DOORS, DATA_DOOR_BROKEN, Color(0.74, 0.72, 0.86, 0.98), Color(0.48, 0.28, 0.72, 0.95), false, 1.05, true),
		"combat_locked_door": _door("final_hive_door_combat_locked", CYBERPUNK_DOORS, DATA_DOOR_ORANGE, Color(0.82, 0.58, 0.76, 0.98), Color(0.9, 0.12, 0.10, 0.95), true, 1.08, true),
		"event_locked_door": _door("final_hive_door_event_locked", CYBERPUNK_DOORS, DATA_DOOR_DARK, Color(0.7, 0.56, 0.86, 0.98), Color(0.88, 0.3, 0.92, 0.95), true, 1.05, true),
		"supply_door": _door("final_hive_door_supply", CYBERPUNK_DOORS, DATA_DOOR_BLUE, Color(0.72, 0.8, 0.92, 0.98), Color(0.34, 0.9, 0.88, 0.95), false, 1.02, true),
		"boss_door": _door("final_hive_door_boss", CYBERPUNK_DOORS, DATA_DOOR_ORANGE, Color(0.86, 0.48, 0.68, 1.0), Color(1.0, 0.10, 0.08, 0.98), true, 1.28, true),
		"sealed_wall": _sealed("final_hive_sealed_wall", CYBERPUNK_WALLS, DATA_SEALED_WALL, Color(0.32, 0.25, 0.42, 1.0), true),
	}


static func _door(
	asset_name: String,
	texture: Texture2D,
	region: Rect2,
	tint: Color,
	status_color: Color,
	locked := false,
	scale_multiplier := 1.0,
	corrupted := false
) -> Dictionary:
	return {
		"asset_name": asset_name,
		"texture": texture,
		"region": region,
		"tint": tint,
		"status_texture": SCI_FI_PORTAL,
		"status_region": PORTAL_STATUS,
		"status_color": status_color,
		"locked": locked,
		"scale_multiplier": scale_multiplier,
		"corrupted": corrupted,
	}


static func _sealed(asset_name: String, texture: Texture2D, region: Rect2, tint: Color, corrupted := false, suppress_visual := false) -> Dictionary:
	return {
		"asset_name": asset_name,
		"texture": texture,
		"region": region,
		"tint": tint,
		"corrupted": corrupted,
		"suppress_visual": suppress_visual,
	}
