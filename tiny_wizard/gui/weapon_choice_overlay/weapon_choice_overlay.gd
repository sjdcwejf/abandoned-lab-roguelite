class_name LabWeaponChoiceOverlay
extends Control


signal confirmed(slot_index: int)
signal cancelled

const MAX_QUICK_SLOTS := 4
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

var weapon_holder: Node
var new_weapon_scene: PackedScene
var new_weapon_affixes: Array = []
var title_text := "武器对比"
var action_text := "拾取"
var cost_text := ""
var allow_empty_slot := true

var _previous_pause_state := false
var _closed := false
var _requires_replacement := false
var _primary_button: Button
var _slot_buttons: Array[Button] = []


static func present(owner: Node, params: Dictionary) -> LabWeaponChoiceOverlay:
	var overlay := LabWeaponChoiceOverlay.new()
	overlay.setup(params)
	var parent := _resolve_overlay_parent(owner)
	parent.add_child(overlay)
	return overlay


static func _resolve_overlay_parent(owner: Node) -> Node:
	if owner == null:
		return null

	var tree := owner.get_tree()
	if tree == null:
		return owner

	var current_scene := tree.current_scene
	if current_scene == null:
		return owner

	var gui := current_scene.get_node_or_null("GUI")
	if gui != null:
		return gui
	return current_scene


func setup(params: Dictionary) -> void:
	weapon_holder = params.get("weapon_holder") as Node
	new_weapon_scene = params.get("weapon_scene") as PackedScene
	var affixes = params.get("weapon_affixes", [])
	new_weapon_affixes = affixes.duplicate() if affixes is Array else []
	title_text = str(params.get("title", title_text))
	action_text = str(params.get("action", action_text))
	cost_text = str(params.get("cost", ""))
	allow_empty_slot = bool(params.get("allow_empty_slot", true))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_previous_pause_state = get_tree().paused
	get_tree().paused = true
	_requires_replacement = not allow_empty_slot
	_build_ui()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	call_deferred("_focus_default_button")


func _unhandled_input(event: InputEvent) -> void:
	if _closed:
		return

	if _event_pressed(event, "pause_game") or _event_pressed(event, "ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
		return

	if allow_empty_slot and _event_pressed(event, "interact"):
		_confirm(-1)
		get_viewport().set_input_as_handled()
		return

	for slot_index in range(MAX_QUICK_SLOTS):
		var action_name := "weapon_slot_%d" % (slot_index + 1)
		if _event_pressed(event, action_name) and _requires_replacement:
			_confirm(slot_index)
			get_viewport().set_input_as_handled()
			return


func _exit_tree() -> void:
	if not _closed and get_tree() != null:
		get_tree().paused = _previous_pause_state


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.62)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(720, 438)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.78, 1.0, 0.98, 1.0))
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _get_subtitle_text()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.74, 0.86, 0.88, 1.0))
	layout.add_child(subtitle)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	layout.add_child(content)

	content.add_child(_make_new_weapon_card())
	content.add_child(_make_slot_list())

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(footer)

	_primary_button = Button.new()
	_primary_button.custom_minimum_size = Vector2(210, 36)
	_primary_button.text = "%s到空武器位 (F)" % action_text
	_primary_button.disabled = _requires_replacement
	_primary_button.pressed.connect(func() -> void: _confirm(-1))
	footer.add_child(_primary_button)

	var cancel_button := Button.new()
	cancel_button.custom_minimum_size = Vector2(124, 36)
	cancel_button.text = "取消 (Esc)"
	cancel_button.pressed.connect(_cancel)
	footer.add_child(cancel_button)


func _make_new_weapon_card() -> Control:
	var info := _get_weapon_scene_info(new_weapon_scene, new_weapon_affixes)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(322, 276)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_weapon_style(info.get("color", Color(0.28, 0.72, 0.8, 1.0)) as Color, true))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var eyebrow := Label.new()
	eyebrow.text = "新武器 / %s / %s" % [info.get("rarity", "制式"), info.get("role", "通用")]
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", Color(0.72, 0.92, 0.92, 1.0))
	layout.add_child(eyebrow)

	var name_label := Label.new()
	name_label.text = str(info.get("name", "未知武器"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.96, 1.0, 0.94, 1.0))
	layout.add_child(name_label)

	var description := Label.new()
	description.text = str(info.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 13)
	description.add_theme_color_override("font_color", Color(0.8, 0.88, 0.88, 1.0))
	layout.add_child(description)

	layout.add_child(_make_stat_grid(info))

	var special := Label.new()
	special.text = "特性：%s" % str(info.get("special", "无特殊词条"))
	special.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	special.add_theme_font_size_override("font_size", 13)
	special.add_theme_color_override("font_color", Color(0.9, 0.86, 0.64, 1.0))
	layout.add_child(special)

	if cost_text != "":
		var cost := Label.new()
		cost.text = cost_text
		cost.add_theme_font_size_override("font_size", 13)
		cost.add_theme_color_override("font_color", Color(0.68, 1.0, 0.64, 1.0))
		layout.add_child(cost)

	return panel


func _make_slot_list() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(324, 276)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_dark_card_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "当前武器栏"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.84, 0.98, 1.0, 1.0))
	layout.add_child(title)

	var help := Label.new()
	help.text = "武器栏已满，按 1-4 选择替换。" if _requires_replacement else "还有空位，按 F 加入；当前列表用于对比。"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.66, 0.78, 0.8, 1.0))
	layout.add_child(help)

	for slot_info in _get_slot_infos():
		var button := _make_slot_button(slot_info)
		_slot_buttons.append(button)
		layout.add_child(button)

	return panel


