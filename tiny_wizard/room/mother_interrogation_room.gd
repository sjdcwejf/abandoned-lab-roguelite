class_name MotherInterrogationRoom
extends Room


const CORE_OBJECTIVE_TEXT := "激活核心终端。"
const CORE_COMPLETION_TEXT := "核心干扰已清除。出口已开启。"

var _terminal_connected := false


func _ready() -> void:
	super._ready()
	lock_chests_until_cleared = false
	set_room_objective({
		"type": Room.OBJECTIVE_READ_ARCHIVE,
		"objective_text": CORE_OBJECTIVE_TEXT,
		"completion_text": CORE_COMPLETION_TEXT,
	})
	set_meta("event_objective_text", CORE_OBJECTIVE_TEXT)
	set_meta("event_completion_text", CORE_COMPLETION_TEXT)
	call_deferred("_connect_core_terminal")


func enter_room() -> void:
	if is_cleared:
		_open_all_doors()
		return

	if room_state == ROOM_STATE_NOT_VISITED:
		room_state = ROOM_STATE_IN_PROGRESS

	objective_progress_changed.emit(self)
	_close_all_doors()
	call_deferred("_connect_core_terminal")


func _connect_core_terminal() -> void:
	if _terminal_connected:
		return

	var terminal := find_child("CoreInterferenceTerminal", true, false)
	if terminal == null:
		terminal = _find_archive_terminal(self)
	if terminal == null:
		return

	if terminal.has_signal("archive_read"):
		var callable := Callable(self, "_on_core_terminal_activated")
		if not terminal.is_connected("archive_read", callable):
			terminal.connect("archive_read", callable)
		_terminal_connected = true


func _find_archive_terminal(root: Node) -> Node:
	for child in root.get_children():
		if child is LabDataArchiveTerminal:
			return child
		var nested := _find_archive_terminal(child)
		if nested != null:
			return nested
	return null


func _on_core_terminal_activated(_terminal: LabDataArchiveTerminal) -> void:
	if is_cleared:
		return
	_open_all_doors()
	_mark_room_cleared()
	var main := _get_main()
	if main != null and main.has_method("show_story_feedback"):
		main.call("show_story_feedback", CORE_COMPLETION_TEXT, 1.3)


func _open_all_doors() -> void:
	for direction in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		open_door(direction)


func _close_all_doors() -> void:
	for direction in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		close_door(direction)


func _get_main() -> Node:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		return current_scene
	return null
