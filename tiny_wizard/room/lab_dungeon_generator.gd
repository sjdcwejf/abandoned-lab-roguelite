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
const REWARD_ROOM_A_SCENE := preload("res://tiny_wizard/room/room_types/lab_reward_supply_room.tscn")
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
const EXOSUIT_MAINTENANCE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_maintenance_room.tscn")
const EXOSUIT_TEST_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_test_room.tscn")
const EXOSUIT_POWER_CONTROL_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_power_control_room.tscn")
const EXOSUIT_WEAPON_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_weapon_room.tscn")
const EXOSUIT_ELITE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_elite_room.tscn")
const EXOSUIT_ARMORY_STATION_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_armory_station_room.tscn")
const EXOSUIT_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_exosuit_boss_room.tscn")
const DATA_CORE_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_start_room.tscn")
const DATA_CORE_SERVER_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_server_room.tscn")
const DATA_CORE_COMM_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_comm_room.tscn")
const DATA_CORE_COMM_CONTROL_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_comm_control_room.tscn")
const DATA_CORE_ARCHIVE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_archive_room.tscn")
const DATA_CORE_SUPPLY_STATION_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_supply_station_room.tscn")
const DATA_CORE_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_data_core_boss_room.tscn")
const MOTHER_HIVE_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_mother_hive_start_room.tscn")
const MOTHER_HIVE_TRANSITION_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_mother_hive_transition_room.tscn")
const MOTHER_HIVE_CORE_INTERFERENCE_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_mother_hive_core_interference_room.tscn")
const MOTHER_HIVE_SIGNAL_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_mother_hive_signal_room.tscn")
const MOTHER_HIVE_ANTECHAMBER_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_mother_hive_antechamber_room.tscn")
const MOTHER_HIVE_SUPPLY_STATION_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_mother_hive_supply_station_room.tscn")
const MOTHER_HIVE_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_mother_hive_boss_room.tscn")
const FORMAL_ENCOUNTER_GENERATOR := preload("res://tiny_wizard/room/formal_encounter_generator.gd")

const START_ROOM_OFFSET := Vector2(0, 200)
const DEFAULT_CHAPTER_ID := 1
const FINAL_CHAPTER_ID := 99
const MAIN_PATH_ROOM_COUNT := 6
const REWARD_ROOM_COUNT := 2
const MAX_LAYOUT_ATTEMPTS := 80
const LAYOUT_RADIUS := 3
const ROOM_ROLE_PRE_BOSS_SHOP := "PRE_BOSS_SHOP"

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
	EXOSUIT_MAINTENANCE_ROOM_SCENE,
]

const DATA_CORE_COMBAT_ROOM_SCENES := [
	DATA_CORE_SERVER_ROOM_SCENE,
	DATA_CORE_SERVER_ROOM_SCENE,
]

const DATA_CORE_EVENT_ROOM_SCENES := [
	DATA_CORE_COMM_ROOM_SCENE,
	DATA_CORE_COMM_CONTROL_ROOM_SCENE,
]

