extends Node2D


signal weapon_picked_up(slot_index: int)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")

@export var weapon_scene: PackedScene
@export var weapon_label := "检疫刃"
@export var equip_on_pickup := false
@export_range(0, 8) var target_slot_number := 0

var _candidate_character: Node2D
var _picked_up := false
var _drop_tween: Tween
var _awaiting_slot_selection := false

@onready var pickup_area: Area2D = $PickupArea
@onready var prompt: CanvasItem = $Prompt
@onready var weapon_preview: CanvasItem = $WeaponPreview
@onready var stand_light: CanvasItem = $StandLight


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	prompt.visible = false
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


func _process(_delta: float) -> void:
	if _picked_up or _candidate_character == null:
		return
	if _awaiting_slot_selection:
		var replacement_slot := _get_pressed_replacement_slot()
		if replacement_slot >= 0:
			_pick_up(_candidate_character, replacement_slot)
		return
	if Input.is_action_just_pressed("interact"):
		_pick_up(_candidate_character)


func _pick_up(character: Node2D, replacement_slot := -1) -> void:
	if weapon_scene == null:
		return

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		return

	var slot_index := -1
	if target_slot_number > 0 and weapon_holder.has_method("add_weapon_scene_to_slot"):
		slot_index = int(weapon_holder.add_weapon_scene_to_slot(weapon_scene, target_slot_number - 1, equip_on_pickup))
	elif weapon_holder.has_method("has_free_quick_slot") and not bool(weapon_holder.call("has_free_quick_slot")):
		if replacement_slot < 0:
			_awaiting_slot_selection = true
			if prompt is Label:
				(prompt as Label).text = "按 1 / 2 / 3 / 4 选择替换"
			return
		if not weapon_holder.has_method("replace_weapon_scene_in_slot"):
			return
		slot_index = int(weapon_holder.call("replace_weapon_scene_in_slot", weapon_scene, replacement_slot))
	else:
		slot_index = int(weapon_holder.add_weapon_scene(weapon_scene, equip_on_pickup))
	if slot_index < 0:
		INTERACTION_FEEDBACK.show_from(self, "武器拾取失败。", 1.2)
		return

	_picked_up = true
	_awaiting_slot_selection = false
	prompt.visible = false
	weapon_preview.visible = false
	stand_light.visible = false
	pickup_area.set_deferred("monitoring", false)
	INTERACTION_FEEDBACK.show_from(self, "已获得 %s，装备到 %d 号位。" % [weapon_label, slot_index + 1], 1.4)
	print("%s added to weapon slot %d." % [weapon_label, slot_index + 1])
	weapon_picked_up.emit(slot_index)


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _picked_up or not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	_awaiting_slot_selection = false
	if prompt is Label:
		(prompt as Label).text = "按 F 拾取"
	prompt.visible = true


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	_awaiting_slot_selection = false
	prompt.visible = false


func _get_pressed_replacement_slot() -> int:
	for slot_index in range(4):
		var action_name := "weapon_slot_%d" % (slot_index + 1)
		if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
			return slot_index
	return -1


func play_drop_animation(start_global_position: Vector2, end_global_position: Vector2) -> void:
	if _drop_tween != null:
		_drop_tween.kill()

	global_position = start_global_position
	scale = Vector2(0.36, 0.36)
	modulate = Color(1, 1, 1, 0.0)
	pickup_area.set_deferred("monitoring", false)
	prompt.visible = false

	_drop_tween = create_tween()
	_drop_tween.set_parallel(true)
	_drop_tween.tween_property(self, "global_position", end_global_position, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(self, "scale", Vector2.ONE, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(self, "modulate", Color.WHITE, 0.18).set_ease(Tween.EASE_OUT)
	_drop_tween.finished.connect(_on_drop_animation_finished)


func _on_drop_animation_finished() -> void:
	if _picked_up:
		return
	pickup_area.set_deferred("monitoring", true)
