class_name LabRoomObjectiveUI
extends CanvasLayer


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

var _current_room: Room
var _floor_index := 1
var _chapter_label := ""
var _room_type_label := ""
var _objective_text := ""

var _root: Control
var _floor_label: Label
var _room_label: Label
var _objective_label: Label
var _progress_label: Label


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	hide_objective()


func show_room(room: Room, floor_index: int, room_type_label: String, objective_text: String, chapter_label := "") -> void:
	_disconnect_room()
	_current_room = room
	_floor_index = floor_index
	_chapter_label = chapter_label
	_room_type_label = room_type_label
	_objective_text = objective_text
	_connect_room()
	_refresh()
	if _root != null:
		_root.visible = true


func hide_objective() -> void:
	_disconnect_room()
	_current_room = null
	if _root != null:
		_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "RoomObjectiveRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var top_margin := MarginContainer.new()
	top_margin.name = "TopMargin"
	top_margin.anchor_left = 0.25
	top_margin.anchor_top = 0.0
	top_margin.anchor_right = 0.75
	top_margin.anchor_bottom = 0.0
	top_margin.offset_top = 94.0
	top_margin.offset_bottom = 178.0
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top_margin)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	top_margin.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	_floor_label = Label.new()
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_floor_label.add_theme_font_size_override("font_size", 11)
	_floor_label.add_theme_color_override("font_color", Color(0.4, 0.92, 0.98, 1.0))
	layout.add_child(_floor_label)

	_room_label = Label.new()
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_label.add_theme_font_size_override("font_size", 17)
	_room_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 1.0))
	layout.add_child(_room_label)

	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.add_theme_font_size_override("font_size", 13)
	_objective_label.add_theme_color_override("font_color", Color(0.78, 0.9, 0.92, 1.0))
	layout.add_child(_objective_label)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 13)
	_progress_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.58, 1.0))
	layout.add_child(_progress_label)


func _connect_room() -> void:
	if _current_room == null or not is_instance_valid(_current_room):
		return

	var progress_callable := Callable(self, "_on_room_progress_changed")
	if _current_room.has_signal("objective_progress_changed") and not _current_room.is_connected("objective_progress_changed", progress_callable):
		_current_room.connect("objective_progress_changed", progress_callable)

	var cleared_callable := Callable(self, "_on_room_cleared")
	if _current_room.has_signal("room_cleared") and not _current_room.is_connected("room_cleared", cleared_callable):
		_current_room.connect("room_cleared", cleared_callable)


func _disconnect_room() -> void:
	if _current_room == null or not is_instance_valid(_current_room):
		return

	var progress_callable := Callable(self, "_on_room_progress_changed")
	if _current_room.has_signal("objective_progress_changed") and _current_room.is_connected("objective_progress_changed", progress_callable):
		_current_room.disconnect("objective_progress_changed", progress_callable)

	var cleared_callable := Callable(self, "_on_room_cleared")
	if _current_room.has_signal("room_cleared") and _current_room.is_connected("room_cleared", cleared_callable):
		_current_room.disconnect("room_cleared", cleared_callable)


func _on_room_progress_changed(_room: Room) -> void:
	_refresh()


func _on_room_cleared(_room: Room) -> void:
	_refresh()


func _refresh() -> void:
	if _current_room == null or not is_instance_valid(_current_room):
		return

	if _chapter_label != "":
		_floor_label.text = "%s｜第 %d 层 / %s" % [_chapter_label, _floor_index, _room_type_label]
	else:
		_floor_label.text = "第 %d 层 / %s" % [_floor_index, _room_type_label]
	_room_label.text = _current_room.lab_room_label

	var completion_text := _get_completion_text()
	if _current_room.is_cleared and completion_text != "":
		_objective_label.text = completion_text
	else:
		_objective_label.text = "当前目标：%s" % _get_objective_text()

	_progress_label.text = _get_progress_text()


func _get_objective_text() -> String:
	if _current_room == null or not is_instance_valid(_current_room):
		return _objective_text
	var objective := _get_room_objective()
	var configured_text := str(objective.get("objective_text", ""))
	if _has_event_target_objective():
		if configured_text == "" and _current_room.has_meta("event_objective_text"):
			configured_text = str(_current_room.get_meta("event_objective_text"))
		return _replace_target_counter(configured_text)
	if configured_text != "":
		return configured_text
	if _has_pollution_objective():
		if _current_room.has_meta("event_objective_text"):
			return str(_current_room.get_meta("event_objective_text"))
		return "清除原质污染源，并肃清房内样本。"
	if _has_cryo_pod_objective():
		return "检查冷冻舱，并清除释放的封存样本。"
	return _objective_text


