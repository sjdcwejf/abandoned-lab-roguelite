extends Node2D


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const ROOM_OBJECTIVE_UI_SCRIPT := preload("res://tiny_wizard/gui/room_objective_ui/room_objective_ui.gd")
const MINIMAP_UI_SCRIPT := preload("res://tiny_wizard/gui/minimap_ui/minimap_ui.gd")
const POLLUTION_SOURCE_SCENE := preload("res://tiny_wizard/interactable_objects/pollution_source/pollution_source.tscn")
const MAIN_MENU_SCENE := "res://tiny_wizard/gui/main_menu/main_menu.tscn"
const RUN_STATE_TUTORIAL := "tutorial"
const RUN_STATE_FORMAL := "formal"
const RUN_STATE_BASE := "base"
const RUN_STATE_LAYER_COMPLETE := "layer_complete"
const FORMAL_CHAPTER_ID := 1
const CHAPTER_1_ID := 1
const CHAPTER_2_ID := 2
const POLLUTION_EVENT_LAYER := 2
const POLLUTION_EVENT_SOURCE_COUNT := 3
const POLLUTION_EVENT_SOURCE_POSITIONS := [
	Vector2(386, 226),
	Vector2(512, 326),
	Vector2(638, 226),
]

@export var use_generated_lab_dungeon := true
@export var play_tutorial := true
@export var dungeon_seed := 0
@export var start_room_coord := Vector2i.ZERO
@export var tiemu_character_scene: PackedScene
@export var liuying_character_scene: PackedScene
@export var fengqun_character_scene: PackedScene
@export var shitong_character_scene: PackedScene
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
var _layer_clear_root: Control
var _layer_clear_title_label: Label
var _layer_clear_summary_label: Label
var _layer_clear_weapons_label: Label
var _layer_clear_inventory_label: Label
var _death_prompt_root: Control
var _death_prompt_status_label: Label
var _death_prompt_title_label: Label
var _death_prompt_description_label: Label
var _death_prompt_respawn_button: Button
var _death_prompt_main_menu_button: Button
var _room_objective_ui: Node
var _minimap_ui: LabMinimapUI
var _formal_chapter_id := FORMAL_CHAPTER_ID
var _formal_chapter_title := ""
var _formal_chapter_sector := ""
var _formal_layer_index := 0
var _base_completed_chapter_id := 0
var _base_next_chapter_id := 0

var rooms := {}


func _ready():
	get_tree().paused = false
	CHINESE_FONT_BOOTSTRAP.install()
	_current_room = start_room_coord
	$Camera2D.position = _room_camera_position(_current_room)
	_setup_tutorial_hint()
	_setup_room_objective_ui()
	_setup_minimap_ui()
	_setup_layer_clear_screen()
	_setup_death_prompt_screen()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	_show_character_select()


func can_pause_game() -> bool:
	if _character_select_screen != null and is_instance_valid(_character_select_screen):
		return false
	if _layer_clear_root != null and _layer_clear_root.visible:
		return false
	if _death_prompt_root != null and _death_prompt_root.visible:
		return false
	if _run_state == RUN_STATE_LAYER_COMPLETE:
		return false
	return _character != null and is_instance_valid(_character)


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
		if room.has_method("set_relic_controller"):
			room.call("set_relic_controller", _get_relic_controller())

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
	_update_room_feedback_for_room(start_room)


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
	_update_room_feedback_for_room(next_room)


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
		_start_run_with_character(tiemu_character_scene, CharacterSelectScreen.TIEMU_ID)
		return

	var screen := character_select_scene.instantiate() as CharacterSelectScreen
	if screen == null:
		push_error("Character select scene is not a CharacterSelectScreen.")
		_start_run_with_character(tiemu_character_scene, CharacterSelectScreen.TIEMU_ID)
		return

	_character_select_screen = screen
	add_child(_character_select_screen)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(_character_select_screen)
	_character_select_screen.character_selected.connect(_on_character_selected)


