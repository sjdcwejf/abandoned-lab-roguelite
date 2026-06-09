extends Node2D


@export var use_generated_lab_dungeon := true
@export var dungeon_seed := 0
@export var start_room_coord := Vector2i.ZERO
@export var experimenter_character_scene: PackedScene
@export var technician_character_scene: PackedScene
@export var character_select_scene: PackedScene

var _current_room := Vector2i.ZERO
var _character: Node2D
var _character_select_screen: CharacterSelectScreen
var _selected_character_id := ""

var rooms := {}

func _ready():
	_current_room = start_room_coord
	if use_generated_lab_dungeon:
		rooms = LabDungeonGenerator.generate($Rooms, dungeon_seed)
	else:
		rooms = _collect_existing_rooms()

	_register_rooms()
	_update_room_doors()
	$Camera2D.position = _room_camera_position(_current_room)
	_show_character_select()


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


func _enter_start_room(wake_character_id := "") -> void:
	var start_room = get_current_room()
	if start_room == null:
		push_error("Start room %s was not generated." % start_room_coord)
		return

	$Camera2D.position = _room_camera_position(_current_room)
	_character.global_position = _get_start_spawn_position(start_room, wake_character_id)
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
	if _character != null:
		_character.global_position = next_room.get_spawning_point(direction).global_position
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


func _room_center(room: Room) -> Vector2:
	return room.get_room_global_position() + room.ROOM_SIZE * 0.5


func _get_start_spawn_position(start_room: Room, character_id: String) -> Vector2:
	var sleep_pod := _find_sleep_pod(start_room, character_id)
	if sleep_pod == null:
		return _room_center(start_room)

	sleep_pod.wake_up()
	return sleep_pod.get_wake_position()


func _find_sleep_pod(root: Node, character_id: String) -> LabSleepPod:
	if root is LabSleepPod:
		var pod := root as LabSleepPod
		if pod.character_id == character_id:
			return pod

	for child in root.get_children():
		var found := _find_sleep_pod(child, character_id)
		if found != null:
			return found
	return null


func _show_character_select() -> void:
	if character_select_scene == null:
		_start_run_with_character(experimenter_character_scene)
		return

	var screen := character_select_scene.instantiate() as CharacterSelectScreen
	if screen == null:
		push_error("Character select scene is not a CharacterSelectScreen.")
		_start_run_with_character(experimenter_character_scene)
		return

	_character_select_screen = screen
	add_child(_character_select_screen)
	_character_select_screen.character_selected.connect(_on_character_selected)


func _on_character_selected(character_id: String) -> void:
	var character_scene := experimenter_character_scene
	match character_id:
		CharacterSelectScreen.TECHNICIAN_ID:
			character_scene = technician_character_scene
		CharacterSelectScreen.EXPERIMENTER_ID:
			character_scene = experimenter_character_scene

	if _character_select_screen != null:
		_character_select_screen.queue_free()
		_character_select_screen = null

	_start_run_with_character(character_scene, character_id)


func _start_run_with_character(character_scene: PackedScene, character_id := CharacterSelectScreen.EXPERIMENTER_ID) -> void:
	if character_scene == null:
		push_error("Cannot start run because no character scene was assigned.")
		return

	_selected_character_id = character_id
	if _character != null and is_instance_valid(_character):
		_character.queue_free()

	_character = character_scene.instantiate() as Node2D
	_character.name = "Character"
	add_child(_character)
	_character.set("gui_path", NodePath("../Camera2D/GUI"))
	if _character.has_signal("respawn_requested"):
		_character.connect("respawn_requested", Callable(self, "_respawn_character_at_start"))

	_enter_start_room(_selected_character_id)


func _respawn_character_at_start() -> void:
	var start_room = get_room(start_room_coord)
	if start_room == null:
		push_error("Cannot respawn because start room %s does not exist." % start_room_coord)
		return
	if _character == null:
		return

	_current_room = start_room_coord
	$Camera2D.position = _room_camera_position(_current_room)
	_character.global_position = _room_center(start_room)
	_character.set("velocity", Vector2.ZERO)
	var character_stats := _character.get("character_stats") as QuiverCharacterStats
	if character_stats != null:
		character_stats.set_life_to_max()
	start_room.enter_room()
	print("Player respawned in Start Room.")


func _print_dungeon_summary() -> void:
	var seed_text := ""
	if use_generated_lab_dungeon:
		seed_text = " (seed %d)" % LabDungeonGenerator.last_seed
	print("Generated %d-room abandoned lab dungeon%s:" % [rooms.size(), seed_text])
	for room_pos in rooms:
		var room = rooms[room_pos]
		print(" - ", room.lab_room_label, " [", room.lab_room_type, "] at ", room_pos)
