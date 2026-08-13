class_name LabFormalEncounterGenerator
extends RefCounted


const CRAWLER_SCENE := preload("res://tiny_wizard/enemies/red_fly/red_fly.tscn")
const FLOATER_SCENE := preload("res://tiny_wizard/enemies/black_fly/black_fly.tscn")
const SPITTER_SCENE := preload("res://tiny_wizard/enemies/quarantine_spitter/quarantine_spitter.tscn")
const BRITTLE_SHELL_ADAPTER_SCENE := preload("res://tiny_wizard/enemies/brittle_shell_adapter/brittle_shell_adapter.tscn")
const SEALED_TECHNICIAN_SCENE := preload("res://tiny_wizard/enemies/sealed_technician/sealed_technician.tscn")
const RIVET_INSPECTION_RIG_SCENE := preload("res://tiny_wizard/enemies/rivet_inspection_rig/rivet_inspection_rig.tscn")
const REJECTED_CARRIER_SCENE := preload("res://tiny_wizard/enemies/rejected_carrier/rejected_carrier.tscn")
const SECURITY_GANTRY_UNIT_SCENE := preload("res://tiny_wizard/enemies/security_gantry_unit/security_gantry_unit.tscn")
const CHAPTER5_INDEX_PURSUER_SCENE := preload("res://tiny_wizard/enemies/index_pursuer/index_pursuer.tscn")
const CHAPTER5_PORT_RELAY_SCENE := preload("res://tiny_wizard/enemies/port_relay/port_relay.tscn")
const CHAPTER5_HYDRAULIC_CLEARANCE_RIG_SCENE := preload("res://tiny_wizard/enemies/hydraulic_clearance_rig/hydraulic_clearance_rig.tscn")
const CHAPTER5_R7_EXECUTOR_SCENE := preload("res://tiny_wizard/enemies/r7_executor/r7_executor.tscn")

const MAX_ENEMY_COUNT := 6
const MAX_SPITTER_COUNT := 2
const MIN_SPAWN_SEPARATION := 104.0
const MIN_DOOR_DISTANCE := 176.0
const MIN_PROP_DISTANCE := 82.0
const OBSTACLE_CLEARANCE := 64.0
const SPAWN_ATTEMPTS := 240
const RELAXED_SPAWN_SEPARATION := 82.0
const RELAXED_DOOR_DISTANCE := 152.0
const RELAXED_PROP_DISTANCE := 68.0
const RELAXED_OBSTACLE_CLEARANCE := 52.0
const ROOM_INTERIOR := Rect2(180, 138, 664, 324)
const BUDGET_BY_DEPTH := [5, 6, 8]

const ENEMY_DEFINITIONS := [
	{
		"id": "maintenance_crawler",
		"scene": CRAWLER_SCENE,
		"cost": 1,
		"weight": 5,
	},
	{
		"id": "leaking_floater",
		"scene": FLOATER_SCENE,
		"cost": 2,
		"weight": 4,
	},
	{
		"id": "quarantine_spitter",
		"scene": SPITTER_SCENE,
		"cost": 3,
		"weight": 2,
	},
]

const CRYO_ENEMY_DEFINITIONS := [
	{
		"id": "brittle_shell_adapter",
		"scene": BRITTLE_SHELL_ADAPTER_SCENE,
		"cost": 1,
		"weight": 5,
	},
	{
		"id": "sealed_technician",
		"scene": SEALED_TECHNICIAN_SCENE,
		"cost": 3,
		"weight": 3,
	},
]

const EXOSUIT_ENEMY_DEFINITIONS := [
	{
		"id": "rejected_carrier",
		"scene": REJECTED_CARRIER_SCENE,
		"cost": 2,
		"weight": 5,
		"max_count": 3,
		"required_lane_length": 220.0,
	},
	{
		"id": "rivet_inspection_rig",
		"scene": RIVET_INSPECTION_RIG_SCENE,
		"cost": 3,
		"weight": 3,
		"max_count": 2,
	},
]

const EXOSUIT_ELITE_DEFINITIONS := [
	{
		"id": "security_gantry_unit",
		"scene": SECURITY_GANTRY_UNIT_SCENE,
		"cost": 99,
		"weight": 1,
		"max_count": 1,
		"spawn_clearance": 118.0,
		"required_lane_length": 260.0,
	},
]

