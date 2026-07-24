class_name ChapterFloorHUD
extends Control


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const ENTER_DURATION := 1.8
const COMPLETE_DURATION := 1.2

var _current_view_model := {}
var _current_floor_id := ""
var _completed_floor_toasts := {}

var _entry_timer: Timer
var _complete_timer: Timer
var _entry_panel: PanelContainer
var _compact_panel: PanelContainer
var _complete_panel: PanelContainer
var _entry_chapter_label: Label
var _entry_floor_label: Label
var _entry_layer_label: Label
var _entry_objective_label: Label
var _entry_threat_label: Label
var _compact_chapter_label: Label
var _compact_floor_label: Label
var _compact_progress_label: Label
var _complete_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_build_timers()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	clear_floor()


func show_floor(view_model: Dictionary) -> void:
	if view_model.is_empty():
		clear_floor()
		return

	_current_view_model = view_model.duplicate(true)
	var next_floor_id := str(_current_view_model.get("floor_id", ""))
	var entered_new_floor := next_floor_id != "" and next_floor_id != _current_floor_id
	_current_floor_id = next_floor_id
	_refresh_labels()
	visible = true
	if _compact_panel != null:
		_compact_panel.visible = true
	if entered_new_floor:
		_show_entry_prompt()


func show_floor_complete(view_model: Dictionary) -> void:
	if view_model.is_empty():
		return
	var floor_id := str(view_model.get("floor_id", ""))
	if floor_id != "" and _completed_floor_toasts.has(floor_id):
		return
	if floor_id != "":
		_completed_floor_toasts[floor_id] = true

	visible = true
	if _complete_label != null:
		_complete_label.text = str(view_model.get("completion_text", "楼层完成"))
	if _complete_panel != null:
		_complete_panel.visible = true
	if _complete_timer != null:
		_complete_timer.start(COMPLETE_DURATION)


func clear_floor() -> void:
	_current_view_model.clear()
	_current_floor_id = ""
	_completed_floor_toasts.clear()
	if _entry_timer != null:
		_entry_timer.stop()
	if _complete_timer != null:
		_complete_timer.stop()
	if _entry_panel != null:
		_entry_panel.visible = false
	if _compact_panel != null:
		_compact_panel.visible = false
	if _complete_panel != null:
		_complete_panel.visible = false
	visible = false


func get_current_view_model() -> Dictionary:
	return _current_view_model.duplicate(true)


func is_showing_floor() -> bool:
	return visible and not _current_view_model.is_empty()


func _show_entry_prompt() -> void:
	if _entry_panel != null:
		_entry_panel.visible = true
	if _entry_timer != null:
		_entry_timer.start(ENTER_DURATION)


func _refresh_labels() -> void:
	var chapter_text := str(_current_view_model.get("chapter_display", ""))
	var floor_name := str(_current_view_model.get("floor_name", ""))
	var local_index := int(_current_view_model.get("local_floor_index", 1))
	var floor_count := int(_current_view_model.get("floor_count", 1))
	var global_index := int(_current_view_model.get("global_floor_index", local_index))
	var objective := str(_current_view_model.get("objective_text", ""))
	var threat := str(_current_view_model.get("threat_label", ""))
	var progress := str(_current_view_model.get("progress_nodes", ""))
	var layer_text := "第 %d/%d 层 · 全局第%d层" % [local_index, floor_count, global_index]

	if _entry_chapter_label != null:
		_entry_chapter_label.text = chapter_text
	if _entry_floor_label != null:
		_entry_floor_label.text = floor_name
	if _entry_layer_label != null:
		_entry_layer_label.text = layer_text
	if _entry_objective_label != null:
		_entry_objective_label.text = "目标：%s" % objective
	if _entry_threat_label != null:
		_entry_threat_label.text = "威胁：%s" % threat

	if _compact_chapter_label != null:
		_compact_chapter_label.text = chapter_text
	if _compact_floor_label != null:
		_compact_floor_label.text = "%s｜%d/%d｜全局%d" % [floor_name, local_index, floor_count, global_index]
	if _compact_progress_label != null:
		_compact_progress_label.text = progress


