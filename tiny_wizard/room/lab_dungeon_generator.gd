class_name LabDungeonGenerator
extends RefCounted


const TUTORIAL_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_start_room.tscn")
const START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_formal_start_room.tscn")
const TUTORIAL_TARGET_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_tutorial_target_room.tscn")
const TUTORIAL_RAVEN_SAFEHOUSE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_tutorial_raven_safehouse_room.tscn")
const TUTORIAL_COMBAT_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_tutorial_combat_room.tscn")
const TUTORIAL_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_tutorial_boss_room.tscn")
const COMBAT_ROOM_A_SCENE := preload("res://tiny_wizard/room/room_types/room_1.tscn")
const COMBAT_ROOM_B_SCENE := preload("res://tiny_wizard/room/room_types/room_2.tscn")
const REWARD_ROOM_A_SCENE := preload("res://tiny_wizard/room/room_types/lab_reward_bomb_room.tscn")
const REWARD_ROOM_B_SCENE := preload("res://tiny_wizard/room/room_types/lab_reward_guarded_room.tscn")
const WEAPON_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/room_4.tscn")
const RAVEN_SAFEHOUSE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_raven_safehouse_room.tscn")
const CHAPTER_BASE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_chapter_base_room.tscn")
const BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_boss_room.tscn")
const GREENHOUSE_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_start_room.tscn")
const GREENHOUSE_COMBAT_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_combat_room.tscn")
const GREENHOUSE_SPORE_EVENT_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_spore_event_room.tscn")
const GREENHOUSE_REWARD_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_reward_room.tscn")
const GREENHOUSE_WEAPON_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_weapon_room.tscn")
const GREENHOUSE_MERCHANT_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_merchant_room.tscn")
const GREENHOUSE_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_greenhouse_boss_room.tscn")
const CRYO_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_start_room.tscn")
const CRYO_COMBAT_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_combat_room.tscn")
const CRYO_POD_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_pod_room.tscn")
const CRYO_VENT_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_vent_room.tscn")
const CRYO_REWARD_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_reward_room.tscn")
const CRYO_ELITE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_elite_room.tscn")
const CRYO_BOSS_ANTECHAMBER_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_boss_antechamber.tscn")
const CRYO_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_cryo_boss_room.tscn")
const EXOSUIT_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_start_room.tscn")
const EXOSUIT_ASSEMBLY_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_assembly_room.tscn")
const EXOSUIT_DRONE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_drone_room.tscn")
const EXOSUIT_TEST_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_test_room.tscn")
const EXOSUIT_WEAPON_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_weapon_room.tscn")
const EXOSUIT_ELITE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_elite_room.tscn")
const EXOSUIT_ARMORY_STATION_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_armory_station_room.tscn")
const EXOSUIT_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_boss_room.tscn")
const DATA_CORE_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_start_room.tscn")
const DATA_CORE_SERVER_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_server_room.tscn")
const DATA_CORE_COMM_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_comm_room.tscn")
const DATA_CORE_SATELLITE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_satellite_room.tscn")
const DATA_CORE_ARCHIVE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_archive_room.tscn")
const DATA_CORE_SUPPLY_STATION_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_supply_station_room.tscn")
const DATA_CORE_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_boss_room.tscn")
const FORMAL_ENCOUNTER_GENERATOR := preload("res://tiny_wizard/room/formal_encounter_generator.gd")

const START_ROOM_OFFSET := Vector2(0, 200)
const DEFAULT_CHAPTER_ID := 1
const MAIN_PATH_ROOM_COUNT := 6
const REWARD_ROOM_COUNT := 2
const MAX_LAYOUT_ATTEMPTS := 80
const LAYOUT_RADIUS := 3

const DIRECTIONS := [
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.UP,
]

const COMBAT_ROOM_SCENES := [
	COMBAT_ROOM_A_SCENE,
	COMBAT_ROOM_B_SCENE,
	preload("res://tiny_wizard/room/room_types/room_7.tscn"),
	preload("res://tiny_wizard/room/room_types/room_8.tscn"),
	preload("res://tiny_wizard/room/room_types/room_9.tscn"),
]