func _on_character_selected(character_id: String) -> void:
	var resolved_character_id := CharacterSelectScreen.TIEMU_ID
	var character_scene := tiemu_character_scene
	match character_id:
		CharacterSelectScreen.LIUYING_ID:
			resolved_character_id = CharacterSelectScreen.LIUYING_ID
			character_scene = liuying_character_scene
		CharacterSelectScreen.FENGQUN_ID:
			resolved_character_id = CharacterSelectScreen.FENGQUN_ID
			character_scene = fengqun_character_scene
		CharacterSelectScreen.SHITONG_ID:
			resolved_character_id = CharacterSelectScreen.SHITONG_ID
			character_scene = shitong_character_scene
		CharacterSelectScreen.TIEMU_ID:
			resolved_character_id = CharacterSelectScreen.TIEMU_ID
			character_scene = tiemu_character_scene
		_:
			push_warning("未知角色 ID：'%s'。已回退为铁幕。" % character_id)

	if _character_select_screen != null:
		_character_select_screen.queue_free()
		_character_select_screen = null

	_start_run_with_character(character_scene, resolved_character_id)


func _start_run_with_character(character_scene: PackedScene, character_id := CharacterSelectScreen.TIEMU_ID) -> void:
	if character_scene == null:
		push_error("Cannot start run because no character scene was assigned.")
		return

	_selected_character_id = character_id
	_hide_layer_clear_screen()
	_hide_death_prompt(false)
	if _character != null and is_instance_valid(_character):
		_character.queue_free()

	_character = character_scene.instantiate() as Node2D
	_character.name = "Character"
	_make_character_runtime_resources_unique(_character)
	add_child(_character)
	_character.set("gui_path", NodePath("../Camera2D/GUI"))
	_initialize_character_relic_controller()
	_reset_character_inventory()
	_bind_character_weapon_ui()
	if _character.has_signal("respawn_requested"):
		_character.connect("respawn_requested", Callable(self, "_on_character_death_requested"))

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
	_reset_minimap()
	_current_room = start_room_coord
	rooms = LabDungeonGenerator.generate_tutorial($Rooms)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree($Rooms)
	_register_rooms()
	_update_room_doors()
	_enter_start_room(wake_character_id)


func _start_formal_run(layer_index := 1, chapter_id := FORMAL_CHAPTER_ID) -> void:
	_run_state = RUN_STATE_FORMAL
	_formal_chapter_id = chapter_id
	_formal_layer_index = clampi(layer_index, 1, _get_formal_layer_count())
	_formal_chapter_title = LabDungeonGenerator.get_chapter_title(_formal_chapter_id)
	_formal_chapter_sector = LabDungeonGenerator.get_chapter_sector_label(_formal_chapter_id)
	_base_completed_chapter_id = 0
	_base_next_chapter_id = 0
	_hide_tutorial_hint()
	_hide_room_objective()
	_hide_minimap()
	_hide_layer_clear_screen()
	_set_character_control_enabled(true)
	_current_room = start_room_coord
	if use_generated_lab_dungeon:
		rooms = LabDungeonGenerator.generate($Rooms, _get_formal_layer_seed(_formal_layer_index), _formal_chapter_id, _formal_layer_index)
	else:
		rooms = _collect_existing_rooms()

	_install_formal_layer_events()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree($Rooms)
	_register_rooms()
	_update_room_doors()
	_set_minimap_rooms()
	_enter_start_room()


func _start_chapter_base(completed_chapter_id: int) -> void:
	_run_state = RUN_STATE_BASE
	_base_completed_chapter_id = completed_chapter_id
	_base_next_chapter_id = LabDungeonGenerator.get_next_chapter_id(completed_chapter_id)
	_hide_tutorial_hint()
	_hide_room_objective()
	_hide_minimap()
	_hide_layer_clear_screen()
	_set_character_control_enabled(true)
	_current_room = start_room_coord
	rooms = LabDungeonGenerator.generate_chapter_base($Rooms, completed_chapter_id)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree($Rooms)
	_register_rooms()
	_update_room_doors()
	_enter_base_room()


func _enter_base_room() -> void:
	var base_room = get_current_room()
	if base_room == null:
		push_error("Base room %s was not generated." % start_room_coord)
		return

	$Camera2D.position = _room_camera_position(_current_room)
	if _character != null:
		_character.global_position = base_room.get_room_global_position() + Vector2(512, 468)
		_character.set("velocity", Vector2.ZERO)
	base_room.enter_room()
	_print_dungeon_summary()
	_update_room_feedback_for_room(base_room)


