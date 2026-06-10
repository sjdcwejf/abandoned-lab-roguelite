class_name LabDungeonGenerator
extends RefCounted


const TUTORIAL_START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_start_room.tscn")
const START_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_formal_start_room.tscn")
const TUTORIAL_COMBAT_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_tutorial_combat_room.tscn")
const TUTORIAL_BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_tutorial_boss_room.tscn")
const COMBAT_ROOM_A_SCENE := preload("res://tiny_wizard/room/room_types/room_1.tscn")
const COMBAT_ROOM_B_SCENE := preload("res://tiny_wizard/room/room_types/room_2.tscn")
const REWARD_ROOM_A_SCENE := preload("res://tiny_wizard/room/room_types/lab_reward_bomb_room.tscn")
const REWARD_ROOM_B_SCENE := preload("res://tiny_wizard/room/room_types/lab_reward_guarded_room.tscn")
const WEAPON_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/room_4.tscn")
const BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_boss_room.tscn")

const START_ROOM_OFFSET := Vector2(0, 200)
const MAIN_PATH_ROOM_COUNT := 5
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
		"label": "Start Room",
		"scene": START_ROOM_SCENE,
	},
	{
		"coord": Vector2i(1, 0),
		"type": "combat",
		"label": "Monster Room 1",
		"scene": COMBAT_ROOM_A_SCENE,
	},
	{
		"coord": Vector2i(2, 0),
		"type": "combat",
		"label": "Monster Room 2",
		"scene": COMBAT_ROOM_B_SCENE,
	},
	{
		"coord": Vector2i(3, 0),
		"type": "boss",
		"label": "Boss Room",
		"scene": BOSS_ROOM_SCENE,
	},
	{
		"coord": Vector2i(1, -1),
		"type": "weapon",
		"label": "Weapon Room",
		"scene": WEAPON_ROOM_SCENE,
	},
	{
		"coord": Vector2i(2, -1),
		"type": "reward",
		"label": "Reward Room 1",
		"scene": REWARD_ROOM_A_SCENE,
	},
	{
		"coord": Vector2i(2, 1),
		"type": "reward",
		"label": "Reward Room 2",
		"scene": REWARD_ROOM_B_SCENE,
	},
]

const TUTORIAL_ROOM_LAYOUT := [
	{
		"coord": Vector2i(0, 0),
		"type": "tutorial_start",
		"label": "Tutorial Start Room",
		"scene": TUTORIAL_START_ROOM_SCENE,
	},
	{
		"coord": Vector2i(1, 0),
		"type": "tutorial_combat",
		"label": "Tutorial Bomb Room",
		"scene": TUTORIAL_COMBAT_ROOM_SCENE,
	},
	{
		"coord": Vector2i(2, 0),
		"type": "tutorial_boss",
		"label": "Tutorial Boss Room",
		"scene": TUTORIAL_BOSS_ROOM_SCENE,
	},
]

static var last_seed := 0


static func generate(rooms_parent: Node2D, requested_seed := 0) -> Dictionary:
	_clear_existing_rooms(rooms_parent)

	var rng := RandomNumberGenerator.new()
	last_seed = _resolve_seed(requested_seed)
	rng.seed = last_seed

	var room_layout := _generate_random_layout(rng)
	var generated_rooms := {}
	for spec in room_layout:
		var room := _instantiate_room(spec)
		rooms_parent.add_child(room)
		generated_rooms[room.room_pos] = room

	return generated_rooms


static func generate_tutorial(rooms_parent: Node2D) -> Dictionary:
	_clear_existing_rooms(rooms_parent)

	var generated_rooms := {}
	for spec in TUTORIAL_ROOM_LAYOUT:
		var room := _instantiate_room(spec)
		rooms_parent.add_child(room)
		generated_rooms[room.room_pos] = room

	return generated_rooms


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


static func _generate_random_layout(rng: RandomNumberGenerator) -> Array:
	for attempt in range(MAX_LAYOUT_ATTEMPTS):
		var main_path := _build_main_path(rng)
		if main_path.is_empty():
			continue

		var reward_coords := _build_reward_branches(main_path, rng)
		if reward_coords.size() != REWARD_ROOM_COUNT:
			continue

		return _build_room_specs(main_path, reward_coords, rng)

	push_warning("Random dungeon layout failed; using fallback layout.")
	return FALLBACK_ROOM_LAYOUT


