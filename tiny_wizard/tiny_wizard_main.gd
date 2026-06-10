extends Node2D


const RUN_STATE_TUTORIAL := "tutorial"
const RUN_STATE_FORMAL := "formal"
const RUN_STATE_LAYER_COMPLETE := "layer_complete"

@export var use_generated_lab_dungeon := true
@export var play_tutorial := true
@export var dungeon_seed := 0
@export var start_room_coord := Vector2i.ZERO
@export var experimenter_character_scene: PackedScene
@export var technician_character_scene: PackedScene
@export var character_select_scene: PackedScene

var _current_room := Vector2i.ZERO
var _character: Node2D
var _character_select_screen: CharacterSelectScreen
var _selected_character_id := ""
var _run_state := ""
var _tutorial_rewards_dropped := false
var _tutorial_rewards_granted := false
var _tutorial_reward_pickups_remaining := 0
var _tutorial_hint_panel: PanelContainer
var _tutorial_hint_label: Label

var rooms := {}


func _ready():
	_current_room = start_room_coord
	$Camera2D.position = _room_camera_position(_current_room)
	_setup_tutorial_hint()
	_show_character_select()


func _collect_existing_rooms() -> Dictionary:
	var collected_rooms := {}
	for room in $Rooms.get_children():
		var room_pos = Vector2i((room.global_position - Vector2(0, 200)) / room.ROOM_SIZE)
		collected_rooms[room_pos] = room
		room.room_pos = room_pos
	return collected_rooms


func _register_rooms() -> void:
	for room_pos in rooms:
		var room = rooms[room_pos]
		var door_callable := Callable(self, "move_camera")
		if not room.door_entered.is_connected(door_callable):
			room.door_entered.connect(door_callable)

		var boss_defeated_callable := Callable(self, "_on_tutorial_boss_defeated")
		if room.has_signal("tutorial_boss_defeated") and not room.is_connected("tutorial_boss_defeated", boss_defeated_callable):
			room.connect("tutorial_boss_defeated", boss_defeated_callable)

		if room.has_method("set_weapon_holder"):
			room.call("set_weapon_holder", _get_weapon_holder())

		_connect_black_holes(room)


func _connect_black_holes(root: Node) -> void:
	if root is LabBlackHole:
		var black_hole := root as LabBlackHole
		var entered_callable := Callable(self, "_on_black_hole_entered")
		if not black_hole.entered.is_connected(entered_callable):
			black_hole.entered.connect(entered_callable)

	for child in root.get_children():
		_connect_black_holes(child)


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
	_update_tutorial_hint_for_room(start_room)


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
	_update_tutorial_hint_for_room(next_room)


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
	_bind_character_weapon_ui()
	if _character.has_signal("respawn_requested"):
		_character.connect("respawn_requested", Callable(self, "_respawn_character_at_start"))

	if play_tutorial:
		_configure_character_for_tutorial()
		_start_tutorial_run(_selected_character_id)
	else:
		_start_formal_run()


func _configure_character_for_tutorial() -> void:
	var weapon_holder := _get_weapon_holder()
	if weapon_holder == null or not weapon_holder.has_method("set_weapon_loadout"):
		return

	var starting_weapon := weapon_holder.get("starting_weapon_scene") as PackedScene
	if starting_weapon == null:
		var weapon_scenes := weapon_holder.get("weapon_scenes") as Array
		if weapon_scenes != null and not weapon_scenes.is_empty():
			starting_weapon = weapon_scenes[0] as PackedScene

	if starting_weapon != null:
		weapon_holder.set_weapon_loadout([starting_weapon], 0)


func _start_tutorial_run(wake_character_id: String) -> void:
	_run_state = RUN_STATE_TUTORIAL
	_tutorial_rewards_dropped = false
	_tutorial_rewards_granted = false
	_tutorial_reward_pickups_remaining = 0
	_current_room = start_room_coord
	rooms = LabDungeonGenerator.generate_tutorial($Rooms)
	_register_rooms()
	_update_room_doors()
	_enter_start_room(wake_character_id)


func _start_formal_run() -> void:
	_run_state = RUN_STATE_FORMAL
	_hide_tutorial_hint()
	_current_room = start_room_coord
	if use_generated_lab_dungeon:
		rooms = LabDungeonGenerator.generate($Rooms, dungeon_seed)
	else:
		rooms = _collect_existing_rooms()

	_register_rooms()
	_update_room_doors()
	_enter_start_room()


func _get_weapon_holder() -> Node:
	if _character == null:
		return null
	return _character.get_node_or_null("Visual/WeaponHolder")