func _install_formal_layer_events() -> void:
	if _formal_chapter_id != CHAPTER_1_ID:
		return
	if _formal_layer_index != POLLUTION_EVENT_LAYER:
		return

	var pollution_room := _pick_pollution_event_room()
	if pollution_room == null:
		push_warning("第二层没有找到可安装原质污染源事件的怪物房。")
		return

	_install_pollution_source_event(pollution_room)


func _pick_pollution_event_room() -> Room:
	var candidates: Array[Room] = []
	for room_pos in rooms:
		var room := rooms[room_pos] as Room
		if room == null:
			continue
		if room.lab_room_type == "combat":
			candidates.append(room)

	if candidates.is_empty():
		return null

	candidates.sort_custom(func(a: Room, b: Room) -> bool:
		return a.room_pos.length_squared() < b.room_pos.length_squared()
	)
	return candidates[0]


func _install_pollution_source_event(room: Room) -> void:
	var container := Node2D.new()
	container.name = "PollutionSources"
	room.add_child(container)

	for index in range(POLLUTION_EVENT_SOURCE_COUNT):
		var source := POLLUTION_SOURCE_SCENE.instantiate()
		if source == null:
			continue
		source.name = "ProtomatterPollutionSource%d" % (index + 1)
		source.position = POLLUTION_EVENT_SOURCE_POSITIONS[index % POLLUTION_EVENT_SOURCE_POSITIONS.size()]
		container.add_child(source)
		if room.has_method("register_pollution_source"):
			room.call("register_pollution_source", source)

	room.lab_room_label = "%s｜污染源" % room.lab_room_label


func _get_weapon_holder() -> Node:
	if _character == null:
		return null
	return _character.get_node_or_null("Visual/WeaponHolder")


func _get_character_inventory() -> QuiverInventory:
	if _character == null:
		return null
	return _character.get("inventory") as QuiverInventory


func _get_character_stats() -> QuiverCharacterStats:
	if _character == null:
		return null
	return _character.get("character_stats") as QuiverCharacterStats


func _get_ability_controller() -> LabPlayerAbilityController:
	if _character == null:
		return null
	return _character.get_node_or_null("AbilityController") as LabPlayerAbilityController


func _get_relic_controller() -> RelicController:
	if _character == null:
		return null
	return _character.get_node_or_null("RelicController") as RelicController


func _reset_character_inventory() -> void:
	var inventory := _get_character_inventory()
	if inventory == null:
		return

	inventory.inventory.clear()
	inventory.item_counts.clear()


func _initialize_character_relic_controller() -> void:
	var relic_controller := _get_relic_controller()
	if relic_controller == null:
		return
	relic_controller.character_id = StringName(_selected_character_id)
	relic_controller.initialize(_character, null)


func _make_character_runtime_resources_unique(character: Node2D) -> void:
	if character == null:
		return

	var character_stats := character.get("character_stats") as Resource
	if character_stats != null:
		character.set("character_stats", character_stats.duplicate(true))

	var physics_stats := character.get("physics_stats") as Resource
	if physics_stats != null:
		character.set("physics_stats", physics_stats.duplicate(true))


func _bind_character_weapon_ui() -> void:
	var gui := $Camera2D/GUI
	if gui == null:
		return

	if gui.has_method("bind_inventory"):
		gui.bind_inventory(_get_character_inventory())
	if gui.has_method("bind_character_stats"):
		gui.bind_character_stats(_get_character_stats())
	if gui.has_method("bind_weapon_holder"):
		gui.bind_weapon_holder(_get_weapon_holder())
	if gui.has_method("bind_ability_controller"):
		gui.bind_ability_controller(_get_ability_controller())
	if gui.has_method("bind_relic_controller"):
		gui.bind_relic_controller(_get_relic_controller())


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
	_character.set("can_grab_items", true)
	_set_character_control_enabled(true)
	start_room.enter_room()
	_update_room_feedback_for_room(start_room)
	print("Subject respawned in Sealing Airlock.")


