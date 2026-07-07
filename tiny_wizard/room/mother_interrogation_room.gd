class_name MotherInterrogationRoom
extends Room


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

const RESPONSE_REFUSE := "refuse"
const RESPONSE_CONNECT := "connect"
const RESPONSE_REWRITE := "rewrite"

const SCAN_TEXT := "母体信号接入中……\n检测到遗物共鸣。\n检测到非稳定生命序列。\n检测到外部渡鸦通信痕迹。\n检测到异常存活记录。\n检测到召回协议偏移。\n请选择回应方式。"

var _choice_layer: CanvasLayer
var _choice_root: Control
var _choice_buttons: Array[Button] = []
var _result_label: Label
var _confirm_button: Button
var _ui_open := false


func _ready() -> void:
	super._ready()
	lock_chests_until_cleared = false
	if room_objective.is_empty():
		set_room_objective({
			"type": Room.OBJECTIVE_READ_ARCHIVE,
			"objective_text": "回应母体信号。",
			"completion_text": "母体回应已记录。",
		})
	set_meta("event_objective_text", "回应母体信号。")
	set_meta("event_completion_text", "母体回应已记录。")


func enter_room() -> void:
	if _is_interrogation_completed():
		_finish_interrogation_room(false)
		return

	if room_state == ROOM_STATE_NOT_VISITED:
		room_state = ROOM_STATE_IN_PROGRESS

	objective_progress_changed.emit(self)
	for direction in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		close_door(direction)

	if not _ui_open:
		call_deferred("_open_interrogation_ui")


func _open_interrogation_ui() -> void:
	if _ui_open or _is_interrogation_completed():
		return
	_ui_open = true
	_set_player_control(false)

	_choice_layer = CanvasLayer.new()
	_choice_layer.name = "MotherInterrogationChoiceLayer"
	_choice_layer.layer = 95
	_choice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var ui_parent: Node = _get_ui_parent()
	ui_parent.add_child(_choice_layer)

	_choice_root = Control.new()
	_choice_root.name = "MotherInterrogationChoiceRoot"
	_choice_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_choice_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_layer.add_child(_choice_root)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(560, 500)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "母体信号接入"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
	layout.add_child(title)

	var scan_label := Label.new()
	scan_label.text = _get_scan_text()
	scan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scan_label.add_theme_font_size_override("font_size", 15)
	scan_label.add_theme_color_override("font_color", Color(0.68, 0.86, 0.92, 1.0))
	layout.add_child(_wrap_detail(scan_label))

	_choice_buttons.clear()
	for entry in _get_choice_entries():
		var choice := entry as Dictionary
		var button := Button.new()
		button.text = "%s\n%s" % [str(choice.get("label", "")), str(choice.get("description", ""))]
		button.custom_minimum_size = Vector2(500, 58)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", _make_button_style())
		button.add_theme_stylebox_override("hover", _make_button_hover_style())
		button.pressed.connect(_on_choice_pressed.bind(str(choice.get("type", RESPONSE_REFUSE))))
		layout.add_child(button)
		_choice_buttons.append(button)

	_result_label = Label.new()
	_result_label.visible = false
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.96, 1.0))
	layout.add_child(_wrap_detail(_result_label))

	_confirm_button = Button.new()
	_confirm_button.text = "确认回应"
	_confirm_button.visible = false
	_confirm_button.custom_minimum_size = Vector2(500, 42)
	_confirm_button.add_theme_stylebox_override("normal", _make_button_style())
	_confirm_button.add_theme_stylebox_override("hover", _make_button_hover_style())
	_confirm_button.pressed.connect(_on_confirm_pressed)
	layout.add_child(_confirm_button)

	CHINESE_FONT_BOOTSTRAP.apply_to_tree(_choice_root)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _on_choice_pressed(response_type: String) -> void:
	if _is_interrogation_completed():
		return

	var main := _get_main()
	if main != null and main.has_method("record_mother_interrogation_response"):
		main.call("record_mother_interrogation_response", response_type)

	for button in _choice_buttons:
		button.disabled = true
		button.visible = false

	if _result_label != null:
		_result_label.text = _get_response_result_text(response_type)
		_result_label.visible = true
	if _confirm_button != null:
		_confirm_button.visible = true
		_confirm_button.grab_focus()


func _on_confirm_pressed() -> void:
	_close_interrogation_ui()
	_finish_interrogation_room(true)


func _finish_interrogation_room(show_feedback: bool) -> void:
	for direction in [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]:
		open_door(direction)
	_mark_room_cleared()
	if show_feedback:
		var main := _get_main()
		if main != null and main.has_method("show_story_feedback"):
			main.call("show_story_feedback", "母体回应已记录。", 1.3)


func _close_interrogation_ui() -> void:
	_set_player_control(true)
	_ui_open = false
	if _choice_layer != null and is_instance_valid(_choice_layer):
		_choice_layer.queue_free()
	_choice_layer = null
	_choice_root = null
	_choice_buttons.clear()
	_result_label = null
	_confirm_button = null


func _get_scan_text() -> String:
	var text := SCAN_TEXT
	var main := _get_main()
	if main != null and main.has_method("is_raven_hidden_quest_unlocked") and bool(main.call("is_raven_hidden_quest_unlocked")):
		text += "\n检测到历史开门记录。通信源：渡鸦。"
	return text


func _get_choice_entries() -> Array[Dictionary]:
	return [
		{
			"type": RESPONSE_REFUSE,
			"label": "拒绝接入",
			"description": "切断母体信号，不回应召回。",
		},
		{
			"type": RESPONSE_CONNECT,
			"label": "短暂接入",
			"description": "读取母体记忆，但暴露自身位置。",
		},
		{
			"type": RESPONSE_REWRITE,
			"label": "反向篡改",
			"description": "篡改召回协议，让母体误判你的状态。",
		},
	]


func _get_response_result_text(response_type: String) -> String:
	match response_type:
		RESPONSE_CONNECT:
			return "你听见了母体的记忆。\n那些遗物并不是被发现的。\n它们是被投放的。\n渡鸦的通信记录在黑暗中闪烁了一瞬。"
		RESPONSE_REWRITE:
			return "协议开始回读自身。\n母体短暂失去了对你的识别。\n你听见一个错误的声音：\n样本状态：不可归类。"
	return "你切断了母体信号。\n遗物的低鸣逐渐平息。\n远处的核心短暂沉默。"


func _is_interrogation_completed() -> bool:
	var main := _get_main()
	if main != null and main.has_method("is_mother_interrogation_completed"):
		return bool(main.call("is_mother_interrogation_completed"))
	return is_cleared


func _set_player_control(enabled: bool) -> void:
	var main := _get_main()
	if main != null and main.has_method("_set_character_control_enabled"):
		main.call("_set_character_control_enabled", enabled)


func _get_main() -> Node:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		return current_scene
	return null


func _get_ui_parent() -> Node:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		return current_scene
	return self


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.026, 0.052, 0.97)
	style.border_color = Color(0.47, 0.22, 0.72, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _make_detail_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.068, 0.09, 0.82)
	style.border_color = Color(0.18, 0.28, 0.38, 0.8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style


func _make_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.095, 0.064, 0.13, 0.95)
	style.border_color = Color(0.38, 0.2, 0.6, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style


func _make_button_hover_style() -> StyleBoxFlat:
	var style := _make_button_style()
	style.bg_color = Color(0.16, 0.09, 0.22, 1.0)
	style.border_color = Color(0.63, 0.34, 0.86, 0.95)
	return style


func _wrap_detail(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_detail_style())
	panel.add_child(content)
	return panel