const DATA_CORE_ENEMY_DEFINITIONS := [
	{"id": "index_pursuer", "scene": CHAPTER5_INDEX_PURSUER_SCENE, "cost": 1, "weight": 6, "max_count": 3},
	{"id": "port_relay", "scene": CHAPTER5_PORT_RELAY_SCENE, "cost": 2, "weight": 3, "max_count": 1, "requires": ["index_pursuer"]},
	{"id": "hydraulic_clearance_rig", "scene": CHAPTER5_HYDRAULIC_CLEARANCE_RIG_SCENE, "cost": 3, "weight": 2, "max_count": 2},
]

const DATA_CORE_ELITE_DEFINITIONS := [
	{"id": "r7_executor", "scene": CHAPTER5_R7_EXECUTOR_SCENE, "cost": 99, "weight": 1, "max_count": 1, "spawn_clearance": 130.0},
]


static func populate(room: Room, rng: RandomNumberGenerator, path_depth: int) -> void:
	if room == null:
		return
	var chapter_id := int(room.get_meta("chapter_id", 1))
	if not (room.lab_room_type in ["combat", "cryo_vent"]) and not (chapter_id in [4, 5] and room.lab_room_type == "elite"):
		return
	var enemies := room.get_node_or_null("Enemies")
	if enemies == null:
		return

	_clear_authored_enemies(enemies)
	if chapter_id == 4 and room.lab_room_type == "elite":
		_populate_chapter_four_elite(room, enemies, rng, path_depth)
		return
	if chapter_id == 5 and room.lab_room_type == "elite":
		_populate_chapter_five_elite(room, enemies, rng, path_depth)
		return

	var budget_index := clampi(path_depth - 1, 0, BUDGET_BY_DEPTH.size() - 1)
	var budget := int(BUDGET_BY_DEPTH[budget_index])
	if chapter_id == 3:
		budget += 1
	if chapter_id == 4:
		budget += 2
	if chapter_id == 5:
		budget = 4
	var definitions := _get_enemy_definitions(room)
	var encounter := _build_encounter(rng, budget, path_depth, definitions)
	var spawn_positions := _build_spawn_positions(room, encounter, rng)
	var spawned_ids := []

	for index in range(mini(encounter.size(), spawn_positions.size())):
		var definition := encounter[index] as Dictionary
		var enemy_scene := definition.get("scene") as PackedScene
		if enemy_scene == null:
			continue
		var enemy := enemy_scene.instantiate() as Node2D
		if enemy == null:
			continue
		enemy.name = "%s_%02d" % [str(definition.get("id", "enemy")).to_pascal_case(), index + 1]
		enemy.position = spawn_positions[index]
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemies.add_child(enemy)
		spawned_ids.append(str(definition.get("id", "enemy")))

	room.set_meta("formal_encounter_budget", budget)
	room.set_meta("formal_encounter_depth", path_depth)
	room.set_meta("formal_encounter_ids", spawned_ids)


static func _clear_authored_enemies(enemies: Node) -> void:
	for child in enemies.get_children():
		enemies.remove_child(child)
		child.free()


static func _get_enemy_definitions(room: Room) -> Array:
	if room != null and int(room.get_meta("chapter_id", 1)) == 3:
		return CRYO_ENEMY_DEFINITIONS
	if room != null and int(room.get_meta("chapter_id", 1)) == 4:
		return EXOSUIT_ENEMY_DEFINITIONS
	if room != null and int(room.get_meta("chapter_id", 1)) == 5:
		return DATA_CORE_ENEMY_DEFINITIONS
	return ENEMY_DEFINITIONS