const MOTHER_HIVE_COMBAT_ROOM_SCENES := [
	MOTHER_HIVE_TRANSITION_ROOM_SCENE,
	MOTHER_HIVE_ANTECHAMBER_ROOM_SCENE,
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
		"label": "战斗补给训练室",
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
		if str(spec["type"]) in ["combat", "cryo_vent", "final_transition", "final_antechamber"]:
			FORMAL_ENCOUNTER_GENERATOR.populate(room, rng, int(spec.get("depth", 1)))
		rooms_parent.add_child(room)
		generated_rooms[room.room_pos] = room
	_validate_generated_rooms(generated_rooms, chapter_config, layer_index)

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
				"boss_objective": "击败零号封存体，解锁兵器工厂访问权限。",
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
				"combat_labels": ["自动化装配线", "无人机装配线", "机械维护车间"],
				"pollution_labels": ["外骨骼测试场", "动力控制室"],
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
				"pollution_room_scenes": [EXOSUIT_TEST_ROOM_SCENE, EXOSUIT_POWER_CONTROL_ROOM_SCENE],
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
				"main_room_types": ["combat", "data_comm", "data_comm_control", "archive"],
				"start_label": "数据中枢入口",
				"combat_label_prefix": "服务器机房",
				"data_comm_label": "通讯塔控制室",
				"data_comm_control_label": "通讯控制区",
				"archive_label": "数据封存区",
				"merchant_label": "渡鸦数据补给站",
				"boss_label": "清理协议AI核心室",
				"boss_objective": "击败清理协议AI。",
				"completion_destination": "最终区域已解锁",
				"next_chapter_id": FINAL_CHAPTER_ID,
				"next_chapter_title": "最终章：母巢核心",
				"start_room_scene": DATA_CORE_START_ROOM_SCENE,
				"combat_room_scenes": DATA_CORE_COMBAT_ROOM_SCENES,
				"data_comm_room_scenes": [DATA_CORE_COMM_ROOM_SCENE],
				"data_comm_control_room_scenes": [DATA_CORE_COMM_CONTROL_ROOM_SCENE],
				"archive_room_scenes": [DATA_CORE_ARCHIVE_ROOM_SCENE],
				"reward_room_scenes": [],
				"weapon_room_scenes": [],
				"merchant_room_scenes": [DATA_CORE_SUPPLY_STATION_ROOM_SCENE],
				"boss_room_scenes": [DATA_CORE_BOSS_ROOM_SCENE],
			}
		FINAL_CHAPTER_ID:
			return {
				"id": FINAL_CHAPTER_ID,
				"title": "最终章：母巢核心",
				"sector": "母巢核心",
				"planned_minutes": "8-10",
				"formal_layer_count": 1,
				"main_path_room_count": 8,
				"reward_room_count": 2,
				"layout_radius": 4,
				"main_room_types": ["final_transition", "final_core_interference", "final_signal", "final_antechamber", "final_transition"],
				"start_label": "母巢入口",
				"final_transition_label": "高危战斗区",
				"final_core_interference_label": "核心干扰室",
				"final_signal_label": "核心终端室",
				"final_antechamber_label": "Boss 前战斗区",
				"reward_label_prefix": "高危奖励房",
				"merchant_label": "补给站",
				"boss_label": "母巢核心",
				"boss_objective": "击败核心 Boss。",
				"completion_destination": "结局文本占位",
				"next_chapter_id": 0,
				"next_chapter_title": "主线已收束",
				"start_room_scene": MOTHER_HIVE_START_ROOM_SCENE,
				"combat_room_scenes": MOTHER_HIVE_COMBAT_ROOM_SCENES,
				"final_transition_room_scenes": [MOTHER_HIVE_TRANSITION_ROOM_SCENE],
				"final_core_interference_room_scenes": [MOTHER_HIVE_CORE_INTERFERENCE_ROOM_SCENE],
				"final_signal_room_scenes": [MOTHER_HIVE_SIGNAL_ROOM_SCENE],
				"final_antechamber_room_scenes": [MOTHER_HIVE_ANTECHAMBER_ROOM_SCENE],
				"reward_room_scenes": [MOTHER_HIVE_TRANSITION_ROOM_SCENE, MOTHER_HIVE_SIGNAL_ROOM_SCENE],
				"weapon_room_scenes": [],
				"merchant_room_scenes": [MOTHER_HIVE_SUPPLY_STATION_ROOM_SCENE],
				"boss_room_scenes": [MOTHER_HIVE_BOSS_ROOM_SCENE],
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
	room.set_meta("room_role", str(spec.get("room_role", "")))
	if room.has_method("set_room_objective"):
		room.call("set_room_objective", spec.get("objective", {}) as Dictionary)
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
	var last_failed_specs := []

	for attempt in range(MAX_LAYOUT_ATTEMPTS):
		var main_path := _build_main_path(rng, main_path_room_count, layout_radius)
		if main_path.is_empty():
			continue

		var reward_coords := _build_reward_branches(main_path, rng, reward_room_count, layout_radius)
		if reward_coords.size() != reward_room_count:
			continue
		if not _has_isolated_pre_boss_room(main_path, reward_coords):
			continue

		var specs := _build_room_specs(main_path, reward_coords, rng, chapter_config, layer_index)
		if _validate_room_specs(specs, chapter_config, layer_index, false):
			return specs
		last_failed_specs = specs

	push_warning("Random dungeon layout failed; using chapter-safe fallback layout.")
	if not last_failed_specs.is_empty():
		_validate_room_specs(last_failed_specs, chapter_config, layer_index, true)
	var fallback_specs := _build_safe_fallback_specs(rng, chapter_config, layer_index)
	_validate_room_specs(fallback_specs, chapter_config, layer_index, true)
	return fallback_specs


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
	var attempts := 0
	var max_attempts := maxi(80, reward_room_count * 80)
	while reward_coords.size() < reward_room_count and attempts < max_attempts:
		attempts += 1
		var candidates := _collect_loop_branch_candidates(main_path, occupied, main_path, layout_radius)

		if candidates.is_empty():
			return []

		var chosen: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)] as Vector2i
		reward_coords.append(chosen)
		occupied[chosen] = true

	return reward_coords


