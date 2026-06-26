class_name LabMinimapUI
extends CanvasLayer


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

const TILE_SIZE := Vector2(22, 22)
const TILE_GAP := 6.0
const MAP_AREA_SIZE := Vector2(178, 136)

var _rooms := {}
var _explored := {}
var _current_coord := Vector2i.ZERO
var _floor_index := 1
var _chapter_label := ""

var _root: Control
var _title_label: Label
var _map_area: Control


func _ready() -> void:
	layer = 23
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	hide_map()


func set_rooms(room_map: Dictionary, floor_index: int, chapter_label := "") -> void:
	_rooms = room_map.duplicate()
	_floor_index = floor_index
	_chapter_label = chapter_label
	_explored.clear()
	_refresh()


func update_current_room(room_coord: Vector2i) -> void:
	if _rooms.is_empty():
		hide_map()
		return

	_current_coord = room_coord
	_explored[_current_coord] = true
	if _root != null:
		_root.visible = true
	_refresh()


func hide_map() -> void:
	if _root != null:
		_root.visible = false


func reset_map() -> void:
	_rooms.clear()
	_explored.clear()
	_refresh()
	hide_map()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "MinimapRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var holder := MarginContainer.new()
	holder.name = "Holder"
	holder.anchor_left = 1.0
	holder.anchor_top = 0.0
	holder.anchor_right = 1.0
	holder.anchor_bottom = 0.0
	holder.offset_left = -226.0
	holder.offset_top = 214.0
	holder.offset_right = -22.0
	holder.offset_bottom = 414.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(holder)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	holder.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 13)
	_title_label.add_theme_color_override("font_color", Color(0.74, 0.95, 1.0, 1.0))
	layout.add_child(_title_label)

	_map_area = Control.new()
	_map_area.name = "MapArea"
	_map_area.custom_minimum_size = MAP_AREA_SIZE
	_map_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(_map_area)

	var legend := Label.new()
	legend.text = "我：当前位置  始：起点  王：Boss  商：渡鸦  奖：奖励  武：武器"
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.add_theme_font_size_override("font_size", 10)
	legend.add_theme_color_override("font_color", Color(0.56, 0.75, 0.78, 0.92))
	layout.add_child(legend)


func _refresh() -> void:
	if _title_label != null:
		if _chapter_label != "":
			_title_label.text = "%s｜第 %d 层" % [_chapter_label, _floor_index]
		else:
			_title_label.text = "封存地图｜第 %d 层" % _floor_index
	if _map_area == null:
		return

	for child in _map_area.get_children():
		child.queue_free()

	if _rooms.is_empty():
		return

	var bounds := _get_bounds()
	var min_coord: Vector2i = bounds[0]
	var max_coord: Vector2i = bounds[1]
	var grid_size := Vector2(
		(max_coord.x - min_coord.x + 1) * TILE_SIZE.x + (max_coord.x - min_coord.x) * TILE_GAP,
		(max_coord.y - min_coord.y + 1) * TILE_SIZE.y + (max_coord.y - min_coord.y) * TILE_GAP
	)
	var origin := (MAP_AREA_SIZE - grid_size) * 0.5

	for room_coord in _rooms.keys():
		var room := _rooms[room_coord] as Room
		if room == null:
			continue

		var tile := _make_room_tile(room_coord, room)
		tile.position = origin + Vector2(
			(room_coord.x - min_coord.x) * (TILE_SIZE.x + TILE_GAP),
			(room_coord.y - min_coord.y) * (TILE_SIZE.y + TILE_GAP)
		)
		_map_area.add_child(tile)
		CHINESE_FONT_BOOTSTRAP.apply_to_tree(tile)


