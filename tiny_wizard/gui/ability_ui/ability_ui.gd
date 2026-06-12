class_name LabAbilityUI
extends Control


var ability_controller: Node
var _title_label: Label
var _energy_label: Label
var _status_label: Label
var _energy_bar: ProgressBar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -142.0
	offset_top = 126.0
	offset_right = 142.0
	offset_bottom = 190.0
	visible = false
	_build_ui()


func _process(_delta: float) -> void:
	_refresh()


func bind_ability_controller(new_ability_controller: Node) -> void:
	ability_controller = new_ability_controller
	_refresh()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 3)
	margin.add_child(layout)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "Q  SKILL"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.add_theme_color_override("font_color", Color(0.74, 0.94, 1.0, 1.0))
	layout.add_child(_title_label)

	_energy_bar = ProgressBar.new()
	_energy_bar.name = "EnergyBar"
	_energy_bar.min_value = 0.0
	_energy_bar.max_value = 100.0
	_energy_bar.value = 100.0
	_energy_bar.show_percentage = false
	_energy_bar.custom_minimum_size = Vector2(220, 10)
	_energy_bar.add_theme_stylebox_override("background", _make_bar_background_style())
	_energy_bar.add_theme_stylebox_override("fill", _make_bar_fill_style())
	layout.add_child(_energy_bar)

	var line := HBoxContainer.new()
	line.name = "InfoLine"
	line.add_theme_constant_override("separation", 8)
	layout.add_child(line)

	_energy_label = Label.new()
	_energy_label.name = "Energy"
	_energy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_energy_label.add_theme_font_size_override("font_size", 11)
	_energy_label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.94, 1.0))
	line.add_child(_energy_label)

	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42, 1.0))
	line.add_child(_status_label)


func _refresh() -> void:
	if ability_controller == null or not is_instance_valid(ability_controller):
		visible = false
		return

	visible = true
	_title_label.text = "Q  %s" % ability_controller.get_ability_display_name().to_upper()
	_energy_label.text = "%.0f / %.0f EN" % [
		ability_controller.get_energy_current(),
		ability_controller.get_energy_max()
	]
	_status_label.text = ability_controller.get_ability_status_text().to_upper()
	_energy_bar.value = ability_controller.get_energy_ratio() * 100.0


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.065, 0.82)
	style.border_color = Color(0.22, 0.76, 0.86, 0.82)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _make_bar_background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.09, 1.0)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style


func _make_bar_fill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.36, 0.84, 1.0, 1.0)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style