func _on_character_death_requested() -> void:
	if _death_prompt_root != null and _death_prompt_root.visible:
		return

	_set_character_control_enabled(false)
	if _character != null and is_instance_valid(_character):
		_character.set("can_grab_items", false)
	_show_death_prompt()


func _on_tutorial_boss_defeated() -> void:
	if _tutorial_rewards_dropped:
		return

	_tutorial_rewards_dropped = true
	_tutorial_rewards_granted = true
	_activate_tutorial_exit_black_hole()
	_show_tutorial_hint("封存唤醒序列完成。进入下行裂隙，前往正式封存区。")
	print("Sealing wake sequence complete. Descent Rift activated.")


func _activate_tutorial_exit_black_hole() -> void:
	var boss_room: Room = get_current_room()
	if boss_room != null and boss_room.has_method("activate_exit_black_hole"):
		var avoid_position: Variant = null
		if _character != null and is_instance_valid(_character):
			avoid_position = _character.global_position
		boss_room.call("activate_exit_black_hole", avoid_position)


func _on_black_hole_entered(body: Node2D) -> void:
	if body != _character:
		return

	match _run_state:
		RUN_STATE_TUTORIAL:
			if not _tutorial_rewards_granted:
				return
			print("Sealing wake sequence complete. Entering the sealed sector.")
			call_deferred("_start_formal_run", 1)
		RUN_STATE_FORMAL:
			if _formal_layer_index < _get_formal_layer_count():
				call_deferred("_start_next_formal_layer")
			elif _formal_chapter_id == CHAPTER_1_ID:
				call_deferred("_start_chapter_base", _formal_chapter_id)
			else:
				call_deferred("_complete_formal_layer")
		RUN_STATE_BASE:
			if _base_next_chapter_id > 0:
				call_deferred("_start_formal_run", 1, _base_next_chapter_id)
			else:
				call_deferred("_complete_formal_layer")


func _start_next_formal_layer() -> void:
	if _run_state != RUN_STATE_FORMAL:
		return
	var next_layer := mini(_formal_layer_index + 1, _get_formal_layer_count())
	print("Entering %s layer %d." % [_formal_chapter_title, next_layer])
	_start_formal_run(next_layer, _formal_chapter_id)


func _get_formal_layer_seed(layer_index: int) -> int:
	if dungeon_seed == 0:
		return 0
	return dungeon_seed + maxi(0, _formal_chapter_id - 1) * 1000 + maxi(0, layer_index - 1)


func _get_formal_layer_count() -> int:
	return LabDungeonGenerator.get_chapter_layer_count(_formal_chapter_id)


func _complete_formal_layer() -> void:
	if _run_state == RUN_STATE_LAYER_COMPLETE:
		return

	_run_state = RUN_STATE_LAYER_COMPLETE
	_hide_tutorial_hint()
	_hide_room_objective()
	_hide_minimap()
	_set_character_control_enabled(false)
	_show_layer_clear_screen()
	print("%s layer %d complete." % [_formal_chapter_title, _formal_layer_index])


func _set_character_control_enabled(enabled: bool) -> void:
	if _character == null or not is_instance_valid(_character):
		return

	_character.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	_character.set("velocity", Vector2.ZERO)