func _build_timers() -> void:
	_entry_timer = Timer.new()
	_entry_timer.name = "EntryTimer"
	_entry_timer.one_shot = true
	_entry_timer.timeout.connect(_on_entry_timer_timeout)
	add_child(_entry_timer)

	_complete_timer = Timer.new()
	_complete_timer.name = "CompleteTimer"
	_complete_timer.one_shot = true
	_complete_timer.timeout.connect(_on_complete_timer_timeout)
	add_child(_complete_timer)


func _build_ui() -> void:
	_compact_panel = _build_compact_panel()
	add_child(_compact_panel)

	_entry_panel = _build_entry_panel()
	add_child(_entry_panel)

	_complete_panel = _build_complete_panel()
	add_child(_complete_panel)


func _build_compact_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "CompactPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.0
	panel.offset_left = -210.0
	panel.offset_top = 204.0
	panel.offset_right = 210.0
	panel.offset_bottom = 260.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style(0.82))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var layout := HBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var text_stack := VBoxContainer.new()
	text_stack.custom_minimum_size = Vector2(280, 0)
	text_stack.add_theme_constant_override("separation", 1)
	layout.add_child(text_stack)

	_compact_chapter_label = Label.new()
	_compact_chapter_label.add_theme_font_size_override("font_size", 12)
	_compact_chapter_label.add_theme_color_override("font_color", Color(0.68, 0.93, 0.98, 1.0))
	text_stack.add_child(_compact_chapter_label)

	_compact_floor_label = Label.new()
	_compact_floor_label.add_theme_font_size_override("font_size", 13)
	_compact_floor_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 1.0))
	text_stack.add_child(_compact_floor_label)

	_compact_progress_label = Label.new()
	_compact_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compact_progress_label.custom_minimum_size = Vector2(76, 0)
	_compact_progress_label.add_theme_font_size_override("font_size", 17)
	_compact_progress_label.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0, 1.0))
	layout.add_child(_compact_progress_label)

	return panel


func _build_entry_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "EntryPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.0
	panel.offset_left = -270.0
	panel.offset_top = 268.0
	panel.offset_right = 270.0
	panel.offset_bottom = 426.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style(0.9))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	_entry_chapter_label = _make_center_label(14, Color(0.42, 0.9, 0.96, 1.0))
	layout.add_child(_entry_chapter_label)

	_entry_floor_label = _make_center_label(22, Color(0.92, 0.98, 1.0, 1.0))
	layout.add_child(_entry_floor_label)

	_entry_layer_label = _make_center_label(13, Color(0.72, 0.86, 0.9, 1.0))
	layout.add_child(_entry_layer_label)

	_entry_objective_label = _make_center_label(14, Color(0.86, 0.94, 0.94, 1.0))
	_entry_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_entry_objective_label)

	_entry_threat_label = _make_center_label(13, Color(0.96, 0.82, 0.56, 1.0))
	layout.add_child(_entry_threat_label)

	return panel


func _build_complete_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "CompletePanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.0
	panel.offset_left = -190.0
	panel.offset_top = 268.0
	panel.offset_right = 190.0
	panel.offset_bottom = 322.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style(0.88))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	_complete_label = _make_center_label(18, Color(0.92, 0.98, 1.0, 1.0))
	margin.add_child(_complete_label)

	return panel


func _make_center_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _make_panel_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.052, alpha)
	style.border_color = Color(0.2, 0.68, 0.76, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func _on_entry_timer_timeout() -> void:
	if _entry_panel != null:
		_entry_panel.visible = false


func _on_complete_timer_timeout() -> void:
	if _complete_panel != null:
		_complete_panel.visible = false
	if _current_view_model.is_empty():
		visible = false
