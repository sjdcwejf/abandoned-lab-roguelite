extends CanvasLayer


const WEAPON_BACKPACK_UI_SCRIPT := preload("res://tiny_wizard/gui/weapon_backpack_ui/weapon_backpack_ui.gd")
const ABILITY_UI_SCRIPT := preload("res://tiny_wizard/gui/ability_ui/ability_ui.gd")
const PAUSE_MENU_SCENE := preload("res://tiny_wizard/gui/pause_menu/pause_menu.tscn")
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK_SCRIPT := preload("res://tiny_wizard/gui/interaction_feedback.gd")
const DEBUG_CHAPTER_MENU_SCRIPT := preload("res://tiny_wizard/gui/debug_chapter_menu/debug_chapter_menu.gd")

@export var inventory : QuiverInventory

var _weapon_backpack_ui: WeaponBackpackUI
var _ability_ui: Control
var _pause_menu: LabPauseMenu
var _interaction_feedback: LabInteractionFeedback
var _debug_chapter_menu: LabDebugChapterMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_debug_chapter_input()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	_weapon_backpack_ui = WEAPON_BACKPACK_UI_SCRIPT.new()
	_weapon_backpack_ui.name = "WeaponBackpackUI"
	add_child(_weapon_backpack_ui)

	_ability_ui = ABILITY_UI_SCRIPT.new()
	_ability_ui.name = "AbilityUI"
	add_child(_ability_ui)

	_interaction_feedback = INTERACTION_FEEDBACK_SCRIPT.new()
	_interaction_feedback.name = "InteractionFeedback"
	add_child(_interaction_feedback)

	_pause_menu = PAUSE_MENU_SCENE.instantiate() as LabPauseMenu
	_pause_menu.name = "PauseMenu"
	add_child(_pause_menu)

	_debug_chapter_menu = DEBUG_CHAPTER_MENU_SCRIPT.new()
	_debug_chapter_menu.name = "DebugChapterMenu"
	_debug_chapter_menu.chapter_entry_requested.connect(_on_debug_chapter_entry_requested)
	add_child(_debug_chapter_menu)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_chapter_menu"):
		if handle_debug_chapter_request():
			get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed("pause_game"):
		return
	if handle_pause_request():
		get_viewport().set_input_as_handled()


func handle_debug_chapter_request() -> bool:
	if _debug_chapter_menu == null:
		return false

	if _debug_chapter_menu.is_open():
		_debug_chapter_menu.close_menu()
		return true

	if _pause_menu != null and _pause_menu.is_open():
		return false

	if _weapon_backpack_ui != null and _weapon_backpack_ui.is_open():
		_weapon_backpack_ui.close_inventory()
		return true

	if not _current_scene_allows_debug_chapter_menu():
		return false

	_debug_chapter_menu.open_menu()
	return true


func handle_pause_request() -> bool:
	if _weapon_backpack_ui != null and _weapon_backpack_ui.is_open():
		_weapon_backpack_ui.close_inventory()
		return true

	if _debug_chapter_menu != null and _debug_chapter_menu.is_open():
		_debug_chapter_menu.close_menu()
		return true

	if _pause_menu != null and _pause_menu.is_open():
		_pause_menu.handle_escape()
		return true

	if not _current_scene_allows_pause():
		return false

	_pause_menu.open_menu()
	return true


func is_pause_menu_open() -> bool:
	return _pause_menu != null and _pause_menu.is_open()


func _current_scene_allows_pause() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("can_pause_game"):
		return false
	return bool(current_scene.call("can_pause_game"))


func _current_scene_allows_debug_chapter_menu() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("can_open_debug_chapter_menu"):
		return false
	return bool(current_scene.call("can_open_debug_chapter_menu"))


func _on_debug_chapter_entry_requested(chapter_id: int, target_room_type: String) -> void:
	if _debug_chapter_menu != null:
		_debug_chapter_menu.close_menu()

	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("debug_enter_chapter"):
		return
	current_scene.call("debug_enter_chapter", chapter_id, target_room_type)


func _ensure_debug_chapter_input() -> void:
	if not InputMap.has_action("debug_chapter_menu"):
		InputMap.add_action("debug_chapter_menu")
	if InputMap.action_get_events("debug_chapter_menu").is_empty():
		var key_event := InputEventKey.new()
		key_event.keycode = KEY_CTRL
		InputMap.action_add_event("debug_chapter_menu", key_event)


func bind_weapon_holder(weapon_holder: Node) -> void:
	if _weapon_backpack_ui == null:
		return
	_weapon_backpack_ui.bind_weapon_holder(weapon_holder)


func bind_ability_controller(ability_controller: Node) -> void:
	if _ability_ui == null:
		return
	_ability_ui.bind_ability_controller(ability_controller)


func bind_relic_controller(relic_controller: RelicController) -> void:
	var relic_hud := get_node_or_null("RelicHUD") as RelicHUD
	if relic_hud != null:
		relic_hud.bind_relic_controller(relic_controller)
	if _weapon_backpack_ui != null and _weapon_backpack_ui.has_method("bind_relic_controller"):
		_weapon_backpack_ui.bind_relic_controller(relic_controller)


func bind_character_stats(new_stats: QuiverCharacterStats) -> void:
	var hearts_ui := get_node_or_null("TopUI/TextureRect/MarginContainer/HBoxContainer/HeartsUI")
	if hearts_ui == null:
		return
	if hearts_ui.has_method("bind_player_stats"):
		hearts_ui.call("bind_player_stats", new_stats)


func bind_inventory(new_inventory: QuiverInventory) -> void:
	inventory = new_inventory
	if _weapon_backpack_ui != null and _weapon_backpack_ui.has_method("bind_inventory"):
		_weapon_backpack_ui.bind_inventory(inventory)
	var inventory_ui := get_node_or_null("TopUI/TextureRect/MarginContainer/HBoxContainer/InventoryUI")
	if inventory_ui == null:
		return
	if inventory_ui.has_method("bind_inventory"):
		inventory_ui.call("bind_inventory", inventory)
