class_name LabDataArchiveTerminal
extends Node2D


signal archive_read(terminal: LabDataArchiveTerminal)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")

@export var archive_id := ""
@export var archive_title := "数据档案"
@export_multiline var archive_content := ""
@export var success_message := "数据档案已同步"
@export var clue_id := ""
@export var unlock_ending_hints := false
@export var requires_ending_hints := false
@export var prompt_text := "按 F 读取档案"
@export var locked_message := "权限不足：先读取公司黑匣子档案。"
@export var read_once := true
@export var accent_color := Color(0.34, 0.92, 1.0, 1.0)

var _candidate_character: Node2D
var _read := false
var _visual_time := 0.0

@onready var interact_area: Area2D = get_node_or_null("InteractArea") as Area2D
@onready var screen_light: Polygon2D = get_node_or_null("ScreenLight") as Polygon2D
@onready var prompt_label: Label = get_node_or_null("Prompt") as Label
@onready var archive_panel: PanelContainer = get_node_or_null("ArchivePanel") as PanelContainer
@onready var archive_label: Label = get_node_or_null("ArchivePanel/Margin/Content") as Label


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	if interact_area != null:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
	if prompt_label != null:
		prompt_label.text = prompt_text
		prompt_label.visible = false
	if archive_panel != null:
		archive_panel.visible = false
	if screen_light != null:
		screen_light.color = accent_color


func _process(delta: float) -> void:
	_visual_time += delta
	if screen_light != null:
		var pulse := (sin(_visual_time * 5.2) + 1.0) * 0.5
		screen_light.color = accent_color.lerp(Color.WHITE, 0.18 * pulse)
	if _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		_try_read_archive()


func _on_body_entered(body: Node2D) -> void:
	if body == null or not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	if prompt_label != null:
		prompt_label.visible = false


func _try_read_archive() -> void:
	if _candidate_character == null:
		return
	if read_once and _read:
		INTERACTION_FEEDBACK.show_from(self, "该档案已同步。", 1.2)
		return
	if requires_ending_hints and not _main_has_ending_hints_unlocked():
		INTERACTION_FEEDBACK.show_from(self, locked_message, 1.5)
		return

	_read = true
	if prompt_label != null:
		prompt_label.visible = false
	_show_archive_panel()
	_record_archive_to_main()
	archive_read.emit(self)


func _show_archive_panel() -> void:
	if archive_panel == null or archive_label == null:
		return
	var content := archive_content.strip_edges()
	if content == "":
		content = "未发现可读数据。"
	archive_label.text = "%s\n\n%s" % [archive_title, content]
	archive_panel.visible = true


func _record_archive_to_main() -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("record_data_archive"):
		main.call("record_data_archive", {
			"archive_id": archive_id,
			"title": archive_title,
			"content": archive_content,
			"success_message": success_message,
			"clue_id": clue_id,
			"unlock_ending_hints": unlock_ending_hints,
		})
		return
	INTERACTION_FEEDBACK.show_from(self, success_message, 1.4)


func _main_has_ending_hints_unlocked() -> bool:
	var main := get_tree().current_scene
	if main != null and main.has_method("are_ending_hints_unlocked"):
		return bool(main.call("are_ending_hints_unlocked"))
	return false


func _refresh_prompt() -> void:
	if prompt_label == null:
		return
	if _candidate_character == null:
		prompt_label.visible = false
		return
	if read_once and _read:
		prompt_label.visible = false
		return
	prompt_label.text = prompt_text
	prompt_label.visible = true
