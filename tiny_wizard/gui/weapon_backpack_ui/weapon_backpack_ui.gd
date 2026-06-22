class_name WeaponBackpackUI
extends Control


const GRID_COLUMNS := 6
const GRID_ROWS := 4
const CELL_SIZE := Vector2(54, 54)
const CELL_GAP := 4.0
const MAX_QUICK_SLOTS := 4
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

var weapon_holder: Node
var _item_layer: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if get_tree().paused:
			return
		visible = not visible
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return visible


func close_inventory() -> void:
	visible = false


func bind_weapon_holder(new_weapon_holder: Node) -> void:
	_disconnect_weapon_holder()
	weapon_holder = new_weapon_holder
	_connect_weapon_holder()
	refresh()


func refresh() -> void:
	if _item_layer == null:
		return

	_clear_item_layer()
	if weapon_holder == null or not is_instance_valid(weapon_holder):
		return
	if not weapon_holder.has_method("get_quick_weapon_slots"):
		return

	var slots := weapon_holder.call("get_quick_weapon_slots", MAX_QUICK_SLOTS) as Array
	var occupied := {}
	for slot_info in slots:
		var weapon_scene := slot_info.get("scene") as PackedScene
		if weapon_scene == null:
			continue

		var weapon_size := slot_info.get("size", Vector2i(2, 1)) as Vector2i
		weapon_size = Vector2i(
			clampi(weapon_size.x, 1, GRID_COLUMNS),
			clampi(weapon_size.y, 1, GRID_ROWS)
		)

		var cell := _find_open_cell(weapon_size, occupied)
		_mark_occupied(cell, weapon_size, occupied)
		_add_weapon_block(slot_info, cell, weapon_size)


func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.42)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(424, 322)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.name = "Title"
	title.text = "背包"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	layout.add_child(title)

	var grid_area := Control.new()
	grid_area.name = "GridArea"
	grid_area.custom_minimum_size = _grid_pixel_size()
	grid_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(grid_area)

	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			var cell := PanelContainer.new()
			cell.name = "Cell_%d_%d" % [x, y]
			cell.position = _cell_position(Vector2i(x, y))
			cell.size = CELL_SIZE
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_theme_stylebox_override("panel", _make_cell_style())
			grid_area.add_child(cell)

	_item_layer = Control.new()
	_item_layer.name = "ItemLayer"
	_item_layer.position = Vector2.ZERO
	_item_layer.size = _grid_pixel_size()
	_item_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_area.add_child(_item_layer)


func _connect_weapon_holder() -> void:
	if weapon_holder == null or not is_instance_valid(weapon_holder):
		return

	var loadout_callable := Callable(self, "refresh")
	if weapon_holder.has_signal("weapon_loadout_changed") and not weapon_holder.is_connected("weapon_loadout_changed", loadout_callable):
		weapon_holder.connect("weapon_loadout_changed", loadout_callable)

	var equipped_callable := Callable(self, "_on_weapon_equipped")
	if weapon_holder.has_signal("weapon_equipped") and not weapon_holder.is_connected("weapon_equipped", equipped_callable):
		weapon_holder.connect("weapon_equipped", equipped_callable)


func _disconnect_weapon_holder() -> void:
	if weapon_holder == null or not is_instance_valid(weapon_holder):
		return

	var loadout_callable := Callable(self, "refresh")
	if weapon_holder.has_signal("weapon_loadout_changed") and weapon_holder.is_connected("weapon_loadout_changed", loadout_callable):
		weapon_holder.disconnect("weapon_loadout_changed", loadout_callable)

	var equipped_callable := Callable(self, "_on_weapon_equipped")
	if weapon_holder.has_signal("weapon_equipped") and weapon_holder.is_connected("weapon_equipped", equipped_callable):
		weapon_holder.disconnect("weapon_equipped", equipped_callable)


func _on_weapon_equipped(_slot_index: int) -> void:
	refresh()