const GREENHOUSE_COMBAT_ROOM_SCENES := [
	GREENHOUSE_COMBAT_ROOM_SCENE,
	GREENHOUSE_COMBAT_ROOM_SCENE,
	GREENHOUSE_COMBAT_ROOM_SCENE,
	GREENHOUSE_COMBAT_ROOM_SCENE,
	GREENHOUSE_COMBAT_ROOM_SCENE,
]

const CRYO_COMBAT_ROOM_SCENES := [
	CRYO_COMBAT_ROOM_SCENE,
	CRYO_COMBAT_ROOM_SCENE,
	CRYO_VENT_ROOM_SCENE,
]

const EXOSUIT_COMBAT_ROOM_SCENES := [
	EXOSUIT_ASSEMBLY_ROOM_SCENE,
	EXOSUIT_DRONE_ROOM_SCENE,
]

const DATA_CORE_COMBAT_ROOM_SCENES := [
	DATA_CORE_SERVER_ROOM_SCENE,
	DATA_CORE_SERVER_ROOM_SCENE,
]

const DATA_CORE_EVENT_ROOM_SCENES := [
	DATA_CORE_COMM_ROOM_SCENE,
	DATA_CORE_SATELLITE_ROOM_SCENE,
]

const REWARD_ROOM_SCENES := [
	REWARD_ROOM_A_SCENE,
	REWARD_ROOM_B_SCENE,
]

const WEAPON_ROOM_SCENES := [
	WEAPON_ROOM_SCENE,
]

const BOSS_ROOM_SCENES := [
	BOSS_ROOM_SCENE,
]

const FALLBACK_ROOM_LAYOUT := [
	{
		"coord": Vector2i(0, 0),
		"type": "start",
		"label": "封存气闸",
		"scene": START_ROOM_SCENE,
	},
	{
		"coord": Vector2i(1, 0),
		"type": "combat",
		"label": "封存样本间 1",
		"scene": COMBAT_ROOM_A_SCENE,
		"depth": 1,
	},
	{
		"coord": Vector2i(2, 0),
		"type": "combat",
		"label": "封存样本间 2",
		"scene": COMBAT_ROOM_B_SCENE,
		"depth": 2,
	},
	{
		"coord": Vector2i(3, 0),
		"type": "weapon",
		"label": "渡鸦军械缓存",
		"scene": WEAPON_ROOM_SCENE,
	},
	{
		"coord": Vector2i(3, 1),
		"type": "merchant",
		"label": "渡鸦检疫商店",
		"scene": RAVEN_SAFEHOUSE_ROOM_SCENE,
	},
	{
		"coord": Vector2i(3, 2),
		"type": "boss",
		"label": "A-03 回收室",
		"scene": BOSS_ROOM_SCENE,
	},
	{
		"coord": Vector2i(1, -1),
		"type": "reward",
		"label": "证物库 1",
		"scene": REWARD_ROOM_A_SCENE,
	},
	{
		"coord": Vector2i(2, -1),
		"type": "reward",
		"label": "证物库 2",
		"scene": REWARD_ROOM_B_SCENE,
	},
]

const TUTORIAL_ROOM_LAYOUT := [
	{
		"coord": Vector2i(0, 0),
		"type": "tutorial_start",
		"label": "封存协议唤醒区",
		"scene": TUTORIAL_START_ROOM_SCENE,
	},
	{
		"coord": Vector2i(1, 0),
		"type": "tutorial_targets",
		"label": "靶场同步室",
		"scene": TUTORIAL_TARGET_ROOM_SCENE,
	},
	{
		"coord": Vector2i(2, 0),
		"type": "tutorial_merchant",
		"label": "渡鸦军械附属间",
		"scene": TUTORIAL_RAVEN_SAFEHOUSE_ROOM_SCENE,
	},
	{
		"coord": Vector2i(3, 0),
		"type": "tutorial_combat",
		"label": "破障训练实验室",
		"scene": TUTORIAL_COMBAT_ROOM_SCENE,
	},
	{
		"coord": Vector2i(4, 0),
		"type": "tutorial_boss",
		"label": "A-03 回收室",
		"scene": TUTORIAL_BOSS_ROOM_SCENE,
	},
]

