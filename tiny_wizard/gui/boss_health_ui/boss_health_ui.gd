extends CanvasLayer


var _boss: Node
var _panel: PanelContainer
var _name_label: Label
var _health_bar: ProgressBar
var _value_label: Label


func _ready() -> void:
	layer = 45
	_build_ui()
	visible = false


func bind_boss(boss: Node) -> void:
	_boss = boss
	if _boss == null:
		return

	var display_name := str(_boss.get("boss_display_name"))
	if display_name.strip_edges().is_empty():
		display_name = "Fusion Node"
	_name_label.text = display_name

	if _boss.has_signal("boss_stats_changed"):
		var stats_callable := Callable(self, "_on_boss_stats_changed")
		if not _boss.is_connected("boss_stats_changed", stats_callable):
			_boss.connect("boss_stats_changed", stats_callable)

	var tree_exited_callable := Callable(self, "_on_boss_tree_exited")
	if not _boss.tree_exited.is_connected(tree_exited_callable):
		_boss.tree_exited.connect(tree_exited_callable)

	var stats := _boss.get("character_stats") as QuiverCharacterStats
	if stats != null:
		_on_boss_stats_changed(stats.current_life, stats.max_life)


func show_bar() -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	visible = true


func hide_bar() -> void:
	visible = false


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -240.0
	_panel.offset_right = 240.0
	_panel.offset_top = 24.0
	_panel.offset_bottom = 84.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.055, 0.06, 0.88)
	panel_style.border_color = Color(0.25, 0.95, 0.6, 0.72)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	_name_label = Label.new()
	_name_label.text = "Fusion Node"
	_name_label.add_theme_color_override("font_color", Color(0.76, 1.0, 0.86))
	_name_label.add_theme_font_size_override("font_size", 14)
	header.add_child(_name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_value_label = Label.new()
	_value_label.text = "0 / 0"
	_value_label.add_theme_color_override("font_color", Color(0.85, 0.98, 0.9))
	_value_label.add_theme_font_size_override("font_size", 12)
	header.add_child(_value_label)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(452, 16)
	_health_bar.show_percentage = false
	layout.add_child(_health_bar)

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.08, 0.12, 0.13, 0.95)
	background_style.corner_radius_top_left = 3
	background_style.corner_radius_top_right = 3
	background_style.corner_radius_bottom_left = 3
	background_style.corner_radius_bottom_right = 3
	_health_bar.add_theme_stylebox_override("background", background_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.25, 0.95, 0.34, 0.95)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	_health_bar.add_theme_stylebox_override("fill", fill_style)


func _on_boss_stats_changed(current_life: int, max_life: int) -> void:
	if _health_bar == null:
		return

	var safe_max_life := maxi(1, max_life)
	var shown_life := clampi(current_life, 0, safe_max_life)
	_health_bar.max_value = safe_max_life
	_health_bar.value = shown_life
	_value_label.text = "%d / %d" % [shown_life, safe_max_life]


func _on_boss_tree_exited() -> void:
	hide_bar()