static func _collect_loop_branch_candidates(anchor_coords: Array, occupied: Dictionary, main_path: Array, layout_radius: int) -> Array:
	var candidates := []
	var seen := {}
	for anchor_value in anchor_coords:
		var attach_coord: Vector2i = anchor_value as Vector2i
		for direction: Vector2i in DIRECTIONS:
			var branch_coord := attach_coord + direction
			if seen.has(branch_coord):
				continue
			if occupied.has(branch_coord):
				continue
			if _is_outside_layout_bounds(branch_coord, layout_radius):
				continue
			if _touches_boss_without_being_merchant(branch_coord, main_path):
				continue
			if _count_adjacent_coords(branch_coord, occupied) < 2:
				continue
			seen[branch_coord] = true
			candidates.append(branch_coord)
	return candidates


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
		room_specs.append(_make_spec(coord, room_type, _label_for_scene(room_type, label_counts, chapter_config, scene), scene, path_index, chapter_config, layer_index))

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

	return true


static func _build_scene_pools(chapter_config: Dictionary) -> Dictionary:
	return {
		"combat": (chapter_config.get("combat_room_scenes", COMBAT_ROOM_SCENES) as Array).duplicate(),
		"pollution": (chapter_config.get("pollution_room_scenes", [COMBAT_ROOM_A_SCENE]) as Array).duplicate(),
		"data_comm": (chapter_config.get("data_comm_room_scenes", [DATA_CORE_COMM_ROOM_SCENE]) as Array).duplicate(),
		"data_comm_control": (chapter_config.get("data_comm_control_room_scenes", [DATA_CORE_COMM_CONTROL_ROOM_SCENE]) as Array).duplicate(),
		"final_transition": (chapter_config.get("final_transition_room_scenes", [MOTHER_HIVE_TRANSITION_ROOM_SCENE]) as Array).duplicate(),
		"final_core_interference": (chapter_config.get("final_core_interference_room_scenes", [MOTHER_HIVE_CORE_INTERFERENCE_ROOM_SCENE]) as Array).duplicate(),
		"final_signal": (chapter_config.get("final_signal_room_scenes", [MOTHER_HIVE_SIGNAL_ROOM_SCENE]) as Array).duplicate(),
		"final_antechamber": (chapter_config.get("final_antechamber_room_scenes", [MOTHER_HIVE_ANTECHAMBER_ROOM_SCENE]) as Array).duplicate(),
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
		"data_comm_control":
			return [DATA_CORE_COMM_CONTROL_ROOM_SCENE]
		"final_transition":
			return [MOTHER_HIVE_TRANSITION_ROOM_SCENE]
		"final_core_interference":
			return [MOTHER_HIVE_CORE_INTERFERENCE_ROOM_SCENE]
		"final_signal":
			return [MOTHER_HIVE_SIGNAL_ROOM_SCENE]
		"final_antechamber":
			return [MOTHER_HIVE_ANTECHAMBER_ROOM_SCENE]
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
		"room_role": ROOM_ROLE_PRE_BOSS_SHOP if room_type == "merchant" else "",
		"objective": _make_room_objective(room_type, label, chapter_config),
	}