func _bind_character_weapon_ui() -> void:
	var gui := $Camera2D/GUI
	if gui == null or not gui.has_method("bind_weapon_holder"):
		return

	gui.bind_weapon_holder(_get_weapon_holder())


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
	_update_tutorial_hint_for_room(start_room)
	print("Player respawned in Start Room.")


func _on_tutorial_boss_defeated() -> void:
	if _tutorial_rewards_dropped:
		return

	_tutorial_rewards_dropped = true
	_tutorial_rewards_granted = true
	_activate_tutorial_exit_black_hole()
	_show_tutorial_hint("Training complete. Enter the black hole to start the real run.")
	print("Tutorial complete. Exit black hole activated.")


func _activate_tutorial_exit_black_hole() -> void:
	var boss_room: Room = get_current_room()
	if boss_room != null and boss_room.has_method("activate_exit_black_hole"):
		boss_room.call("activate_exit_black_hole")


func _on_black_hole_entered(body: Node2D) -> void:
	if body != _character:
		return

	match _run_state:
		RUN_STATE_TUTORIAL:
			if not _tutorial_rewards_granted:
				return
			print("Tutorial complete. Entering formal dungeon.")
			call_deferred("_start_formal_run")
		RUN_STATE_FORMAL:
			call_deferred("_complete_formal_layer")


func _complete_formal_layer() -> void:
	if _run_state == RUN_STATE_LAYER_COMPLETE:
		return

	_run_state = RUN_STATE_LAYER_COMPLETE
	_show_tutorial_hint("Layer complete. Next layer will be added in a later version.")
	print("Formal layer complete.")


func _setup_tutorial_hint() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TutorialHintLayer"
	layer.layer = 20
	add_child(layer)

	_tutorial_hint_panel = PanelContainer.new()
	_tutorial_hint_panel.name = "HintPanel"
	_tutorial_hint_panel.visible = false
	_tutorial_hint_panel.anchor_left = 0.18
	_tutorial_hint_panel.anchor_top = 0.0
	_tutorial_hint_panel.anchor_right = 0.82
	_tutorial_hint_panel.anchor_bottom = 0.0
	_tutorial_hint_panel.offset_left = 0.0
	_tutorial_hint_panel.offset_top = 18.0
	_tutorial_hint_panel.offset_right = 0.0
	_tutorial_hint_panel.offset_bottom = 90.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.05, 0.06, 0.82)
	panel_style.border_color = Color(0.26, 0.68, 0.86, 0.75)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 18
	panel_style.content_margin_top = 12
	panel_style.content_margin_right = 18
	panel_style.content_margin_bottom = 12
	_tutorial_hint_panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(_tutorial_hint_panel)

	_tutorial_hint_label = Label.new()
	_tutorial_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tutorial_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_hint_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	_tutorial_hint_panel.add_child(_tutorial_hint_label)


func _update_tutorial_hint_for_room(room: Room) -> void:
	if _run_state != RUN_STATE_TUTORIAL:
		_hide_tutorial_hint()
		return

	match room.lab_room_type:
		"tutorial_start":
			_show_tutorial_hint("Press F to pick up the sword. Press 4 to equip it, then enter the room on the right.")
		"tutorial_combat":
			_show_tutorial_hint("Clear the enemies. Open the nearby chest for a bomb. Press E to place it, break the rocks, then loot the blocked chest.")
		"tutorial_boss":
			if _tutorial_rewards_granted:
				_show_tutorial_hint("Training complete. Enter the black hole to start the real run.")
			elif _tutorial_rewards_dropped:
				_show_tutorial_hint("Enter the black hole to start the real run.")
			else:
				_show_tutorial_hint("Defeat the boss, then enter the black hole to start the real run.")
		_:
			_hide_tutorial_hint()


func _show_tutorial_hint(text: String) -> void:
	if _tutorial_hint_panel == null or _tutorial_hint_label == null:
		return
	_tutorial_hint_label.text = text
	_tutorial_hint_panel.visible = true


func _hide_tutorial_hint() -> void:
	if _tutorial_hint_panel == null:
		return
	_tutorial_hint_panel.visible = false


func _print_dungeon_summary() -> void:
	var seed_text := ""
	if _run_state == RUN_STATE_FORMAL and use_generated_lab_dungeon:
		seed_text = " (seed %d)" % LabDungeonGenerator.last_seed
	print("Generated %d-room %s abandoned lab dungeon%s:" % [rooms.size(), _run_state, seed_text])
	for room_pos in rooms:
		var room = rooms[room_pos]
		print(" - ", room.lab_room_label, " [", room.lab_room_type, "] at ", room_pos)
