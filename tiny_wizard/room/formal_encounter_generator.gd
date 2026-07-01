class_name LabFormalEncounterGenerator
extends RefCounted


const CRAWLER_SCENE := preload("res://tiny_wizard/enemies/red_fly/red_fly.tscn")
const FLOATER_SCENE := preload("res://tiny_wizard/enemies/black_fly/black_fly.tscn")
const SPITTER_SCENE := preload("res://tiny_wizard/enemies/quarantine_spitter/quarantine_spitter.tscn")
const FROSTBITTEN_SCENE := preload("res://tiny_wizard/enemies/frostbitten_infected/frostbitten_infected.tscn")
const STASIS_CRAWLER_SCENE := preload("res://tiny_wizard/enemies/stasis_crawler/stasis_crawler.tscn")
const CRYO_SPITTER_SCENE := preload("res://tiny_wizard/enemies/cryo_spitter/cryo_spitter.tscn")

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
		"id": "frostbitten_infected",
		"scene": FROSTBITTEN_SCENE,
		"cost": 1,
		"weight": 5,
	},
	{
		"id": "stasis_crawler",
		"scene": STASIS_CRAWLER_SCENE,
		"cost": 2,
		"weight": 3,
	},
	{
		"id": "cryo_spitter",
		"scene": CRYO_SPITTER_SCENE,
		"cost": 3,
		"weight": 3,
	},
]


static func populate(room: Room, rng: RandomNumberGenerator, path_depth: int) -> void:
	if room == null or not (room.lab_room_type in ["combat", "cryo_vent"]):
		return
	var enemies := room.get_node_or_null("Enemies")
	if enemies == null:
		return

	_clear_authored_enemies(enemies)
	var budget_index := clampi(path_depth - 1, 0, BUDGET_BY_DEPTH.size() - 1)
	var budget := int(BUDGET_BY_DEPTH[budget_index])
	if int(room.get_meta("chapter_id", 1)) == 3:
		budget += 1
	if int(room.get_meta("chapter_id", 1)) == 4:
		budget += 2
	var definitions := _get_enemy_definitions(room)
	var encounter := _build_encounter(rng, budget, path_depth, definitions)
	var spawn_positions := _build_spawn_positions(room, encounter.size(), rng)
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
	return ENEMY_DEFINITIONS


static func _build_encounter(rng: RandomNumberGenerator, budget: int, path_depth: int, enemy_definitions := ENEMY_DEFINITIONS) -> Array:
	var encounter := []
	var remaining_budget := budget
	var spitter_count := 0

	var crawler := enemy_definitions[0] as Dictionary
	encounter.append(crawler)
	remaining_budget -= int(crawler["cost"])

	while remaining_budget > 0 and encounter.size() < MAX_ENEMY_COUNT:
		var candidates := []
		var total_weight := 0
		for definition_value in enemy_definitions:
			var definition := definition_value as Dictionary
			var cost := int(definition["cost"])
			if cost > remaining_budget:
				continue
			if str(definition["id"]) in ["quarantine_spitter", "cryo_spitter"] and spitter_count >= MAX_SPITTER_COUNT:
				continue

			var weight := int(definition["weight"])
			if str(definition["id"]) in ["quarantine_spitter", "cryo_spitter"]:
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
		if str(selected["id"]) in ["quarantine_spitter", "cryo_spitter"]:
			spitter_count += 1

	_shuffle_array(encounter, rng)
	return encounter


static func _build_spawn_positions(room: Room, count: int, rng: RandomNumberGenerator) -> Array:
	var positions := []
	var attempts := 0
	while positions.size() < count and attempts < SPAWN_ATTEMPTS:
		attempts += 1
		var candidate := Vector2(
			rng.randf_range(ROOM_INTERIOR.position.x, ROOM_INTERIOR.end.x),
			rng.randf_range(ROOM_INTERIOR.position.y, ROOM_INTERIOR.end.y)
		)
		if not _is_spawn_position_valid(room, candidate, positions):
			continue
		positions.append(candidate)

	if positions.size() < count:
		for fallback_position in _fallback_spawn_positions():
			if positions.size() >= count:
				break
			if _is_spawn_position_valid(room, fallback_position, positions):
				positions.append(fallback_position)

	attempts = 0
	while positions.size() < count and attempts < SPAWN_ATTEMPTS:
		attempts += 1
		var candidate := Vector2(
			rng.randf_range(ROOM_INTERIOR.position.x, ROOM_INTERIOR.end.x),
			rng.randf_range(ROOM_INTERIOR.position.y, ROOM_INTERIOR.end.y)
		)
		if not _is_spawn_position_valid(
			room,
			candidate,
			positions,
			RELAXED_SPAWN_SEPARATION,
			RELAXED_DOOR_DISTANCE,
			RELAXED_PROP_DISTANCE,
			RELAXED_OBSTACLE_CLEARANCE
		):
			continue
		positions.append(candidate)

	return positions


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
