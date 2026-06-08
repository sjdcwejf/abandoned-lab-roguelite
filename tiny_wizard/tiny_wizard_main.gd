extends Node2D


@export var use_generated_lab_dungeon := true
@export var start_room_coord := Vector2i.ZERO

var _current_room := Vector2i.ZERO

var rooms := {}

func _ready():
	_current_room = start_room_coord
	if use_generated_lab_dungeon:
		rooms = LabDungeonGenerator.generate($Rooms)
	else:
		rooms = _collect_existing_rooms()

	_register_rooms()
	_update_room_doors()
	_enter_start_room()


func _collect_existing_rooms() -> Dictionary:
	var collected_rooms := {}
	for room in $Rooms.get_children():
		var room_pos = Vector2i((room.global_position - Vector2(0,200)) / room.ROOM_SIZE)
		collected_rooms[room_pos] = room
		room.room_pos = room_pos
	return collected_rooms


func _register_rooms() -> void:
	for room_pos in rooms:
		var room = rooms[room_pos]
		room.door_entered.connect(self.move_camera)


func _update_room_doors() -> void:
	for room_pos in rooms:
		var room = rooms[room_pos]
		room.hide_right_door = !rooms.has(room_pos + Vector2i.RIGHT)
		room.hide_down_door = !rooms.has(room_pos + Vector2i.DOWN)
		room.hide_left_door = !rooms.has(room_pos + Vector2i.LEFT)
		room.hide_up_door = !rooms.has(room_pos + Vector2i.UP)
		room.update_doors()


func _enter_start_room() -> void:
	var start_room = get_current_room()
	if start_room == null:
		push_error("Start room %s was not generated." % start_room_coord)
		return

	$Camera2D.position = _room_camera_position(_current_room)
	$Character.global_position = start_room.get_room_global_position() + start_room.ROOM_SIZE * 0.5
	start_room.enter_room()
	_print_dungeon_summary()


func move_camera(direction: Vector2):
	var room_step := Vector2i(direction)
	var target_room := _current_room + room_step
	var next_room = get_room(target_room)
	if next_room == null:
		return

	_current_room = target_room
	print(
		"Entering ", next_room.lab_room_label,
		" ", next_room.get_room_matrix_position(),
		" at position ", next_room.get_room_global_position(),
		" covering area ", next_room.get_room_rect()
		)
	$Camera2D.position = _room_camera_position(_current_room)
	$Character.global_position = next_room.get_spawning_point(direction).global_position
	next_room.enter_room()


func get_room(room_coord: Vector2i):
	if rooms.has(room_coord):
		return rooms[room_coord]
	else:
		return null

func get_current_room():
	return get_room(_current_room)


func _room_camera_position(room_coord: Vector2i) -> Vector2:
	return Vector2(room_coord.x, room_coord.y) * Room.ROOM_SIZE


func _print_dungeon_summary() -> void:
	print("Generated 7-room abandoned lab dungeon:")
	for room_pos in rooms:
		var room = rooms[room_pos]
		print(" - ", room.lab_room_label, " [", room.lab_room_type, "] at ", room_pos)