static func _make_room_objective(room_type: String, label: String, chapter_config: Dictionary) -> Dictionary:
	var chapter_id := int(chapter_config.get("id", DEFAULT_CHAPTER_ID))
	match room_type:
		"start":
			return {
				"type": Room.OBJECTIVE_CLEAR_ENEMIES,
				"objective_text": _chapter_start_objective(chapter_id),
				"completion_text": "入口同步完成。",
			}
		"combat":
			return {
				"type": Room.OBJECTIVE_CLEAR_ENEMIES,
				"objective_text": _chapter_combat_objective(chapter_id, label),
				"completion_text": "封锁解除：异常单位已清除。",
			}
		"pollution":
			return _chapter_event_objective(chapter_id, label)
		"data_comm":
			return {
				"type": Room.OBJECTIVE_INTERACT_TARGETS,
				"objective_text": "重启通讯终端 0/3。",
				"target_label": "通讯终端",
				"target_total": 3,
				"completion_text": "封锁解除：通讯终端已重启。",
			}
		"data_comm_control":
			return {
				"type": Room.OBJECTIVE_INTERACT_TARGETS,
				"objective_text": "关闭控制节点 0/3。",
				"target_label": "控制节点",
				"target_total": 3,
				"completion_text": "封锁解除：控制节点已关闭。",
			}
		"final_transition":
			return {
				"type": Room.OBJECTIVE_CLEAR_ENEMIES,
				"objective_text": "清除房间内异常单位。",
				"completion_text": "封锁解除：异常单位已清除。",
			}
		"final_core_interference":
			return {
				"type": Room.OBJECTIVE_READ_ARCHIVE,
				"objective_text": "激活核心终端。",
				"completion_text": "核心干扰已清除。出口已开启。",
			}
		"final_signal":
			return {
				"type": Room.OBJECTIVE_READ_ARCHIVE,
				"objective_text": "激活核心终端。",
				"completion_text": "终端已激活。",
			}
		"final_antechamber":
			return {
				"type": Room.OBJECTIVE_CLEAR_ENEMIES,
				"objective_text": "清除战斗区内异常单位。",
				"completion_text": "封锁解除：异常单位已清除。",
			}
		"cryo_pod":
			return {
				"type": Room.OBJECTIVE_INTERACT_TARGETS,
				"objective_text": "检查冷冻舱 0/3。",
				"target_label": "冷冻舱",
				"target_total": 3,
				"completion_text": "封锁解除：冷冻舱已检查。",
			}
		"cryo_vent":
			return {
				"type": Room.OBJECTIVE_CLEAR_ENEMIES,
				"objective_text": "避开周期冷气喷口，清除房内冻伤样本。",
				"completion_text": "封锁解除：低温喷口已稳定。",
			}
		"elite":
			return {
				"type": Room.OBJECTIVE_CLEAR_ENEMIES,
				"objective_text": "击败仓库守卫。" if chapter_id == 4 else "击败冰核守卫，回收低温封存遗物。",
				"completion_text": "封锁解除：高威胁单位已清除。",
			}
		"reward":
			return {
				"type": Room.OBJECTIVE_CHOOSE_REWARD,
				"objective_text": "肃清守卫样本，回收补给箱。",
				"completion_text": "奖励解锁：补给箱可领取。",
			}
		"weapon":
			return {
				"type": Room.OBJECTIVE_CHOOSE_REWARD,
				"objective_text": "选择一件武器。",
				"completion_text": "武器选择已开放。",
			}
		"merchant":
			return {
				"type": Room.OBJECTIVE_SHOP,
				"objective_text": _chapter_shop_objective(chapter_id),
				"completion_text": "补给窗口已开启。",
			}
		"archive":
			return {
				"type": Room.OBJECTIVE_READ_ARCHIVE,
				"objective_text": "激活数据终端。",
				"completion_text": "数据节点已清除。",
			}
		"boss":
			return {
				"type": Room.OBJECTIVE_BOSS,
				"objective_text": str(chapter_config.get("boss_objective", "击败当前章节 Boss。")),
				"completion_text": "Boss 已击败：裂隙稳定。",
			}
	return {
		"type": Room.OBJECTIVE_CLEAR_ENEMIES,
		"objective_text": "清除所有敌人。",
		"completion_text": "封锁解除。",
	}


static func _chapter_start_objective(chapter_id: int) -> String:
	match chapter_id:
		FINAL_CHAPTER_ID:
			return "进入母巢深处。"
		5:
			return "进入数据中枢。"
		4:
			return "进入兵器工厂。"
		3:
			return "确认当前构筑，进入低温封存区。"
		2:
			return "确认前哨构筑，进入生态温室。"
	return "确认装备状态，进入极渊前哨基地。"