static var last_seed := 0


static func generate(rooms_parent: Node2D, requested_seed := 0, chapter_id := DEFAULT_CHAPTER_ID, layer_index := 1) -> Dictionary:
	_clear_existing_rooms(rooms_parent)

	var rng := RandomNumberGenerator.new()
	last_seed = _resolve_seed(requested_seed)
	rng.seed = last_seed

	var chapter_config := get_chapter_config(chapter_id)
	var room_layout := _generate_random_layout(rng, chapter_config, layer_index)
	var generated_rooms := {}
	for spec in room_layout:
		var room := _instantiate_room(spec)
		if str(spec["type"]) in ["combat", "cryo_vent"]:
			FORMAL_ENCOUNTER_GENERATOR.populate(room, rng, int(spec.get("depth", 1)))
		rooms_parent.add_child(room)
		generated_rooms[room.room_pos] = room

	return generated_rooms


static func get_chapter_config(chapter_id: int) -> Dictionary:
	match chapter_id:
		1:
			return {
				"id": 1,
				"title": "第一章：极渊前哨基地",
				"sector": "极渊前哨基地",
				"planned_minutes": "6-8",
				"formal_layer_count": 2,
				"main_path_room_count": 6,
				"reward_room_count": 2,
				"layout_radius": 3,
				"main_room_types": ["combat", "combat", "weapon"],
				"start_label": "前哨气闸",
				"combat_label_prefix": "前哨样本间",
				"reward_label_prefix": "前哨证物库",
				"weapon_label": "渡鸦前哨军械缓存",
				"merchant_label": "渡鸦前哨补给站",
				"boss_label": "前哨回收室",
				"boss_objective": "击败前哨失格样本，稳定下行裂隙。",
				"completion_destination": "临时安全屋 / 渡鸦据点",
				"next_chapter_id": 2,
				"next_chapter_title": "第二章：生态温室",
				"chapter_boss_layer": 2,
				"combat_room_scenes": COMBAT_ROOM_SCENES,
				"reward_room_scenes": REWARD_ROOM_SCENES,
				"weapon_room_scenes": WEAPON_ROOM_SCENES,
				"merchant_room_scenes": [RAVEN_SAFEHOUSE_ROOM_SCENE],
				"boss_room_scenes": BOSS_ROOM_SCENES,
			}
		2:
			return {
				"id": 2,
				"title": "第二章：生态温室",
				"sector": "生态温室",
				"planned_minutes": "7-10",
				"formal_layer_count": 1,
				"main_path_room_count": 7,
				"reward_room_count": 2,
				"layout_radius": 4,
				"main_room_types": ["combat", "combat", "pollution", "weapon"],
				"start_label": "温室检疫入口",
				"combat_label_prefix": "孢子培养廊",
				"pollution_label": "虫巢样本间",
				"reward_label_prefix": "温室样本库",
				"weapon_label": "渡鸦温室军械缓存",
				"merchant_label": "渡鸦温室补给站",
				"boss_label": "温室守望者培育舱",
				"boss_objective": "压制温室守望者，记录孢子与虫巢反应。",
				"completion_destination": "临时安全屋 / 渡鸦据点",
				"next_chapter_id": 3,
				"next_chapter_title": "第三章：低温封存区",
				"start_room_scene": GREENHOUSE_START_ROOM_SCENE,
				"combat_room_scenes": GREENHOUSE_COMBAT_ROOM_SCENES,
				"pollution_room_scenes": [GREENHOUSE_SPORE_EVENT_ROOM_SCENE],
				"reward_room_scenes": [GREENHOUSE_REWARD_ROOM_SCENE, GREENHOUSE_REWARD_ROOM_SCENE],
				"weapon_room_scenes": [GREENHOUSE_WEAPON_ROOM_SCENE],
				"merchant_room_scenes": [GREENHOUSE_MERCHANT_ROOM_SCENE],
				"boss_room_scenes": [GREENHOUSE_BOSS_ROOM_SCENE],
			}
		3:
			return {
				"id": 3,
				"title": "第三章：低温封存区",
				"sector": "低温封存区",
				"planned_minutes": "8-12",
				"formal_layer_count": 1,
				"main_path_room_count": 8,
				"reward_room_count": 2,
				"layout_radius": 4,
				"main_room_types": ["combat", "cryo_pod", "cryo_vent", "elite", "combat"],
				"start_label": "低温检疫闸",
				"combat_label_prefix": "冷雾处理间",
				"cryo_pod_label": "冷冻舱列阵",
				"cryo_vent_label": "冷却通风廊",
				"elite_label": "冰核守卫间",
				"reward_label_prefix": "封存样本库",
				"merchant_label": "低温封存前厅",
				"boss_label": "零号封存室",
				"boss_objective": "击败零号封存体，回收封存区黑匣子碎片。",
				"completion_destination": "兵器工厂访问权限",
				"next_chapter_id": 4,
				"next_chapter_title": "第四章：外骨骼兵器工厂",
				"start_room_scene": CRYO_START_ROOM_SCENE,
				"combat_room_scenes": CRYO_COMBAT_ROOM_SCENES,
				"cryo_pod_room_scenes": [CRYO_POD_ROOM_SCENE],
				"cryo_vent_room_scenes": [CRYO_VENT_ROOM_SCENE],
				"elite_room_scenes": [CRYO_ELITE_ROOM_SCENE],
				"reward_room_scenes": [CRYO_REWARD_ROOM_SCENE, CRYO_REWARD_ROOM_SCENE],
				"merchant_room_scenes": [CRYO_BOSS_ANTECHAMBER_SCENE],
				"boss_room_scenes": [CRYO_BOSS_ROOM_SCENE],
			}
		4:
			return {
				"id": 4,
				"title": "第四章：外骨骼兵器工厂",
				"sector": "外骨骼兵器工厂",
				"planned_minutes": "约 5",
				"formal_layer_count": 1,
				"main_path_room_count": 8,
				"reward_room_count": 1,
				"layout_radius": 4,
				"main_room_types": ["combat", "pollution", "combat", "weapon", "elite"],
				"start_label": "兵器工厂入口",
				"combat_labels": ["自动化装配线", "无人机装配线"],
				"pollution_label": "外骨骼测试场",
				"reward_label_prefix": "工厂补给缓存",
				"weapon_label": "武器质检室",
				"elite_label": "安保机甲仓库",
				"merchant_label": "渡鸦军械补给站",
				"boss_label": "重装清理机停放库",
				"boss_objective": "击败弥赛亚重装清理机。",
				"completion_destination": "数据中枢访问权限",
				"next_chapter_id": 5,
				"next_chapter_title": "第五章：数据中枢",
				"start_room_scene": EXOSUIT_START_ROOM_SCENE,
				"combat_room_scenes": EXOSUIT_COMBAT_ROOM_SCENES,
				"pollution_room_scenes": [EXOSUIT_TEST_ROOM_SCENE],
				"reward_room_scenes": [REWARD_ROOM_A_SCENE, REWARD_ROOM_B_SCENE],
				"weapon_room_scenes": [EXOSUIT_WEAPON_ROOM_SCENE],
				"elite_room_scenes": [EXOSUIT_ELITE_ROOM_SCENE],
				"merchant_room_scenes": [EXOSUIT_ARMORY_STATION_ROOM_SCENE],
				"boss_room_scenes": [EXOSUIT_BOSS_ROOM_SCENE],
			}
		5:
			return {
				"id": 5,
				"title": "第五章：数据中枢",
				"sector": "数据中枢",
				"planned_minutes": "约 6",
				"formal_layer_count": 1,
				"main_path_room_count": 7,
				"reward_room_count": 0,
				"layout_radius": 4,
				"main_room_types": ["combat", "data_comm", "data_satellite", "archive"],
				"start_label": "数据中枢入口",
				"combat_label_prefix": "服务器机房",
				"data_comm_label": "通讯塔控制室",
				"data_satellite_label": "卫星伪装系统",
				"archive_label": "公司黑匣子档案库",
				"merchant_label": "渡鸦数据补给站",
				"boss_label": "清理协议AI核心室",
				"boss_objective": "击败清理协议AI。",
				"completion_destination": "第六章：深层熵区，后续版本开放",
				"next_chapter_id": 0,
				"next_chapter_title": "第六章：深层熵区",
				"start_room_scene": DATA_CORE_START_ROOM_SCENE,
				"combat_room_scenes": DATA_CORE_COMBAT_ROOM_SCENES,
				"data_comm_room_scenes": [DATA_CORE_COMM_ROOM_SCENE],
				"data_satellite_room_scenes": [DATA_CORE_SATELLITE_ROOM_SCENE],
				"archive_room_scenes": [DATA_CORE_ARCHIVE_ROOM_SCENE],
				"reward_room_scenes": [],
				"weapon_room_scenes": [],
				"merchant_room_scenes": [DATA_CORE_SUPPLY_STATION_ROOM_SCENE],
				"boss_room_scenes": [DATA_CORE_BOSS_ROOM_SCENE],
			}
	return get_chapter_config(DEFAULT_CHAPTER_ID)


