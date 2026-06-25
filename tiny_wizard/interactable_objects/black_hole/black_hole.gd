class_name LabBlackHole
extends Area2D


signal entered(body: Node2D)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")

@export_range(0.0, 2.0, 0.05) var activation_grace_seconds := 0.35
@export var enter_prompt_text := "按 F 进入下行裂隙"
@export var stabilizing_text := "下行裂隙稳定中。"

var _active := true
var _activated_at_msec := -1000000.0
var _candidate_body: Node2D
var _prompt_label: Label


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	_create_prompt_label()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_active(monitoring)
	set_process(true)


func _process(_delta: float) -> void:
	if not _active or _candidate_body == null:
		return
	_refresh_prompt()
	if Input.is_action_just_pressed("interact"):
		_try_enter(_candidate_body)


func set_active(active: bool) -> void:
	_active = active
	if active:
		_activated_at_msec = Time.get_ticks_msec()
	visible = active
	_candidate_body = null
	_refresh_prompt()
	set_deferred("monitoring", active)
	set_deferred("monitorable", active)


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_body = body
	_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body != _candidate_body:
		return
	_candidate_body = null
	_refresh_prompt()


func _try_enter(body: Node2D) -> void:
	if _is_in_activation_grace():
		INTERACTION_FEEDBACK.show_from(self, stabilizing_text, 1.2)
		return
	if body == null or not body.has_node("Visual/WeaponHolder"):
		return
	entered.emit(body)


func _is_in_activation_grace() -> bool:
	if activation_grace_seconds <= 0.0:
		return false
	var elapsed_seconds := (Time.get_ticks_msec() - _activated_at_msec) / 1000.0
	return elapsed_seconds < activation_grace_seconds


func _refresh_prompt() -> void:
	if _prompt_label == null:
		return
	if not _active or _candidate_body == null:
		_prompt_label.visible = false
		return
	_prompt_label.text = stabilizing_text if _is_in_activation_grace() else enter_prompt_text
	_prompt_label.visible = true


func _create_prompt_label() -> void:
	_prompt_label = Label.new()
	_prompt_label.name = "Prompt"
	_prompt_label.visible = false
	_prompt_label.position = Vector2(-82, -82)
	_prompt_label.size = Vector2(164, 30)
	_prompt_label.z_index = 40
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_color_override("font_color", Color(0.72, 0.95, 1.0, 1))
	_prompt_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.86))
	_prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	_prompt_label.add_theme_font_size_override("font_size", 13)
	add_child(_prompt_label)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(_prompt_label)