static func _build_main_path(rng: RandomNumberGenerator) -> Array:
	var path := [Vector2i.ZERO]
	var occupied := {
		Vector2i.ZERO: true,
	}

	while path.size() < MAIN_PATH_ROOM_COUNT:
		var current := path[path.size() - 1] as Vector2i
		var candidates := []
		for direction: Vector2i in DIRECTIONS:
			var next_coord := current + direction
			if occupied.has(next_coord):
				continue
			if _is_outside_layout_bounds(next_coord):
				continue
			candidates.append(next_coord)

		if candidates.is_empty():
			return []

		var chosen := candidates[rng.randi_range(0, candidates.size() - 1)] as Vector2i
		path.append(chosen)
		occupied[chosen] = true

	return path


static func _build_reward_branches(main_path: Array, rng: RandomNumberGenerator) -> Array:
	var occupied := {}
	for coord in main_path:
		occupied[coord] = true

	var reward_coords := []
	while reward_coords.size() < REWARD_ROOM_COUNT:
		var candidates := []
		for path_index in range(1, main_path.size() - 1):
			var attach_coord := main_path[path_index] as Vector2i
			for direction: Vector2i in DIRECTIONS:
				var branch_coord := attach_coord + direction
				if occupied.has(branch_coord):
					continue
				if _is_outside_layout_bounds(branch_coord):
					continue
				candidates.append(branch_coord)

		if candidates.is_empty():
			return []

		var chosen := candidates[rng.randi_range(0, candidates.size() - 1)] as Vector2i
		reward_coords.append(chosen)
		occupied[chosen] = true

	return reward_coords


static func _build_room_specs(main_path: Array, reward_coords: Array, rng: RandomNumberGenerator) -> Array:
	var room_specs := []
	var label_counts := {}
	var scene_pools := _build_scene_pools()
	var main_room_types := ["combat", "combat", "weapon"]
	_shuffle_array(main_room_types, rng)
	main_room_types.append("boss")

	room_specs.append(_make_spec(Vector2i.ZERO, "start", "Start Room", START_ROOM_SCENE))

	for path_index in range(1, main_path.size()):
		var room_type := main_room_types[path_index - 1] as String
		var coord := main_path[path_index] as Vector2i
		var scene := _take_scene(scene_pools, room_type, rng)
		room_specs.append(_make_spec(coord, room_type, _next_label(room_type, label_counts), scene))

	for coord in reward_coords:
		var scene := _take_scene(scene_pools, "reward", rng)
		room_specs.append(_make_spec(coord as Vector2i, "reward", _next_label("reward", label_counts), scene))

	return room_specs


static func _build_scene_pools() -> Dictionary:
	return {
		"combat": COMBAT_ROOM_SCENES.duplicate(),
		"reward": REWARD_ROOM_SCENES.duplicate(),
		"weapon": WEAPON_ROOM_SCENES.duplicate(),
		"boss": BOSS_ROOM_SCENES.duplicate(),
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
		"reward":
			return REWARD_ROOM_SCENES
		"weapon":
			return WEAPON_ROOM_SCENES
		"boss":
			return BOSS_ROOM_SCENES
	return COMBAT_ROOM_SCENES


static func _make_spec(coord: Vector2i, room_type: String, label: String, scene: PackedScene) -> Dictionary:
	return {
		"coord": coord,
		"type": room_type,
		"label": label,
		"scene": scene,
	}


static func _next_label(room_type: String, label_counts: Dictionary) -> String:
	var count := int(label_counts.get(room_type, 0)) + 1
	label_counts[room_type] = count

	match room_type:
		"combat":
			return "Monster Room %d" % count
		"reward":
			return "Reward Room %d" % count
		"weapon":
			return "Weapon Room"
		"boss":
			return "Boss Room"
	return "Room %d" % count


static func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value


static func _is_outside_layout_bounds(coord: Vector2i) -> bool:
	return abs(coord.x) > LAYOUT_RADIUS or abs(coord.y) > LAYOUT_RADIUS
