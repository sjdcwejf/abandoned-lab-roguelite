class_name LabDebugChapterMenu
extends Control


signal chapter_entry_requested(chapter_id: int, target_room_type: String)


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

var _target_option: OptionButton
var _first_chapter_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	z_index = 120
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("debug_chapter_menu") or event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	if _first_chapter_button != null:
		_first_chapter_button.grab_focus()


func close_menu(resume_world := true) -> void:
	if not visible:
		return
	visible = false
	if resume_world:
		get_tree().paused = false


func is_open() -> bool:
	return visible


func _build_layout() -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(520, 520)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var status := Label.new()
	status.text = "开发工具 / 章节跳转"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color(0.35, 0.9, 0.93, 1.0))
	layout.add_child(status)

	var title := Label.new()
	title.text = "开发章节入口"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	layout.add_child(title)

	var hint := Label.new()
	hint.text = "选择章节后默认保留当前构筑、武器词条、遗物和资源，只切换测试章节。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.64, 0.78, 0.82, 1.0))
	layout.add_child(hint)

	var separator := HSeparator.new()
	layout.add_child(separator)

	var target_label := Label.new()
	target_label.text = "进入位置"
	target_label.add_theme_font_size_override("font_size", 14)
	target_label.add_theme_color_override("font_color", Color(0.45, 0.94, 0.96, 1.0))
	layout.add_child(target_label)

	_target_option = OptionButton.new()
	_target_option.custom_minimum_size = Vector2(440, 38)
	_target_option.add_theme_stylebox_override("normal", _make_button_style())
	_target_option.add_theme_stylebox_override("hover", _make_button_hover_style())
	layout.add_child(_target_option)
	_add_target_options()

	var chapter_label := Label.new()
	chapter_label.text = "选择章节"
	chapter_label.add_theme_font_size_override("font_size", 14)
	chapter_label.add_theme_color_override("font_color", Color(0.45, 0.94, 0.96, 1.0))
	layout.add_child(chapter_label)

	for entry in _get_chapter_entries():
		var button := Button.new()
		var chapter_id: int = int(entry.get("chapter", 0))
		button.text = str(entry.get("label", "章节"))
		button.custom_minimum_size = Vector2(440, 42)
		button.add_theme_stylebox_override("normal", _make_button_style())
		button.add_theme_stylebox_override("hover", _make_button_hover_style())
		button.pressed.connect(_on_chapter_pressed.bind(chapter_id))
		layout.add_child(button)
		if _first_chapter_button == null:
			_first_chapter_button = button

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(440, 40)
	close_button.add_theme_stylebox_override("normal", _make_danger_button_style())
	close_button.add_theme_stylebox_override("hover", _make_button_hover_style())
	close_button.pressed.connect(close_menu)
	layout.add_child(close_button)


func _add_target_options() -> void:
	var entries: Array[Dictionary] = [
		{"label": "出生房", "target": "none"},
		{"label": "事件房", "target": "event"},
		{"label": "武器房", "target": "weapon"},
		{"label": "Boss 前补给站", "target": "pre_boss_shop"},
		{"label": "Boss 房", "target": "boss"},
	]
	for index in range(entries.size()):
		var entry := entries[index]
		_target_option.add_item(str(entry.get("label", "入口")), index)
		_target_option.set_item_metadata(index, str(entry.get("target", "none")))


func _get_chapter_entries() -> Array[Dictionary]:
	return [
		{"chapter": 1, "label": "第一章：极渊前哨基地"},
		{"chapter": 2, "label": "第二章：生态温室"},
		{"chapter": 3, "label": "第三章：低温封存区"},
		{"chapter": 4, "label": "第四章：外骨骼兵器工厂"},
		{"chapter": 5, "label": "第五章：数据中枢"},
	]


func _on_chapter_pressed(chapter_id: int) -> void:
	var target_room_type: String = "none"
	if _target_option != null:
		var metadata_value: Variant = _target_option.get_item_metadata(_target_option.selected)
		target_room_type = str(metadata_value)
	chapter_entry_requested.emit(chapter_id, target_room_type)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.052, 0.98)
	style.border_color = Color(0.22, 0.76, 0.8, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _make_button_style() -> StyleBoxFlat:
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


func _make_button_hover_style() -> StyleBoxFlat:
	var style := _make_button_style()
	style.bg_color = Color(0.1, 0.29, 0.31, 1.0)
	style.border_color = Color(0.45, 0.95, 0.92, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	return style


func _make_danger_button_style() -> StyleBoxFlat:
	var style := _make_button_style()
	style.bg_color = Color(0.18, 0.07, 0.065, 0.96)
	style.border_color = Color(0.84, 0.32, 0.25, 0.85)
	return style