func _clear_item_layer() -> void:
	for child in _item_layer.get_children():
		_item_layer.remove_child(child)
		child.free()


func _add_weapon_block(slot_info: Dictionary, cell: Vector2i, weapon_size: Vector2i) -> void:
	var block := PanelContainer.new()
	block.name = "WeaponSlot%d" % int(slot_info.get("slot", 0))
	block.position = _cell_position(cell)
	block.size = _block_pixel_size(weapon_size)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_theme_stylebox_override("panel", _make_weapon_style(
		slot_info.get("color", Color(0.26, 0.62, 0.9, 1.0)) as Color,
		bool(slot_info.get("equipped", false))
	))
	_item_layer.add_child(block)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	block.add_child(margin)

	var labels := VBoxContainer.new()
	labels.add_theme_constant_override("separation", 2)
	margin.add_child(labels)

	var slot_label := Label.new()
	slot_label.text = "%d 号位" % int(slot_info.get("slot", 0))
	slot_label.add_theme_font_size_override("font_size", 11)
	slot_label.add_theme_color_override("font_color", Color(0.06, 0.07, 0.08, 0.9))
	labels.add_child(slot_label)

	var name_label := Label.new()
	name_label.text = str(slot_info.get("name", "武器"))
	name_label.clip_text = true
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.02, 0.03, 0.04, 1.0))
	labels.add_child(name_label)

	if bool(slot_info.get("equipped", false)):
		var active_label := Label.new()
		active_label.text = "已装备"
		active_label.add_theme_font_size_override("font_size", 10)
		active_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
		labels.add_child(active_label)

	CHINESE_FONT_BOOTSTRAP.apply_to_tree(block)


func _find_open_cell(weapon_size: Vector2i, occupied: Dictionary) -> Vector2i:
	for y in range(GRID_ROWS - weapon_size.y + 1):
		for x in range(GRID_COLUMNS - weapon_size.x + 1):
			var cell := Vector2i(x, y)
			if _can_place(cell, weapon_size, occupied):
				return cell
	return Vector2i(0, 0)


func _can_place(cell: Vector2i, weapon_size: Vector2i, occupied: Dictionary) -> bool:
	for y in range(weapon_size.y):
		for x in range(weapon_size.x):
			if occupied.has(cell + Vector2i(x, y)):
				return false
	return true


func _mark_occupied(cell: Vector2i, weapon_size: Vector2i, occupied: Dictionary) -> void:
	for y in range(weapon_size.y):
		for x in range(weapon_size.x):
			occupied[cell + Vector2i(x, y)] = true


func _cell_position(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * (CELL_SIZE.x + CELL_GAP),
		cell.y * (CELL_SIZE.y + CELL_GAP)
	)


func _block_pixel_size(weapon_size: Vector2i) -> Vector2:
	return Vector2(
		weapon_size.x * CELL_SIZE.x + max(0, weapon_size.x - 1) * CELL_GAP,
		weapon_size.y * CELL_SIZE.y + max(0, weapon_size.y - 1) * CELL_GAP
	)


func _grid_pixel_size() -> Vector2:
	return Vector2(
		GRID_COLUMNS * CELL_SIZE.x + (GRID_COLUMNS - 1) * CELL_GAP,
		GRID_ROWS * CELL_SIZE.y + (GRID_ROWS - 1) * CELL_GAP
	)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.052, 0.94)
	style.border_color = Color(0.28, 0.54, 0.62, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _make_cell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.095, 0.105, 0.95)
	style.border_color = Color(0.21, 0.25, 0.28, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style


func _make_weapon_style(color: Color, equipped: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.95, 0.98, 1.0, 1.0) if equipped else color.darkened(0.42)
	style.border_width_left = 3 if equipped else 2
	style.border_width_top = 3 if equipped else 2
	style.border_width_right = 3 if equipped else 2
	style.border_width_bottom = 3 if equipped else 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