static func _chapter_combat_objective(chapter_id: int, label: String) -> String:
	match chapter_id:
		5:
			return "清除所有异常单位。"
		4:
			if label == "无人机装配线":
				return "清理装配线异常单位。"
			if label == "机械维护车间":
				return "清理维护车间异常单位。"
			if label == "自动化装配线":
				return "清除装配线安保单位。"
			return "清除所有安保单位。"
		3:
			return "清除冷雾处理间内的冻伤样本。"
		2:
			return "清除孢子培养廊内的失控样本。"
	return "清除房内样本，解除门锁。"


static func _chapter_event_objective(chapter_id: int, _label: String) -> Dictionary:
	match chapter_id:
		5:
			return {
				"type": Room.OBJECTIVE_INTERACT_TARGETS,
				"objective_text": "同步数据节点 0/3。",
				"target_label": "数据节点",
				"target_total": 3,
				"completion_text": "封锁解除：数据节点已同步。",
			}
		4:
			if _label == "动力控制室":
				return {
					"type": Room.OBJECTIVE_DESTROY_TARGETS,
					"objective_text": "摧毁动力控制节点 0/3。",
					"target_label": "动力控制节点",
					"target_total": 3,
					"completion_text": "封锁解除：动力控制节点已停机。",
				}
			return {
				"type": Room.OBJECTIVE_DESTROY_TARGETS,
				"objective_text": "摧毁外骨骼测试节点 0/3。",
				"target_label": "外骨骼测试节点",
				"target_total": 3,
				"completion_text": "封锁解除：外骨骼测试节点已摧毁。",
			}
		2:
			return {
				"type": Room.OBJECTIVE_DESTROY_TARGETS,
				"objective_text": "摧毁孢子囊 0/3，并清除房内敌人。",
				"target_label": "孢子囊",
				"target_total": 3,
				"completion_text": "封锁解除：孢子囊已清除。",
			}
	return {
		"type": Room.OBJECTIVE_DESTROY_TARGETS,
		"objective_text": "摧毁目标 0/3，并清除房内敌人。",
		"target_label": "目标",
		"target_total": 3,
		"completion_text": "封锁解除：目标已清除。",
	}


static func _chapter_shop_objective(chapter_id: int) -> String:
	match chapter_id:
		FINAL_CHAPTER_ID:
			return "最后整备。"
		5:
			return "整备补给并检查终端。"
		4:
			return "整备武器与补给。"
		3:
			return "确认低温封存舱状态，进入零号封存室。"
		2:
			return "在渡鸦温室补给站交易，准备进入培育舱。"
	return "与渡鸦交易，补充装备后前往下一房间。"


static func _build_safe_fallback_specs(rng: RandomNumberGenerator, chapter_config: Dictionary, layer_index: int) -> Array:
	var label_counts := {}
	var scene_pools := _build_scene_pools(chapter_config)
	var specs := []
	var path_types := (chapter_config.get("main_room_types", ["combat", "combat", "weapon"]) as Array).duplicate()
	path_types.append("merchant")
	path_types.append("boss")
	var main_path_room_count := maxi(4, int(chapter_config.get("main_path_room_count", MAIN_PATH_ROOM_COUNT)))
	var reward_room_count := maxi(0, int(chapter_config.get("reward_room_count", REWARD_ROOM_COUNT)))
	var layout_radius := maxi(2, int(chapter_config.get("layout_radius", LAYOUT_RADIUS)))
	var main_path := _build_safe_main_path(main_path_room_count)
	var reward_coords := _build_safe_reward_coords(main_path, reward_room_count, layout_radius)
	specs.append(_make_spec(
		main_path[0] as Vector2i,
		"start",
		str(chapter_config.get("start_label", "封存气闸")),
		chapter_config.get("start_room_scene", START_ROOM_SCENE) as PackedScene,
		0,
		chapter_config,
		layer_index
	))

	for index in range(path_types.size()):
		var room_type := str(path_types[index])
		var coord := main_path[index + 1] as Vector2i
		var scene := _take_scene(scene_pools, room_type, rng)
		specs.append(_make_spec(coord, room_type, _label_for_scene(room_type, label_counts, chapter_config, scene), scene, index + 1, chapter_config, layer_index))

	for coord in reward_coords:
		var scene := _take_scene(scene_pools, "reward", rng)
		specs.append(_make_spec(coord as Vector2i, "reward", _next_label("reward", label_counts, chapter_config), scene, 0, chapter_config, layer_index))

	return specs