func _get_bounds() -> Array:
	var min_coord := Vector2i(99999, 99999)
	var max_coord := Vector2i(-99999, -99999)
	for room_coord in _rooms.keys():
		min_coord.x = mini(min_coord.x, room_coord.x)
		min_coord.y = mini(min_coord.y, room_coord.y)
		max_coord.x = maxi(max_coord.x, room_coord.x)
		max_coord.y = maxi(max_coord.y, room_coord.y)
	return [min_coord, max_coord]


func _make_room_tile(room_coord: Vector2i, room: Room) -> PanelContainer:
	var is_current := room_coord == _current_coord
	var is_explored := bool(_explored.get(room_coord, false))

	var tile := PanelContainer.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.size = TILE_SIZE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_theme_stylebox_override("panel", _make_tile_style(room.lab_room_type, is_current, is_explored))

	var label := Label.new()
	label.text = _get_room_symbol(room.lab_room_type, is_current)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _get_symbol_font_size(label.text))
	label.add_theme_color_override("font_color", _get_symbol_color(room.lab_room_type, is_current, is_explored))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)

	return tile


func _get_room_symbol(room_type: String, is_current: bool) -> String:
	if is_current:
		return "我"
	match room_type:
		"start":
			return "始"
		"boss":
			return "王"
		"merchant":
			return "商"
		"reward":
			return "奖"
		"weapon":
			return "武"
		"pollution":
			return "污"
	return ""


func _get_symbol_font_size(symbol: String) -> int:
	return 12 if symbol.length() > 0 and symbol != "●" else 15


func _get_symbol_color(room_type: String, is_current: bool, is_explored: bool) -> Color:
	if is_current:
		return Color(0.02, 0.08, 0.09, 1.0)
	if not is_explored and room_type == "combat":
		return Color(0.3, 0.42, 0.44, 0.45)
	match room_type:
		"boss":
			return Color(1.0, 0.36, 0.26, 1.0)
		"merchant":
			return Color(0.38, 0.92, 1.0, 1.0)
		"reward":
			return Color(1.0, 0.78, 0.24, 1.0)
		"weapon":
			return Color(0.78, 0.7, 1.0, 1.0)
		"pollution":
			return Color(0.5, 1.0, 0.42, 1.0)
		"start":
			return Color(0.66, 0.95, 0.78, 1.0)
	return Color(0.74, 0.9, 0.92, 0.95)


func _make_tile_style(room_type: String, is_current: bool, is_explored: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(0.16, 0.36, 0.4, 0.76)

	if is_current:
		style.bg_color = Color(0.36, 0.92, 1.0, 0.95)
		style.border_color = Color(0.86, 1.0, 1.0, 1.0)
		style.set_border_width_all(2)
		return style

	var base := _get_type_color(room_type)
	if is_explored:
		style.bg_color = base.lerp(Color(0.82, 0.95, 1.0, 1.0), 0.16)
		style.border_color = base.lerp(Color(0.92, 1.0, 1.0, 1.0), 0.28)
	else:
		style.bg_color = base.darkened(0.52)
		style.bg_color.a = 0.55 if _is_special_room(room_type) else 0.22
		style.border_color = base.darkened(0.18)
		style.border_color.a = 0.5 if _is_special_room(room_type) else 0.25
	return style


func _get_type_color(room_type: String) -> Color:
	match room_type:
		"start":
			return Color(0.14, 0.46, 0.28, 0.92)
		"boss":
			return Color(0.55, 0.11, 0.09, 0.92)
		"merchant":
			return Color(0.05, 0.36, 0.42, 0.92)
		"reward":
			return Color(0.5, 0.34, 0.07, 0.92)
		"weapon":
			return Color(0.25, 0.18, 0.48, 0.92)
		"pollution":
			return Color(0.12, 0.42, 0.18, 0.92)
	return Color(0.12, 0.22, 0.25, 0.85)


func _is_special_room(room_type: String) -> bool:
	return room_type in ["start", "boss", "merchant", "reward", "weapon", "pollution"]


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.042, 0.05, 0.82)
	style.border_color = Color(0.18, 0.6, 0.68, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style