static func get_chapter_title(chapter_id: int) -> String:
	return str(get_chapter_config(chapter_id).get("title", "第一章：封存协议"))


static func get_chapter_sector_label(chapter_id: int) -> String:
	return str(get_chapter_config(chapter_id).get("sector", "封存区"))


static func get_chapter_planned_minutes(chapter_id: int) -> String:
	return str(get_chapter_config(chapter_id).get("planned_minutes", "4-5"))


static func get_chapter_layer_count(chapter_id: int) -> int:
	return maxi(1, int(get_chapter_config(chapter_id).get("formal_layer_count", 1)))


static func get_chapter_boss_objective(chapter_id: int) -> String:
	return str(get_chapter_config(chapter_id).get("boss_objective", "击败当前章节 Boss，稳定下行裂隙。"))


static func get_chapter_completion_destination(chapter_id: int) -> String:
	return str(get_chapter_config(chapter_id).get("completion_destination", "后续章节：下一版本开放"))


static func get_next_chapter_id(chapter_id: int) -> int:
	return int(get_chapter_config(chapter_id).get("next_chapter_id", 0))


static func generate_tutorial(rooms_parent: Node2D) -> Dictionary:
	_clear_existing_rooms(rooms_parent)

	var generated_rooms := {}
	for spec in TUTORIAL_ROOM_LAYOUT:
		var room := _instantiate_room(spec)
		rooms_parent.add_child(room)
		generated_rooms[room.room_pos] = room

	return generated_rooms


