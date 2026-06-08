class_name LabDungeonGenerator
extends RefCounted


const START_ROOM_SCENE := preload("res://tiny_wizard/room/room.tscn")
const COMBAT_ROOM_A_SCENE := preload("res://tiny_wizard/room/room_types/room_1.tscn")
const COMBAT_ROOM_B_SCENE := preload("res://tiny_wizard/room/room_types/room_2.tscn")
const REWARD_ROOM_A_SCENE := preload("res://tiny_wizard/room/room_types/lab_reward_bomb_room.tscn")
const REWARD_ROOM_B_SCENE := preload("res://tiny_wizard/room/room_types/lab_reward_guarded_room.tscn")
const WEAPON_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/room_4.tscn")
const BOSS_ROOM_SCENE := preload("res://tiny_wizard/room/room_types/lab_boss_room.tscn")

const START_ROOM_OFFSET := Vector2(0, 200)

const ROOM_LAYOUT := [
	{
		"coord": Vector2i(0, 0),
		"type": "start",
		"label": "Start Room",
		"scene": START_ROOM_SCENE,
	},
	{
		"coord": Vector2i(1, 0),
		"type": "combat",
		"label": "Monster Room A",
		"scene": COMBAT_ROOM_A_SCENE,
	},
	{
		"coord": Vector2i(2, 0),
		"type": "combat",
		"label": "Monster Room B",
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
		"label": "Reward Room A",
		"scene": REWARD_ROOM_A_SCENE,
	},
	{
		"coord": Vector2i(2, 1),
		"type": "reward",
		"label": "Reward Room B",
		"scene": REWARD_ROOM_B_SCENE,
	},
]


static func generate(rooms_parent: Node2D) -> Dictionary:
	_clear_existing_rooms(rooms_parent)

	var generated_rooms := {}
	for spec in ROOM_LAYOUT:
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