static func _build_encounter(rng: RandomNumberGenerator, budget: int, path_depth: int, enemy_definitions := ENEMY_DEFINITIONS) -> Array:
	var encounter := []
	var remaining_budget := budget
	var selected_counts := {}

	var crawler := enemy_definitions[0] as Dictionary
	encounter.append(crawler)
	remaining_budget -= int(crawler["cost"])
	selected_counts[str(crawler["id"])] = 1

	while remaining_budget > 0 and encounter.size() < MAX_ENEMY_COUNT:
		var candidates := []
		var total_weight := 0
		for definition_value in enemy_definitions:
			var definition := definition_value as Dictionary
			var cost := int(definition["cost"])
			if cost > remaining_budget:
				continue
			var definition_id := str(definition["id"])
			var max_count := int(definition.get("max_count", MAX_ENEMY_COUNT))
			var requirements := definition.get("requires", []) as Array
			var requirement_missing := false
			for required_id in requirements:
				if not selected_counts.has(str(required_id)):
					requirement_missing = true
					break
			if requirement_missing:
				continue
			if definition_id in ["quarantine_spitter", "sealed_technician"]:
				max_count = mini(max_count, MAX_SPITTER_COUNT)
			if int(selected_counts.get(definition_id, 0)) >= max_count:
				continue

			var weight := int(definition["weight"])
			if definition_id in ["quarantine_spitter", "sealed_technician", "rivet_inspection_rig"]:
				weight += maxi(0, path_depth - 1)
			candidates.append({"definition": definition, "weight": weight})
			total_weight += weight

		if candidates.is_empty() or total_weight <= 0:
			break

		var roll := rng.randi_range(1, total_weight)
		var selected := candidates[0]["definition"] as Dictionary
		for candidate_value in candidates:
			var candidate := candidate_value as Dictionary
			roll -= int(candidate["weight"])
			if roll <= 0:
				selected = candidate["definition"] as Dictionary
				break

		encounter.append(selected)
		remaining_budget -= int(selected["cost"])
		var selected_id := str(selected["id"])
		selected_counts[selected_id] = int(selected_counts.get(selected_id, 0)) + 1

	_shuffle_array(encounter, rng)
	return encounter


static func _populate_chapter_four_elite(room: Room, enemies: Node, rng: RandomNumberGenerator, path_depth: int) -> void:
	var encounter := EXOSUIT_ELITE_DEFINITIONS.duplicate()
	var definition := encounter[0] as Dictionary
	var spawn_positions := []
	var preferred_position := Vector2(512.0, 306.0)
	if _is_spawn_position_valid_for_definition(room, preferred_position, [], definition):
		spawn_positions.append(preferred_position)
	else:
		spawn_positions = _build_spawn_positions(room, encounter, rng)
		if spawn_positions.is_empty():
			room.set_meta("formal_encounter_ids", [])
			push_warning("Chapter 4 elite room has no safe security gantry spawn position.")
			return
	var enemy_scene := definition.get("scene") as PackedScene
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.name = "SecurityGantryUnit_01"
	enemy.position = spawn_positions[0]
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemies.add_child(enemy)
	room.set_meta("formal_encounter_budget", 99)
	room.set_meta("formal_encounter_depth", path_depth)
	room.set_meta("formal_encounter_ids", [str(definition.get("id", "enemy"))])


static func _populate_chapter_five_elite(room: Room, enemies: Node, rng: RandomNumberGenerator, path_depth: int) -> void:
	var definition := DATA_CORE_ELITE_DEFINITIONS[0] as Dictionary
	var spawn_position := Vector2(512.0, 306.0)
	if not _is_spawn_position_valid_for_definition(room, spawn_position, [], definition):
		var fallback := _build_spawn_positions(room, [definition], rng)
		if fallback.is_empty():
			room.set_meta("formal_encounter_ids", [])
			push_warning("Chapter 5 elite room has no safe R-7 spawn position.")
			return
		spawn_position = fallback[0]
	var enemy_scene := definition.get("scene") as PackedScene
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.name = "R7Executor_01"
	enemy.position = spawn_position
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemies.add_child(enemy)
	room.set_meta("formal_encounter_budget", 99)
	room.set_meta("formal_encounter_depth", path_depth)
	room.set_meta("formal_encounter_ids", [str(definition.get("id", "enemy"))])


static func _build_spawn_positions(room: Room, encounter: Array, rng: RandomNumberGenerator) -> Array:
	var positions := []
	var attempts := 0
	while positions.size() < encounter.size() and attempts < SPAWN_ATTEMPTS:
		attempts += 1
		var candidate := Vector2(
			rng.randf_range(ROOM_INTERIOR.position.x, ROOM_INTERIOR.end.x),
			rng.randf_range(ROOM_INTERIOR.position.y, ROOM_INTERIOR.end.y)
		)
		var definition := encounter[positions.size()] as Dictionary
		if not _is_spawn_position_valid_for_definition(room, candidate, positions, definition):
			continue
		positions.append(candidate)

	if positions.size() < encounter.size():
		for fallback_position in _fallback_spawn_positions():
			if positions.size() >= encounter.size():
				break
			var definition := encounter[positions.size()] as Dictionary
			if _is_spawn_position_valid_for_definition(room, fallback_position, positions, definition):
				positions.append(fallback_position)

	attempts = 0
	while positions.size() < encounter.size() and attempts < SPAWN_ATTEMPTS:
		attempts += 1
		var candidate := Vector2(
			rng.randf_range(ROOM_INTERIOR.position.x, ROOM_INTERIOR.end.x),
			rng.randf_range(ROOM_INTERIOR.position.y, ROOM_INTERIOR.end.y)
		)
		var definition := encounter[positions.size()] as Dictionary
		if not _is_spawn_position_valid(
			room,
			candidate,
			positions,
			RELAXED_SPAWN_SEPARATION,
			RELAXED_DOOR_DISTANCE,
			float(definition.get("spawn_clearance", RELAXED_PROP_DISTANCE)),
			RELAXED_OBSTACLE_CLEARANCE
		):
			continue
		var lane_length := float(definition.get("required_lane_length", 0.0))
		if lane_length > 0.0 and not _has_clear_lane(room, candidate, lane_length):
			continue
		positions.append(candidate)

	return positions