static func _build_safe_main_path(room_count: int) -> Array:
	if room_count <= 6:
		return [
			Vector2i(0, 0),
			Vector2i(1, 0),
			Vector2i(1, 1),
			Vector2i(0, 1),
			Vector2i(0, 2),
			Vector2i(0, 3),
		]
	if room_count == 7:
		return [
			Vector2i(0, 0),
			Vector2i(1, 0),
			Vector2i(1, 1),
			Vector2i(0, 1),
			Vector2i(0, 2),
			Vector2i(1, 2),
			Vector2i(1, 3),
		]

	var path := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(2, 1),
		Vector2i(1, 1),
		Vector2i(0, 1),
	]
	var extra_needed := maxi(0, room_count - 8)
	var extra_candidates := [
		Vector2i(-1, 1),
		Vector2i(-1, 0),
		Vector2i(-2, 0),
		Vector2i(-2, 1),
		Vector2i(-3, 1),
	]
	for index in range(mini(extra_needed, extra_candidates.size())):
		path.append(extra_candidates[index])

	var last_flexible_coord := path[path.size() - 1] as Vector2i
	var merchant_coord := last_flexible_coord + Vector2i(0, 1)
	var boss_coord := merchant_coord + Vector2i(0, 1)
	path.append(merchant_coord)
	path.append(boss_coord)
	return path


static func _build_safe_reward_coords(main_path: Array, reward_room_count: int, layout_radius: int) -> Array:
	var occupied := {}
	for coord in main_path:
		occupied[coord] = true

	var reward_coords := []
	while reward_coords.size() < reward_room_count:
		var candidates := _collect_loop_branch_candidates(main_path, occupied, main_path, layout_radius)
		if candidates.is_empty():
			return reward_coords
		var chosen: Vector2i = candidates[0] as Vector2i
		reward_coords.append(chosen)
		occupied[chosen] = true
	return reward_coords


static func _validate_room_specs(room_specs: Array, chapter_config: Dictionary, layer_index: int, print_errors := true) -> bool:
	var errors := PackedStringArray()
	var coords := {}
	var start_specs := []
	var boss_specs := []
	var merchant_specs := []
	var type_counts := {}

	for spec_value in room_specs:
		var spec := spec_value as Dictionary
		var coord := spec.get("coord", Vector2i.ZERO) as Vector2i
		var room_type := str(spec.get("type", ""))
		coords[coord] = true
		type_counts[room_type] = int(type_counts.get(room_type, 0)) + 1
		match room_type:
			"start":
				start_specs.append(spec)
			"boss":
				boss_specs.append(spec)
			"merchant":
				merchant_specs.append(spec)

	if start_specs.is_empty():
		errors.append("Map validation failed: missing spawn room")
	if boss_specs.is_empty():
		errors.append("Map validation failed: missing boss room")
	if merchant_specs.is_empty():
		errors.append("Map validation failed: pre-boss shop missing")

	if not boss_specs.is_empty() and not merchant_specs.is_empty():
		var boss_coord := boss_specs[0].get("coord", Vector2i.ZERO) as Vector2i
		var merchant_coord := merchant_specs[0].get("coord", Vector2i.ZERO) as Vector2i
		if not _are_adjacent(merchant_coord, boss_coord):
			errors.append("Map validation failed: pre-boss shop is not adjacent to boss")
		var merchant_objective := merchant_specs[0].get("objective", {}) as Dictionary
		if str(merchant_specs[0].get("room_role", "")) != ROOM_ROLE_PRE_BOSS_SHOP:
			errors.append("Map validation failed: merchant room is not marked PRE_BOSS_SHOP")
		if str(merchant_objective.get("type", "")) != Room.OBJECTIVE_SHOP:
			errors.append("Map validation failed: pre-boss shop objective is not SHOP")

	if not start_specs.is_empty():
		var reachable := _collect_reachable_coords(start_specs[0].get("coord", Vector2i.ZERO) as Vector2i, coords)
		for coord in coords.keys():
			if not reachable.has(coord):
				errors.append("Map validation failed: unreachable room at %s" % [coord])
		_append_room_exit_errors(errors, room_specs, coords)

	var required_room_types := chapter_config.get("main_room_types", []) as Array
	for required_value in required_room_types:
		var required_type := str(required_value)
		if int(type_counts.get(required_type, 0)) <= 0:
			errors.append("Map validation failed: missing key room type %s" % required_type)

	for spec_value in room_specs:
		var spec := spec_value as Dictionary
		var room_type := str(spec.get("type", ""))
		var objective := spec.get("objective", {}) as Dictionary
		if room_type == "merchant":
			if int(objective.get("target_total", 0)) > 0:
				errors.append("Map validation failed: shop has event targets")
		if room_type in ["pollution", "data_comm", "data_comm_control", "cryo_pod"]:
			var target_total := int(objective.get("target_total", 0))
			if target_total != 3:
				errors.append("Map validation failed: event target count mismatch in %s" % room_type)
		if room_type == "boss" and str(objective.get("type", "")) != Room.OBJECTIVE_BOSS:
			errors.append("Map validation failed: boss room objective is not BOSS")

	if not errors.is_empty():
		if print_errors:
			for error_message in errors:
				push_warning("%s | chapter %s layer %d" % [error_message, str(chapter_config.get("title", "")), layer_index])
		return false
	return true