static func generate_chapter_base(rooms_parent: Node2D, completed_chapter_id := DEFAULT_CHAPTER_ID) -> Dictionary:
	_clear_existing_rooms(rooms_parent)

	var completed_config := get_chapter_config(completed_chapter_id)
	var next_chapter_id := get_next_chapter_id(completed_chapter_id)
	var next_chapter_title := get_chapter_title(next_chapter_id) if next_chapter_id > 0 else "后续章节"
	var spec := {
		"coord": Vector2i.ZERO,
		"type": "base",
		"label": "临时安全屋 / 渡鸦据点",
		"scene": CHAPTER_BASE_ROOM_SCENE,
		"chapter_id": 0,
		"chapter_title": "临时安全屋 / 渡鸦据点",
		"chapter_sector": "章节间基地",
		"planned_minutes": "2-3",
		"completed_chapter_id": completed_chapter_id,
		"next_chapter_id": next_chapter_id,
		"completed_chapter_title": str(completed_config.get("title", "")),
		"next_chapter_title": next_chapter_title,
	}
	var room := _instantiate_room(spec)
	room.set_meta("completed_chapter_id", completed_chapter_id)
	room.set_meta("next_chapter_id", next_chapter_id)
	room.set_meta("completed_chapter_title", str(spec.get("completed_chapter_title", "")))
	room.set_meta("next_chapter_title", next_chapter_title)
	rooms_parent.add_child(room)
	return {
		room.room_pos: room,
	}


static func _clear_existing_rooms(rooms_parent: Node2D) -> void:
	for child in rooms_parent.get_children():
		rooms_parent.remove_child(child)
		child.queue_free()