func _setup_layer_clear_screen() -> void:
	var layer := CanvasLayer.new()
	layer.name = "LayerClearLayer"
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	_layer_clear_root = Control.new()
	_layer_clear_root.name = "LayerClearRoot"
	_layer_clear_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer_clear_root.visible = false
	_layer_clear_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_layer_clear_root)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Color(0.0, 0.0, 0.0, 0.68)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_clear_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_clear_root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(460, 360)
	panel.add_theme_stylebox_override("panel", _make_layer_clear_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	_layer_clear_title_label = Label.new()
	_layer_clear_title_label.text = "封存协议完成"
	_layer_clear_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layer_clear_title_label.add_theme_font_size_override("font_size", 26)
	_layer_clear_title_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	layout.add_child(_layer_clear_title_label)

	_layer_clear_summary_label = Label.new()
	_layer_clear_summary_label.text = "失格者 A-03 已肃清。当前构筑快照："
	_layer_clear_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layer_clear_summary_label.add_theme_font_size_override("font_size", 14)
	_layer_clear_summary_label.add_theme_color_override("font_color", Color(0.65, 0.82, 0.88, 1.0))
	layout.add_child(_layer_clear_summary_label)

	layout.add_child(_make_layer_clear_section_title("武器构筑"))

	_layer_clear_weapons_label = Label.new()
	_layer_clear_weapons_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_layer_clear_weapons_label.add_theme_font_size_override("font_size", 14)
	_layer_clear_weapons_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.92, 1.0))
	layout.add_child(_wrap_layer_clear_detail(_layer_clear_weapons_label))

	layout.add_child(_make_layer_clear_section_title("回收物资"))

	_layer_clear_inventory_label = Label.new()
	_layer_clear_inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layer_clear_inventory_label.add_theme_font_size_override("font_size", 15)
	_layer_clear_inventory_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.92, 1.0))
	layout.add_child(_wrap_layer_clear_detail(_layer_clear_inventory_label))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	layout.add_child(buttons)

	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(150, 42)
	restart_button.pressed.connect(_restart_run_from_layer_clear)
	buttons.add_child(restart_button)

	var next_layer_button := Button.new()
	next_layer_button.text = "更深封存区：下一版本开放"
	next_layer_button.disabled = true
	next_layer_button.custom_minimum_size = Vector2(190, 42)
	buttons.add_child(next_layer_button)


func _make_layer_clear_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.075, 0.95)
	style.border_color = Color(0.25, 0.78, 0.86, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _make_layer_clear_detail_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.13, 0.92)
	style.border_color = Color(0.18, 0.28, 0.31, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


func _make_layer_clear_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.96, 1.0))
	return label


func _wrap_layer_clear_detail(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_layer_clear_detail_style())
	panel.add_child(content)
	return panel


func _show_layer_clear_screen() -> void:
	if _layer_clear_root == null:
		return
	_refresh_layer_clear_screen()
	_layer_clear_root.visible = true


func _hide_layer_clear_screen() -> void:
	if _layer_clear_root == null:
		return
	_layer_clear_root.visible = false


func _refresh_layer_clear_screen() -> void:
	if _layer_clear_title_label != null:
		_layer_clear_title_label.text = "%s｜第 %d 层完成" % [_formal_chapter_title, _formal_layer_index]
	if _layer_clear_summary_label != null:
		_layer_clear_summary_label.text = "失格者 A-03 已肃清。当前构筑快照："
	if _layer_clear_weapons_label != null:
		_layer_clear_weapons_label.text = _get_layer_clear_weapon_text()
	if _layer_clear_inventory_label != null:
		_layer_clear_inventory_label.text = _get_layer_clear_inventory_text()


func _get_layer_clear_weapon_text() -> String:
	var weapon_holder := _get_weapon_holder()
	if weapon_holder == null or not weapon_holder.has_method("get_quick_weapon_slots"):
		return "无武器。"

	var lines := PackedStringArray()
	var slots := weapon_holder.call("get_quick_weapon_slots", 4) as Array
	for slot_info in slots:
		var weapon_scene := slot_info.get("scene") as PackedScene
		if weapon_scene == null:
			continue

		var line := "%d. %s" % [
			int(slot_info.get("slot", 0)),
			str(slot_info.get("name", "武器"))
		]
		if bool(slot_info.get("equipped", false)):
			line += "  已装备"
		lines.append(line)

	if lines.is_empty():
		return "无武器。"
	return "\n".join(lines)


func _get_layer_clear_inventory_text() -> String:
	var inventory := _get_character_inventory()
	if inventory == null:
		return "原质：0    遗物：0    生物识别钥：0    破障炸药：0"

	return "原质：%d    遗物：%d    生物识别钥：%d    破障炸药：%d" % [
		inventory.get_item_amount("Protomatter Fragment"),
		inventory.get_item_amount("Relic"),
		inventory.get_item_amount("Biometric Key"),
		inventory.get_item_amount("Breach Charge")
	]