static func _append_room_exit_errors(errors: PackedStringArray, room_specs: Array, coords: Dictionary) -> void:
	for spec_value in room_specs:
		var spec := spec_value as Dictionary
		var room_type := str(spec.get("type", ""))
		var coord := spec.get("coord", Vector2i.ZERO) as Vector2i
		var exit_count := _count_adjacent_coords(coord, coords)
		if room_type == "boss":
			continue
		if room_type == "start" and exit_count < 2:
			errors.append("Map validation failed: spawn room has only one exit")
			continue
		if exit_count < 2:
			errors.append("Map validation failed: room has only one exit at %s (%s)" % [coord, room_type])


static func _append_generated_room_exit_errors(errors: PackedStringArray, generated_rooms: Dictionary, coords: Dictionary) -> void:
	for room_pos in generated_rooms:
		var room := generated_rooms[room_pos] as Room
		if room == null:
			continue
		var exit_count := _count_adjacent_coords(room.room_pos, coords)
		if room.lab_room_type == "boss":
			continue
		if room.lab_room_type == "start" and exit_count < 2:
			errors.append("Map validation failed: spawn room has only one exit")
			continue
		if exit_count < 2:
			errors.append("Map validation failed: room has only one exit at %s (%s)" % [room.room_pos, room.lab_room_type])


static func _collect_reachable_coords(start_coord: Vector2i, coords: Dictionary) -> Dictionary:
	var reachable := {}
	var queue := [start_coord]
	reachable[start_coord] = true
	while not queue.is_empty():
		var current := queue.pop_front() as Vector2i
		for direction: Vector2i in DIRECTIONS:
			var next_coord := current + direction
			if not coords.has(next_coord):
				continue
			if reachable.has(next_coord):
				continue
			reachable[next_coord] = true
			queue.append(next_coord)
	return reachable


static func _count_adjacent_coords(coord: Vector2i, coords: Dictionary) -> int:
	var count := 0
	for direction: Vector2i in DIRECTIONS:
		if coords.has(coord + direction):
			count += 1
	return count


static func _touches_boss_without_being_merchant(coord: Vector2i, main_path: Array) -> bool:
	if main_path.size() < 2:
		return false
	var boss_coord := main_path[main_path.size() - 1] as Vector2i
	var merchant_coord := main_path[main_path.size() - 2] as Vector2i
	return coord != merchant_coord and _are_adjacent(coord, boss_coord)