static func _instantiate_room(spec: Dictionary) -> Room:
	var room := (spec["scene"] as PackedScene).instantiate() as Room
	var coord := spec["coord"] as Vector2i
	room.name = _room_name(spec)
	room.room_pos = coord
	room.lab_room_type = spec["type"]
	room.lab_room_label = spec["label"]
	room.set_meta("chapter_id", int(spec.get("chapter_id", DEFAULT_CHAPTER_ID)))
	room.set_meta("chapter_title", str(spec.get("chapter_title", "")))
	room.set_meta("chapter_sector", str(spec.get("chapter_sector", "")))
	room.set_meta("planned_minutes", str(spec.get("planned_minutes", "")))
	room.position = START_ROOM_OFFSET + Vector2(coord.x, coord.y) * Room.ROOM_SIZE
	return room


static func _room_name(spec: Dictionary) -> String:
	var coord := spec["coord"] as Vector2i
	var label := spec["label"] as String
	return "%s_%d_%d" % [label.replace(" ", ""), coord.x, coord.y]


static func _resolve_seed(requested_seed: int) -> int:
	if requested_seed != 0:
		return requested_seed

	var seed_rng := RandomNumberGenerator.new()
	seed_rng.randomize()
	return int(seed_rng.randi())


static func _generate_random_layout(rng: RandomNumberGenerator, chapter_config: Dictionary, layer_index: int) -> Array:
	var main_path_room_count := maxi(4, int(chapter_config.get("main_path_room_count", MAIN_PATH_ROOM_COUNT)))
	var reward_room_count := maxi(0, int(chapter_config.get("reward_room_count", REWARD_ROOM_COUNT)))
	var layout_radius := maxi(2, int(chapter_config.get("layout_radius", LAYOUT_RADIUS)))

	for attempt in range(MAX_LAYOUT_ATTEMPTS):
		var main_path := _build_main_path(rng, main_path_room_count, layout_radius)
		if main_path.is_empty():
			continue

		var reward_coords := _build_reward_branches(main_path, rng, reward_room_count, layout_radius)
		if reward_coords.size() != reward_room_count:
			continue
		if not _has_isolated_pre_boss_room(main_path, reward_coords):
			continue

		return _build_room_specs(main_path, reward_coords, rng, chapter_config, layer_index)

	push_warning("Random dungeon layout failed; using fallback layout.")
	return FALLBACK_ROOM_LAYOUT


static func _build_main_path(rng: RandomNumberGenerator, room_count: int, layout_radius: int) -> Array:
	var path := [Vector2i.ZERO]
	var occupied := {
		Vector2i.ZERO: true,
	}

	while path.size() < room_count:
		var current := path[path.size() - 1] as Vector2i
		var candidates := []
		for direction: Vector2i in DIRECTIONS:
			var next_coord := current + direction
			if occupied.has(next_coord):
				continue
			if _is_outside_layout_bounds(next_coord, layout_radius):
				continue
			candidates.append(next_coord)

		if candidates.is_empty():
			return []

		var chosen := candidates[rng.randi_range(0, candidates.size() - 1)] as Vector2i
		path.append(chosen)
		occupied[chosen] = true

	return path


static func _build_reward_branches(main_path: Array, rng: RandomNumberGenerator, reward_room_count: int, layout_radius: int) -> Array:
	var occupied := {}
	for coord in main_path:
		occupied[coord] = true

	var reward_coords := []
	while reward_coords.size() < reward_room_count:
		var candidates := []
		for path_index in range(1, main_path.size() - 2):
			var attach_coord := main_path[path_index] as Vector2i
			for direction: Vector2i in DIRECTIONS:
				var branch_coord := attach_coord + direction
				if occupied.has(branch_coord):
					continue
				if _is_outside_layout_bounds(branch_coord, layout_radius):
					continue
				candidates.append(branch_coord)

		if candidates.is_empty():
			return []

		var chosen := candidates[rng.randi_range(0, candidates.size() - 1)] as Vector2i
		reward_coords.append(chosen)
		occupied[chosen] = true

	return reward_coords