func _restart_run_from_layer_clear() -> void:
	var character_id := _selected_character_id
	if character_id == "":
		character_id = CharacterSelectScreen.TIEMU_ID

	_hide_layer_clear_screen()
	_formal_layer_index = 0
	_set_character_control_enabled(true)
	_start_run_with_character(_get_selected_character_scene(), character_id)


func _setup_death_prompt_screen() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DeathPromptLayer"
	layer.layer = 80
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	_death_prompt_root = Control.new()
	_death_prompt_root.name = "DeathPromptRoot"
	_death_prompt_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_death_prompt_root.visible = false
	_death_prompt_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_death_prompt_root)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Color(0.0, 0.0, 0.0, 0.76)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_prompt_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_prompt_root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(500, 300)
	panel.add_theme_stylebox_override("panel", _make_death_prompt_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	_death_prompt_status_label = Label.new()
	_death_prompt_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_prompt_status_label.add_theme_font_size_override("font_size", 13)
	_death_prompt_status_label.add_theme_color_override("font_color", Color(0.35, 0.86, 0.9, 1.0))
	layout.add_child(_death_prompt_status_label)

	_death_prompt_title_label = Label.new()
	_death_prompt_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_prompt_title_label.add_theme_font_size_override("font_size", 28)
	_death_prompt_title_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.58, 1.0))
	layout.add_child(_death_prompt_title_label)

	_death_prompt_description_label = Label.new()
	_death_prompt_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_prompt_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_death_prompt_description_label.add_theme_font_size_override("font_size", 14)
	_death_prompt_description_label.add_theme_color_override("font_color", Color(0.82, 0.89, 0.91, 1.0))
	layout.add_child(_death_prompt_description_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	layout.add_child(buttons)

	_death_prompt_respawn_button = Button.new()
	_death_prompt_respawn_button.custom_minimum_size = Vector2(175, 46)
	_death_prompt_respawn_button.add_theme_stylebox_override("normal", _make_death_prompt_button_style())
	_death_prompt_respawn_button.add_theme_stylebox_override("hover", _make_death_prompt_button_hover_style())
	_death_prompt_respawn_button.pressed.connect(_confirm_death_respawn)
	buttons.add_child(_death_prompt_respawn_button)

	_death_prompt_main_menu_button = Button.new()
	_death_prompt_main_menu_button.custom_minimum_size = Vector2(175, 46)
	_death_prompt_main_menu_button.add_theme_stylebox_override("normal", _make_death_prompt_danger_button_style())
	_death_prompt_main_menu_button.add_theme_stylebox_override("hover", _make_death_prompt_button_hover_style())
	_death_prompt_main_menu_button.pressed.connect(_return_to_main_menu_from_death)
	buttons.add_child(_death_prompt_main_menu_button)

	_refresh_death_prompt_text()


func _make_death_prompt_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.052, 0.98)
	style.border_color = Color(0.24, 0.72, 0.76, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _make_death_prompt_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.16, 0.18, 0.96)
	style.border_color = Color(0.24, 0.7, 0.74, 0.82)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _make_death_prompt_button_hover_style() -> StyleBoxFlat:
	var style := _make_death_prompt_button_style()
	style.bg_color = Color(0.1, 0.29, 0.31, 1.0)
	style.border_color = Color(0.45, 0.95, 0.92, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	return style


func _make_death_prompt_danger_button_style() -> StyleBoxFlat:
	var style := _make_death_prompt_button_style()
	style.bg_color = Color(0.24, 0.075, 0.06, 0.98)
	style.border_color = Color(0.92, 0.39, 0.27, 0.92)
	return style


func _show_death_prompt() -> void:
	if _death_prompt_root == null:
		return
	_refresh_death_prompt_text()
	_death_prompt_root.visible = true
	get_tree().paused = true
	if _death_prompt_respawn_button != null:
		_death_prompt_respawn_button.grab_focus()


func _hide_death_prompt(resume_world := true) -> void:
	if _death_prompt_root != null:
		_death_prompt_root.visible = false
	if resume_world:
		get_tree().paused = false


func _refresh_death_prompt_text() -> void:
	if _death_prompt_status_label != null:
		_death_prompt_status_label.text = GameSettings.tr_ui("death_status")
	if _death_prompt_title_label != null:
		_death_prompt_title_label.text = GameSettings.tr_ui("death_title")
	if _death_prompt_description_label != null:
		_death_prompt_description_label.text = GameSettings.tr_ui("death_desc")
	if _death_prompt_respawn_button != null:
		_death_prompt_respawn_button.text = GameSettings.tr_ui("death_respawn")
	if _death_prompt_main_menu_button != null:
		_death_prompt_main_menu_button.text = GameSettings.tr_ui("death_main_menu")


func _confirm_death_respawn() -> void:
	_hide_death_prompt()
	_respawn_character_at_start()


func _return_to_main_menu_from_death() -> void:
	GameSettings.save_settings()
	_hide_death_prompt()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _get_selected_character_scene() -> PackedScene:
	match _selected_character_id:
		CharacterSelectScreen.LIUYING_ID:
			return liuying_character_scene
		CharacterSelectScreen.FENGQUN_ID:
			return fengqun_character_scene
		CharacterSelectScreen.SHITONG_ID:
			return shitong_character_scene
		_:
			return tiemu_character_scene


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


func _setup_room_objective_ui() -> void:
	_room_objective_ui = ROOM_OBJECTIVE_UI_SCRIPT.new()
	if _room_objective_ui == null:
		return
	_room_objective_ui.name = "RoomObjectiveUI"
	add_child(_room_objective_ui)


func _setup_minimap_ui() -> void:
	_minimap_ui = MINIMAP_UI_SCRIPT.new()
	if _minimap_ui == null:
		return
	_minimap_ui.name = "MinimapUI"
	add_child(_minimap_ui)


func _update_room_feedback_for_room(room: Room) -> void:
	if _run_state == RUN_STATE_TUTORIAL:
		_hide_room_objective()
		_hide_minimap()
		_update_tutorial_hint_for_room(room)
		return
	if _run_state == RUN_STATE_FORMAL:
		_hide_tutorial_hint()
		_update_formal_room_feedback(room)
		return
	if _run_state == RUN_STATE_BASE:
		_hide_tutorial_hint()
		_update_base_room_feedback(room)
		return
	_hide_room_objective()
	_hide_tutorial_hint()
	_hide_minimap()


func _update_tutorial_hint_for_room(room: Room) -> void:
	if _run_state != RUN_STATE_TUTORIAL:
		_hide_tutorial_hint()
		return

	match room.lab_room_type:
		"tutorial_start":
			_show_tutorial_hint("封存协议已上线。向右移动，开始靶场同步。")
		"tutorial_targets":
			_show_tutorial_hint("用任意武器同步 A、B、C、D 四个靶标。全部点亮后，右侧门会解锁。")
		"tutorial_merchant":
			_show_tutorial_hint("渡鸦留下了一把检疫刃。按 F 拾取，按 4 装备，然后继续向右。")
		"tutorial_combat":
			_show_tutorial_hint("清理守卫样本。打开补给箱取得破障炸药，按 E 放置，炸开检疫树脂后回收物资。")
		"tutorial_boss":
			if _tutorial_rewards_granted:
				_show_tutorial_hint("封存唤醒序列完成。进入下行裂隙，前往正式封存区。")
			elif _tutorial_rewards_dropped:
				_show_tutorial_hint("进入下行裂隙，前往正式封存区。")
			else:
				_show_tutorial_hint("肃清失格者 A-03，然后进入下行裂隙。")
		_:
			_hide_tutorial_hint()


func _update_formal_room_feedback(room: Room) -> void:
	var type_label := _get_formal_room_type_label(room.lab_room_type)
	var objective := _get_formal_room_objective(room.lab_room_type)
	var room_label := room.lab_room_label
	if room_label == "":
		room_label = type_label
		room.lab_room_label = room_label

	if _room_objective_ui == null:
		_update_minimap_current_room()
		return
	_room_objective_ui.show_room(room, _formal_layer_index, type_label, objective, _formal_chapter_title)
	_update_minimap_current_room()


func _update_base_room_feedback(room: Room) -> void:
	_hide_minimap()
	if _room_objective_ui == null:
		return
	var next_title := LabDungeonGenerator.get_chapter_title(_base_next_chapter_id) if _base_next_chapter_id > 0 else "后续章节"
	_room_objective_ui.show_room(
		room,
		0,
		"临时安全屋",
		"延续当前角色与构筑，选择 1 个遗物，补给后进入%s。" % next_title,
		"渡鸦据点"
	)


func _get_formal_room_type_label(room_type: String) -> String:
	match room_type:
		"start":
			return "起点房"
		"combat":
			return "怪物房"
		"pollution":
			if _formal_chapter_id == CHAPTER_2_ID:
				return "虫巢事件房"
			return "污染事件房"
		"reward":
			return "奖励房"
		"weapon":
			return "武器房"
		"merchant":
			return "安全屋"
		"boss":
			return "Boss 房"
	return "未知区域"


func _get_formal_room_objective(room_type: String) -> String:
	match room_type:
		"start":
			if _formal_chapter_id == CHAPTER_2_ID:
				return "确认前哨构筑，进入生态温室。"
			return "确认装备状态，进入极渊前哨基地。"
		"combat":
			if _formal_chapter_id == CHAPTER_2_ID:
				return "清除孢子培养廊内的失控样本。"
			return "清除房内样本，解除门锁。"
		"pollution":
			if _formal_chapter_id == CHAPTER_2_ID:
				return "清理虫巢样本，击碎孢子囊，解除温室封锁。"
			return "清除原质污染源，并肃清房内样本。"
		"reward":
			if _formal_chapter_id == CHAPTER_2_ID:
				return "肃清温室样本库守卫，回收补给箱。"
			return "肃清守卫样本，回收补给箱。"
		"weapon":
			if _formal_chapter_id == CHAPTER_2_ID:
				return "回收渡鸦温室军械，整理当前构筑。"
			return "回收随机军械，整理当前构筑。"
		"merchant":
			if _formal_chapter_id == CHAPTER_2_ID:
				return "在渡鸦温室补给站交易，准备进入培育舱。"
			return "与渡鸦交易，补充装备后前往下一房间。"
		"boss":
			return LabDungeonGenerator.get_chapter_boss_objective(_formal_chapter_id)
	return ""


func _show_tutorial_hint(text: String) -> void:
	if _tutorial_hint_panel == null or _tutorial_hint_label == null:
		return
	_tutorial_hint_label.text = text
	_tutorial_hint_panel.visible = true


func _hide_tutorial_hint() -> void:
	if _tutorial_hint_panel == null:
		return
	_tutorial_hint_panel.visible = false


func _hide_room_objective() -> void:
	if _room_objective_ui == null:
		return
	_room_objective_ui.hide_objective()


func _set_minimap_rooms() -> void:
	if _minimap_ui == null:
		return
	_minimap_ui.set_rooms(rooms, _formal_layer_index, _formal_chapter_title)


func _update_minimap_current_room() -> void:
	if _minimap_ui == null:
		return
	if _run_state != RUN_STATE_FORMAL:
		_minimap_ui.hide_map()
		return
	_minimap_ui.update_current_room(_current_room)


func _hide_minimap() -> void:
	if _minimap_ui == null:
		return
	_minimap_ui.hide_map()


func _reset_minimap() -> void:
	if _minimap_ui == null:
		return
	_minimap_ui.reset_map()


func _print_dungeon_summary() -> void:
	var seed_text := ""
	if _run_state == RUN_STATE_FORMAL and use_generated_lab_dungeon:
		seed_text = " (seed %d)" % LabDungeonGenerator.last_seed
	var chapter_text := ""
	if _run_state == RUN_STATE_FORMAL:
		chapter_text = " %s / %s" % [_formal_chapter_title, _formal_chapter_sector]
	elif _run_state == RUN_STATE_BASE:
		chapter_text = " 临时安全屋 / 渡鸦据点"
	print("Generated %d-room %s%s sector%s:" % [rooms.size(), _run_state, chapter_text, seed_text])
	for room_pos in rooms:
		var room = rooms[room_pos]
		print(" - ", room.lab_room_label, " [", room.lab_room_type, "] at ", room_pos)