func _make_slot_button(slot_info: Dictionary) -> Button:
	var slot_index := int(slot_info.get("index", 0))
	var button := Button.new()
	button.custom_minimum_size = Vector2(296, 42)
	button.disabled = not _requires_replacement
	button.text = _get_slot_button_text(slot_info)
	button.pressed.connect(func() -> void: _confirm(slot_index))
	return button


func _make_stat_grid(info: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	_add_stat_pair(grid, "伤害", str(info.get("damage", "特殊")))
	_add_stat_pair(grid, "频率", str(info.get("rate", "中")))
	_add_stat_pair(grid, "射程", str(info.get("range", "中程")))
	_add_stat_pair(grid, "能量", str(info.get("energy", "无消耗")))
	return grid


func _add_stat_pair(grid: GridContainer, label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.56, 0.72, 0.74, 1.0))
	grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.clip_text = true
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", Color(0.92, 0.96, 0.9, 1.0))
	grid.add_child(value)


func _get_slot_infos() -> Array:
	var result := []
	var slots := []
	if weapon_holder != null and weapon_holder.has_method("get_quick_weapon_slots"):
		slots = weapon_holder.call("get_quick_weapon_slots", MAX_QUICK_SLOTS) as Array

	for slot_index in range(MAX_QUICK_SLOTS):
		var slot_info := {
			"index": slot_index,
			"slot": slot_index + 1,
			"scene": null,
			"equipped": false,
			"name": "空武器位",
			"damage": "-",
			"rate": "-",
			"special": "可放入新武器",
		}
		if slot_index < slots.size():
			var raw_info := slots[slot_index] as Dictionary
			var weapon_scene := raw_info.get("scene") as PackedScene
			slot_info["scene"] = weapon_scene
			slot_info["equipped"] = bool(raw_info.get("equipped", false))
			if weapon_scene != null:
				var raw_affixes = raw_info.get("affixes", [])
				var compare_info := _get_weapon_scene_info(weapon_scene, raw_affixes if raw_affixes is Array else [])
				if raw_info.has("damage"):
					compare_info.merge(raw_info, true)
				slot_info["name"] = compare_info.get("name", raw_info.get("name", "武器"))
				slot_info["damage"] = compare_info.get("damage", "-")
				slot_info["rate"] = compare_info.get("rate", "-")
				slot_info["special"] = compare_info.get("special", "")
		result.append(slot_info)
	return result


func _get_slot_button_text(slot_info: Dictionary) -> String:
	var prefix := "%d：" % int(slot_info.get("slot", 0))
	var active := " / 已装备" if bool(slot_info.get("equipped", false)) else ""
	var name_text := str(slot_info.get("name", "空武器位"))
	var stat_text := "伤害 %s｜频率 %s" % [slot_info.get("damage", "-"), slot_info.get("rate", "-")]
	if slot_info.get("scene") == null:
		return "%s空武器位\n%s" % [prefix, slot_info.get("special", "可放入新武器")]
	return "%s%s%s\n%s" % [prefix, name_text, active, stat_text]


func _get_subtitle_text() -> String:
	if _requires_replacement:
		return "确认前不会替换武器；选择 1-4 后，目标槽位会被新武器覆盖。"
	return "确认前不会改变当前构筑；可先查看新武器与现有武器栏。"


func _get_weapon_scene_info(weapon_scene: PackedScene, affixes := []) -> Dictionary:
	var info := {
		"name": "未知武器",
		"rarity": "制式",
		"role": "通用",
		"description": "该武器尚未录入完整说明。",
		"damage": "特殊",
		"rate": "中",
		"energy": "无消耗",
		"range": "中程",
		"special": "无特殊词条",
		"color": Color(0.26, 0.62, 0.9, 1.0),
	}
	if weapon_scene == null:
		return info

	var weapon := weapon_scene.instantiate()
	if weapon is LabWeapon:
		(weapon as LabWeapon).set_weapon_affixes(affixes if affixes is Array else [])
		info.merge((weapon as LabWeapon).get_weapon_compare_info(), true)
	elif weapon != null and weapon_scene.resource_path != "":
		info["name"] = weapon_scene.resource_path.get_file().get_basename().replace("_", " ")
	if weapon != null:
		weapon.free()
	return info


func _focus_default_button() -> void:
	if _primary_button != null and not _primary_button.disabled:
		_primary_button.grab_focus()
		return
	for button in _slot_buttons:
		if button != null and not button.disabled:
			button.grab_focus()
			return


func _event_pressed(event: InputEvent, action_name: String) -> bool:
	return InputMap.has_action(action_name) and event.is_action_pressed(action_name)


func _confirm(slot_index: int) -> void:
	if _closed:
		return
	_closed = true
	get_tree().paused = _previous_pause_state
	confirmed.emit(slot_index)
	queue_free()


func _cancel() -> void:
	if _closed:
		return
	_closed = true
	get_tree().paused = _previous_pause_state
	cancelled.emit()
	queue_free()


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.045, 0.98)
	style.border_color = Color(0.28, 0.76, 0.82, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func _make_dark_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.052, 0.058, 0.96)
	style.border_color = Color(0.16, 0.4, 0.46, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style


func _make_weapon_style(color: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.055, 0.06, 0.98)
	style.border_color = color.lightened(0.18) if highlighted else color.darkened(0.2)
	style.set_border_width_all(2 if highlighted else 1)
	style.set_corner_radius_all(6)
	return style