static func _build_room_specs(main_path: Array, reward_coords: Array, rng: RandomNumberGenerator, chapter_config: Dictionary, layer_index: int) -> Array:
	var room_specs := []
	var label_counts := {}
	var scene_pools := _build_scene_pools(chapter_config)
	var flexible_main_types := (chapter_config.get("main_room_types", ["combat", "combat", "weapon"]) as Array).duplicate()
	var required_flexible_count := maxi(0, main_path.size() - 3)
	while flexible_main_types.size() < required_flexible_count:
		flexible_main_types.append("combat")
	var main_room_types := flexible_main_types.slice(0, required_flexible_count)
	_shuffle_array(main_room_types, rng)
	main_room_types.append("merchant")
	main_room_types.append("boss")

	room_specs.append(_make_spec(
		Vector2i.ZERO,
		"start",
		str(chapter_config.get("start_label", "封存气闸")),
		chapter_config.get("start_room_scene", START_ROOM_SCENE) as PackedScene,
		0,
		chapter_config,
		layer_index
	))

	for path_index in range(1, main_path.size()):
		var room_type := main_room_types[path_index - 1] as String
		var coord := main_path[path_index] as Vector2i
		var scene := _take_scene(scene_pools, room_type, rng)
		room_specs.append(_make_spec(coord, room_type, _next_label(room_type, label_counts, chapter_config), scene, path_index, chapter_config, layer_index))

	for coord in reward_coords:
		var scene := _take_scene(scene_pools, "reward", rng)
		room_specs.append(_make_spec(coord as Vector2i, "reward", _next_label("reward", label_counts, chapter_config), scene, 0, chapter_config, layer_index))

	return room_specs


static func _has_isolated_pre_boss_room(main_path: Array, reward_coords: Array) -> bool:
	if main_path.size() < 3:
		return false

	var boss_coord := main_path[main_path.size() - 1] as Vector2i
	var merchant_coord := main_path[main_path.size() - 2] as Vector2i
	var previous_coord := main_path[main_path.size() - 3] as Vector2i
	if not _are_adjacent(merchant_coord, boss_coord):
		return false
	if not _are_adjacent(previous_coord, merchant_coord):
		return false

	var room_coords := []
	room_coords.append_array(main_path)
	room_coords.append_array(reward_coords)

	for coord_value in room_coords:
		var coord := coord_value as Vector2i
		if coord == boss_coord or coord == merchant_coord:
			continue
		if _are_adjacent(coord, boss_coord):
			return false
		if coord != previous_coord and _are_adjacent(coord, merchant_coord):
			return false

	return true


static func _build_scene_pools(chapter_config: Dictionary) -> Dictionary:
	return {
		"combat": (chapter_config.get("combat_room_scenes", COMBAT_ROOM_SCENES) as Array).duplicate(),
		"pollution": (chapter_config.get("pollution_room_scenes", [COMBAT_ROOM_A_SCENE]) as Array).duplicate(),
		"data_comm": (chapter_config.get("data_comm_room_scenes", [DATA_CORE_COMM_ROOM_SCENE]) as Array).duplicate(),
		"data_satellite": (chapter_config.get("data_satellite_room_scenes", [DATA_CORE_SATELLITE_ROOM_SCENE]) as Array).duplicate(),
		"cryo_pod": (chapter_config.get("cryo_pod_room_scenes", [CRYO_POD_ROOM_SCENE]) as Array).duplicate(),
		"cryo_vent": (chapter_config.get("cryo_vent_room_scenes", [CRYO_VENT_ROOM_SCENE]) as Array).duplicate(),
		"elite": (chapter_config.get("elite_room_scenes", [CRYO_ELITE_ROOM_SCENE]) as Array).duplicate(),
		"archive": (chapter_config.get("archive_room_scenes", [RAVEN_SAFEHOUSE_ROOM_SCENE]) as Array).duplicate(),
		"reward": (chapter_config.get("reward_room_scenes", REWARD_ROOM_SCENES) as Array).duplicate(),
		"weapon": (chapter_config.get("weapon_room_scenes", WEAPON_ROOM_SCENES) as Array).duplicate(),
		"merchant": (chapter_config.get("merchant_room_scenes", [RAVEN_SAFEHOUSE_ROOM_SCENE]) as Array).duplicate(),
		"boss": (chapter_config.get("boss_room_scenes", BOSS_ROOM_SCENES) as Array).duplicate(),
	}


