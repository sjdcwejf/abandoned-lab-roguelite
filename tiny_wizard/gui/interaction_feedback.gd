class_name LabInteractionFeedback
extends Control


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const GROUP_NAME := "lab_interaction_feedback"

var _panel: PanelContainer
var _label: Label
var _hide_tween: Tween


static func show_from(source: Node, message: String, seconds := 1.6) -> void:
	if source == null or message.strip_edges() == "":
		return
	var tree := source.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(GROUP_NAME):
		if node is LabInteractionFeedback:
			(node as LabInteractionFeedback).show_message(message, seconds)
			return


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP_NAME)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)


func show_message(message: String, seconds := 1.6) -> void:
	if _panel == null or _label == null:
		return
	_label.text = message
	_panel.modulate = Color.WHITE
	_panel.visible = true
	if _hide_tween != null:
		_hide_tween.kill()
	_hide_tween = create_tween()
	_hide_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_hide_tween.tween_interval(maxf(0.2, seconds))
	_hide_tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	_hide_tween.finished.connect(func() -> void:
		if _panel != null:
			_panel.visible = false
	)


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.name = "Center"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	center.offset_left = -260.0
	center.offset_top = -118.0
	center.offset_right = 260.0
	center.offset_bottom = -58.0
	add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size = Vector2(360, 38)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	_label = Label.new()
	_label.name = "Message"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", Color(0.78, 0.98, 1.0, 1))
	_label.add_theme_font_size_override("font_size", 14)
	margin.add_child(_label)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.04, 0.9)
	style.border_color = Color(0.22, 0.82, 0.9, 0.84)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style