static func _validate_generated_rooms(generated_rooms: Dictionary, chapter_config: Dictionary, layer_index: int) -> bool:
	var errors := PackedStringArray()
	var start_room: Room = null
	var boss_room: Room = null
	var merchant_room: Room = null
	var coords := {}

	for room_pos in generated_rooms:
		var room := generated_rooms[room_pos] as Room
		if room == null:
			continue
		coords[room.room_pos] = true
		match room.lab_room_type:
			"start":
				start_room = room
			"boss":
				boss_room = room
			"merchant":
				merchant_room = room
				if _count_children_in_group(room, "room_event_targets") > 0:
					errors.append("Map validation failed: shop has event targets")
				if _count_descendants_of_type(room, "LabChest") > 0:
					errors.append("Map validation failed: shop has chest")
				if room.has_node("Enemies") and room.get_node("Enemies").get_child_count() > 0:
					errors.append("Map validation failed: shop has enemies")
			"pollution", "data_comm", "data_comm_control", "cryo_pod":
				if room.has_method("get_event_target_total"):
					var target_total := int(room.call("get_event_target_total"))
					if target_total != 3:
						errors.append("Map validation failed: event target count mismatch in %s (%d)" % [room.lab_room_type, target_total])

	if start_room == null:
		errors.append("Map validation failed: missing spawn room")
	if boss_room == null:
		errors.append("Map validation failed: missing boss room")
	if merchant_room == null:
		errors.append("Map validation failed: pre-boss shop missing")
	if boss_room != null and merchant_room != null and not _are_adjacent(merchant_room.room_pos, boss_room.room_pos):
		errors.append("Map validation failed: pre-boss shop is not adjacent to boss")
	if start_room != null:
		var reachable := _collect_reachable_coords(start_room.room_pos, coords)
		for coord in coords.keys():
			if not reachable.has(coord):
				errors.append("Map validation failed: unreachable instantiated room at %s" % [coord])
		_append_generated_room_exit_errors(errors, generated_rooms, coords)
	if boss_room != null and _boss_has_active_enemy(boss_room):
		errors.append("Map validation failed: boss appears active before room entry")

	if not errors.is_empty():
		for error_message in errors:
			push_warning("%s | chapter %s layer %d" % [error_message, str(chapter_config.get("title", "")), layer_index])
		return false
	return true


static func _count_children_in_group(root: Node, group_name: String) -> int:
	var count := 0
	if root.is_in_group(group_name):
		count += 1
	for child in root.get_children():
		count += _count_children_in_group(child, group_name)
	return count


static func _count_descendants_of_type(root: Node, class_name_value: String) -> int:
	var count := 0
	if class_name_value == "LabChest" and root is LabChest:
		count += 1
	for child in root.get_children():
		count += _count_descendants_of_type(child, class_name_value)
	return count


static func _boss_has_active_enemy(boss_room: Room) -> bool:
	if not boss_room.has_node("Enemies"):
		return false
	for enemy in boss_room.get_node("Enemies").get_children():
		if enemy.process_mode != Node.PROCESS_MODE_DISABLED:
			return true
	return false


static func _label_for_scene(room_type: String, label_counts: Dictionary, chapter_config: Dictionary, scene: PackedScene) -> String:
	if int(chapter_config.get("id", DEFAULT_CHAPTER_ID)) == 4:
		var scene_path: String = scene.resource_path
		match scene_path:
			"res://tiny_wizard/room/room_types/lab_exosuit_assembly_room.tscn":
				label_counts[room_type] = int(label_counts.get(room_type, 0)) + 1
				return "自动化装配线"
			"res://tiny_wizard/room/room_types/lab_exosuit_drone_room.tscn":
				label_counts[room_type] = int(label_counts.get(room_type, 0)) + 1
				return "无人机装配线"
			"res://tiny_wizard/room/room_types/lab_exosuit_maintenance_room.tscn":
				label_counts[room_type] = int(label_counts.get(room_type, 0)) + 1
				return "机械维护车间"
			"res://tiny_wizard/room/room_types/lab_exosuit_test_room.tscn":
				label_counts[room_type] = int(label_counts.get(room_type, 0)) + 1
				return "外骨骼测试场"
			"res://tiny_wizard/room/room_types/lab_exosuit_power_control_room.tscn":
				label_counts[room_type] = int(label_counts.get(room_type, 0)) + 1
				return "动力控制室"
	return _next_label(room_type, label_counts, chapter_config)


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
		"data_comm_control":
			return str(chapter_config.get("data_comm_control_label", "通讯控制区"))
		"final_transition":
			return str(chapter_config.get("final_transition_label", "高危战斗区"))
		"final_core_interference":
			return str(chapter_config.get("final_core_interference_label", "核心干扰室"))
		"final_signal":
			return str(chapter_config.get("final_signal_label", "核心终端室"))
		"final_antechamber":
			return str(chapter_config.get("final_antechamber_label", "Boss 前战斗区"))
		"cryo_pod":
			return str(chapter_config.get("cryo_pod_label", "冷冻舱列阵"))
		"cryo_vent":
			return str(chapter_config.get("cryo_vent_label", "冷却通风廊"))
		"elite":
			return str(chapter_config.get("elite_label", "精英封存室"))
		"archive":
			return str(chapter_config.get("archive_label", "数据封存区"))
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