func _get_progress_text() -> String:
	if _current_room == null or not is_instance_valid(_current_room):
		return ""

	var remaining := 0
	if _current_room.has_method("get_remaining_enemy_count"):
		remaining = int(_current_room.call("get_remaining_enemy_count"))

	if _current_room.is_cleared:
		return "封锁解除"
	if _has_event_target_objective():
		var target_total := _get_event_target_total()
		var target_remaining := _get_event_target_remaining()
		var target_cleared := maxi(0, target_total - target_remaining)
		return "%s：%d/%d    剩余样本：%d" % [_get_event_target_label(), target_cleared, target_total, remaining]
	if not _current_room.has_method("has_enemy_clear_objective") or not bool(_current_room.call("has_enemy_clear_objective")):
		return ""
	if _current_room.lab_room_type == "boss":
		return "目标生命信号：未稳定"
	return "剩余样本：%d" % remaining


func _get_completion_text() -> String:
	if _current_room == null or not is_instance_valid(_current_room):
		return ""
	var objective := _get_room_objective()
	var configured_text := str(objective.get("completion_text", ""))
	if configured_text != "":
		return configured_text

	match _current_room.lab_room_type:
		"combat":
			return "封锁解除：异常样本已清除。"
		"pollution":
			if _current_room.has_meta("event_completion_text"):
				return str(_current_room.get_meta("event_completion_text"))
			return "封锁解除：原质污染源已清除。"
		"data_comm":
			if _current_room.has_meta("event_completion_text"):
				return str(_current_room.get_meta("event_completion_text"))
			return "封锁解除：通讯终端已重启。"
		"data_satellite":
			if _current_room.has_meta("event_completion_text"):
				return str(_current_room.get_meta("event_completion_text"))
			return "封锁解除：伪装节点已关闭。"
		"archive":
			return "数据档案已同步：黑匣子记录可查看。"
		"cryo_pod":
			return "封锁解除：冷冻舱已检查。"
		"cryo_vent":
			return "封锁解除：低温喷口已稳定。"
		"elite":
			return "封锁解除：冰核守卫已清除。"
		"reward":
			return "奖励解锁：守卫样本已清除。"
		"boss":
			return "下行裂隙稳定：可进入裂隙。"
	return ""


func _has_pollution_objective() -> bool:
	if _current_room == null or not is_instance_valid(_current_room):
		return false
	if not _current_room.has_method("has_pollution_source_objective"):
		return false
	return bool(_current_room.call("has_pollution_source_objective"))


func _has_cryo_pod_objective() -> bool:
	if _current_room == null or not is_instance_valid(_current_room):
		return false
	if not _current_room.has_method("has_cryo_pod_objective"):
		return false
	return bool(_current_room.call("has_cryo_pod_objective"))


func _get_room_objective() -> Dictionary:
	if _current_room == null or not is_instance_valid(_current_room):
		return {}
	if _current_room.has_method("get_room_objective"):
		return _current_room.call("get_room_objective") as Dictionary
	return {}


func _has_event_target_objective() -> bool:
	if _current_room == null or not is_instance_valid(_current_room):
		return false
	var objective_type := str(_get_room_objective().get("type", ""))
	if objective_type in [Room.OBJECTIVE_DESTROY_TARGETS, Room.OBJECTIVE_INTERACT_TARGETS]:
		return _get_event_target_total() > 0
	return _has_pollution_objective() or _has_cryo_pod_objective()


func _get_event_target_total() -> int:
	if _current_room == null or not is_instance_valid(_current_room):
		return 0
	if _current_room.has_method("get_event_target_total"):
		return int(_current_room.call("get_event_target_total"))
	if _has_pollution_objective():
		return int(_current_room.call("get_pollution_source_total"))
	if _has_cryo_pod_objective():
		return int(_current_room.call("get_cryo_pod_total"))
	return int(_get_room_objective().get("target_total", 0))


func _get_event_target_remaining() -> int:
	if _current_room == null or not is_instance_valid(_current_room):
		return 0
	if _current_room.has_method("get_event_target_remaining"):
		return int(_current_room.call("get_event_target_remaining"))
	if _has_pollution_objective():
		return int(_current_room.call("get_pollution_source_remaining"))
	if _has_cryo_pod_objective():
		return int(_current_room.call("get_cryo_pod_remaining"))
	return 0


func _get_event_target_label() -> String:
	if _current_room == null or not is_instance_valid(_current_room):
		return "目标"
	if _current_room.has_method("get_event_target_label"):
		return str(_current_room.call("get_event_target_label"))
	if _current_room.has_meta("event_target_label"):
		return str(_current_room.get_meta("event_target_label"))
	return str(_get_room_objective().get("target_label", "目标"))


func _replace_target_counter(text: String) -> String:
	if text == "":
		text = "%s 0/%d。" % [_get_event_target_label(), _get_event_target_total()]
	var total := _get_event_target_total()
	var current := maxi(0, total - _get_event_target_remaining())
	var counter := "%d/%d" % [current, total]
	for possible in ["0/%d" % total, "0/3", "0/0"]:
		if text.find(possible) >= 0:
			return text.replace(possible, counter)
	return "%s（%s）" % [text, counter]


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.052, 0.06, 0.86)
	style.border_color = Color(0.22, 0.66, 0.76, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style