static func _is_spawn_position_valid_for_definition(
	room: Room,
	candidate: Vector2,
	accepted: Array,
	definition: Dictionary
) -> bool:
	if not _is_spawn_position_valid(
		room,
		candidate,
		accepted,
		MIN_SPAWN_SEPARATION,
		MIN_DOOR_DISTANCE,
		float(definition.get("spawn_clearance", MIN_PROP_DISTANCE)),
		OBSTACLE_CLEARANCE
	):
		return false
	var lane_length := float(definition.get("required_lane_length", 0.0))
	if lane_length > 0.0 and not _has_clear_lane(room, candidate, lane_length):
		return false
	return true


static func _is_spawn_position_valid(
	room: Room,
	candidate: Vector2,
	accepted: Array,
	spawn_separation := MIN_SPAWN_SEPARATION,
	door_distance := MIN_DOOR_DISTANCE,
	prop_distance := MIN_PROP_DISTANCE,
	obstacle_clearance := OBSTACLE_CLEARANCE
) -> bool:
	for spawn_name in ["RightSpawnPoint", "DownSpawnPoint", "LeftSpawnPoint", "UpSpawnPoint"]:
		var spawn_point := room.get_node_or_null(spawn_name) as Node2D
		if spawn_point != null and candidate.distance_to(spawn_point.position) < door_distance:
			return false

	for existing_position in accepted:
		if candidate.distance_to(existing_position as Vector2) < spawn_separation:
			return false

	if _is_near_room_prop(room, candidate, prop_distance):
		return false
	if _is_near_tile_obstacle(room, candidate, obstacle_clearance):
		return false
	return true


static func _is_near_room_prop(room: Room, candidate: Vector2, clearance: float) -> bool:
	var ignored_names := {
		"RoomWalls": true,
		"RightSpawnPoint": true,
		"DownSpawnPoint": true,
		"LeftSpawnPoint": true,
		"UpSpawnPoint": true,
		"Enemies": true,
		"TileMap": true,
	}
	for child in room.get_children():
		if not child is Node2D or ignored_names.has(str(child.name)):
			continue
		if candidate.distance_to((child as Node2D).position) < clearance:
			return true
	return false


static func _is_near_tile_obstacle(room: Room, candidate: Vector2, clearance: float) -> bool:
	var tile_map := room.get_node_or_null("TileMap") as TileMap
	if tile_map == null:
		return false
	for cell in tile_map.get_used_cells(0):
		var obstacle_center := tile_map.position + tile_map.map_to_local(cell)
		if candidate.distance_to(obstacle_center) < clearance:
			return true
	return false


static func _has_clear_lane(room: Room, candidate: Vector2, length: float) -> bool:
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var lane_end: Vector2 = candidate + direction * length
		if not ROOM_INTERIOR.has_point(lane_end):
			continue
		if _lane_intersects_obstacle(room, candidate, lane_end):
			continue
		return true
	return false


static func _lane_intersects_obstacle(room: Room, start: Vector2, end: Vector2) -> bool:
	var steps := maxi(4, ceili(start.distance_to(end) / 32.0))
	for index in range(steps + 1):
		var point := start.lerp(end, float(index) / float(steps))
		if _is_near_room_prop(room, point, 54.0) or _is_near_tile_obstacle(room, point, 46.0):
			return true
	return false


static func _fallback_spawn_positions() -> Array:
	return [
		Vector2(300, 180),
		Vector2(724, 180),
		Vector2(512, 300),
		Vector2(300, 420),
		Vector2(724, 420),
		Vector2(390, 300),
		Vector2(634, 300),
	]


static func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