static func _take_scene(scene_pools: Dictionary, room_type: String, rng: RandomNumberGenerator) -> PackedScene:
	var scenes := scene_pools[room_type] as Array
	if scenes.is_empty():
		scenes = _default_scene_pool(room_type).duplicate()
		scene_pools[room_type] = scenes

	var scene_index := rng.randi_range(0, scenes.size() - 1)
	return scenes.pop_at(scene_index) as PackedScene


static func _default_scene_pool(room_type: String) -> Array:
	match room_type:
		"combat":
			return COMBAT_ROOM_SCENES
		"pollution":
			return [COMBAT_ROOM_A_SCENE]
		"data_comm":
			return [DATA_CORE_COMM_ROOM_SCENE]
		"data_satellite":
			return [DATA_CORE_SATELLITE_ROOM_SCENE]
		"cryo_pod":
			return [CRYO_POD_ROOM_SCENE]
		"cryo_vent":
			return [CRYO_VENT_ROOM_SCENE]
		"elite":
			return [CRYO_ELITE_ROOM_SCENE]
		"archive":
			return [RAVEN_SAFEHOUSE_ROOM_SCENE]
		"reward":
			return REWARD_ROOM_SCENES
		"weapon":
			return WEAPON_ROOM_SCENES
		"merchant":
			return [RAVEN_SAFEHOUSE_ROOM_SCENE]
		"boss":
			return BOSS_ROOM_SCENES
	return COMBAT_ROOM_SCENES


static func _make_spec(coord: Vector2i, room_type: String, label: String, scene: PackedScene, depth := 0, chapter_config := {}, layer_index := 1) -> Dictionary:
	return {
		"coord": coord,
		"type": room_type,
		"label": label,
		"scene": scene,
		"depth": depth,
		"chapter_id": int(chapter_config.get("id", DEFAULT_CHAPTER_ID)),
		"chapter_title": str(chapter_config.get("title", "")),
		"chapter_sector": str(chapter_config.get("sector", "")),
		"planned_minutes": str(chapter_config.get("planned_minutes", "")),
		"layer_index": layer_index,
	}


static func _next_label(room_type: String, label_counts: Dictionary, chapter_config: Dictionary) -> String:
	var count := int(label_counts.get(room_type, 0)) + 1
	label_counts[room_type] = count

	match room_type:
		"combat":
			var combat_labels := chapter_config.get("combat_labels", []) as Array
			if not combat_labels.is_empty():
				return str(combat_labels[(count - 1) % combat_labels.size()])
			return "%s %d" % [str(chapter_config.get("combat_label_prefix", "封存样本间")), count]
		"pollution":
			var pollution_labels := chapter_config.get("pollution_labels", []) as Array
			if not pollution_labels.is_empty():
				return str(pollution_labels[(count - 1) % pollution_labels.size()])
			return str(chapter_config.get("pollution_label", "污染事件房"))
		"data_comm":
			return str(chapter_config.get("data_comm_label", "通讯塔控制室"))
		"data_satellite":
			return str(chapter_config.get("data_satellite_label", "卫星伪装系统"))
		"cryo_pod":
			return str(chapter_config.get("cryo_pod_label", "冷冻舱列阵"))
		"cryo_vent":
			return str(chapter_config.get("cryo_vent_label", "冷却通风廊"))
		"elite":
			return str(chapter_config.get("elite_label", "精英封存室"))
		"archive":
			return str(chapter_config.get("archive_label", "档案库"))
		"reward":
			return "%s %d" % [str(chapter_config.get("reward_label_prefix", "证物库")), count]
		"weapon":
			return str(chapter_config.get("weapon_label", "渡鸦军械缓存"))
		"merchant":
			return str(chapter_config.get("merchant_label", "渡鸦检疫商店"))
		"boss":
			return str(chapter_config.get("boss_label", "A-03 回收室"))
	return "房间 %d" % count


static func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value


static func _is_outside_layout_bounds(coord: Vector2i, layout_radius := LAYOUT_RADIUS) -> bool:
	return abs(coord.x) > layout_radius or abs(coord.y) > layout_radius


static func _are_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1
