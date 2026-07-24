class_name LabWeaponPickup
extends Node2D


signal weapon_picked_up(slot_index: int)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")
const WEAPON_AFFIX_SERVICE := preload("res://tiny_wizard/player/weapons/weapon_affix_service.gd")

@export var weapon_scene: PackedScene
@export var weapon_label := "武器"
@export var weapon_affixes: Array = []
@export var equip_on_pickup := false
@export_range(0, 8) var target_slot_number := 0
@export var preview_rotation := -0.28
@export var preview_scale := Vector2(1.28, 1.28)

var _candidate_character: Node2D
var _picked_up := false
var _drop_tween: Tween
var _preview_instance: Node2D
var _awaiting_slot_selection := false

@onready var pickup_area: Area2D = $PickupArea
@onready var prompt: CanvasItem = $Prompt
@onready var weapon_preview: Node2D = $WeaponPreview
@onready var glow: CanvasItem = $Glow


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	prompt.visible = false
	_build_weapon_preview()
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


func _process(_delta: float) -> void:
	if _picked_up or _candidate_character == null:
		return
	if _awaiting_slot_selection:
		return
	if Input.is_action_just_pressed("interact"):
		_request_pickup(_candidate_character)


func _input(event: InputEvent) -> void:
	if _picked_up or _candidate_character == null or not _awaiting_slot_selection:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
		_cancel_slot_selection()
		get_viewport().set_input_as_handled()
		return

	var replacement_slot := _get_pressed_replacement_slot_from_event(event)
	if replacement_slot >= 0:
		_pick_up(_candidate_character, replacement_slot)
		get_viewport().set_input_as_handled()


func _request_pickup(character: Node2D) -> void:
	if weapon_scene == null:
		return

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		return
	if weapon_holder.has_method("has_weapon_scene") and bool(weapon_holder.call("has_weapon_scene", weapon_scene)):
		if prompt is Label:
			(prompt as Label).text = "已拥有"
		INTERACTION_FEEDBACK.show_from(self, "已经拥有 %s。" % weapon_label, 1.2)
		return

	if target_slot_number > 0:
		_pick_up(character)
		return

	var has_free_slot := true
	if weapon_holder.has_method("has_free_quick_slot"):
		has_free_slot = bool(weapon_holder.call("has_free_quick_slot"))
	if has_free_slot:
		_pick_up(character)
		return

	_begin_slot_selection()


func _build_weapon_preview() -> void:
	for child in weapon_preview.get_children():
		child.queue_free()

	if weapon_scene == null:
		return

	_preview_instance = weapon_scene.instantiate() as Node2D
	if _preview_instance == null:
		return

	weapon_preview.add_child(_preview_instance)
	_preview_instance.position = Vector2.ZERO
	_preview_instance.rotation = preview_rotation
	_preview_instance.scale = preview_scale
	_disable_preview_collision(_preview_instance)


func _disable_preview_collision(root: Node) -> void:
	if root is CollisionObject2D:
		var collision_object := root as CollisionObject2D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
		if collision_object is Area2D:
			(collision_object as Area2D).monitoring = false
			(collision_object as Area2D).monitorable = false

	if root is CollisionShape2D:
		(root as CollisionShape2D).disabled = true

	for child in root.get_children():
		_disable_preview_collision(child)


func _pick_up(character: Node2D, replacement_slot := -1) -> void:
	if weapon_scene == null:
		return

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		return
	if weapon_holder.has_method("has_weapon_scene") and bool(weapon_holder.call("has_weapon_scene", weapon_scene)):
		print("%s already owned; pickup ignored." % weapon_label)
		return

	var slot_index := -1
	if target_slot_number > 0 and weapon_holder.has_method("add_weapon_scene_to_slot"):
		if weapon_holder.has_method("add_weapon_scene_to_slot_with_affixes"):
			slot_index = int(weapon_holder.call("add_weapon_scene_to_slot_with_affixes", weapon_scene, target_slot_number - 1, weapon_affixes, equip_on_pickup))
		else:
			slot_index = int(weapon_holder.add_weapon_scene_to_slot(weapon_scene, target_slot_number - 1, equip_on_pickup))
	elif weapon_holder.has_method("has_free_quick_slot") and not bool(weapon_holder.call("has_free_quick_slot")):
		if replacement_slot < 0:
			_begin_slot_selection()
			return
		if not weapon_holder.has_method("replace_weapon_scene_in_slot"):
			return
		if weapon_holder.has_method("replace_weapon_scene_in_slot_with_affixes"):
			slot_index = int(weapon_holder.call("replace_weapon_scene_in_slot_with_affixes", weapon_scene, replacement_slot, weapon_affixes))
		else:
			slot_index = int(weapon_holder.call("replace_weapon_scene_in_slot", weapon_scene, replacement_slot))
	else:
		if weapon_holder.has_method("add_weapon_scene_with_affixes"):
			slot_index = int(weapon_holder.call("add_weapon_scene_with_affixes", weapon_scene, weapon_affixes, equip_on_pickup))
		else:
			slot_index = int(weapon_holder.add_weapon_scene(weapon_scene, equip_on_pickup))
	if slot_index < 0:
		INTERACTION_FEEDBACK.show_from(self, "武器拾取失败。", 1.2)
		return

	_picked_up = true
	_awaiting_slot_selection = false
	prompt.visible = false
	visible = false
	pickup_area.set_deferred("monitoring", false)
	weapon_picked_up.emit(slot_index)
	var display_label := _get_display_weapon_label()
	INTERACTION_FEEDBACK.show_from(self, "已获得 %s，装备到 %d 号位。" % [display_label, slot_index + 1], 1.4)
	print("%s added to weapon slot %d." % [display_label, slot_index + 1])


func _begin_slot_selection() -> void:
	_awaiting_slot_selection = true
	if prompt is Label:
		(prompt as Label).text = "武器栏已满：按 1 / 2 / 3 / 4 替换，Esc 取消"
	prompt.visible = true
	INTERACTION_FEEDBACK.show_from(self, "武器栏已满，按 1-4 选择替换槽位。", 1.4)


func _cancel_slot_selection() -> void:
	_awaiting_slot_selection = false
	if _candidate_character != null and not _picked_up:
		if prompt is Label:
			(prompt as Label).text = "按 F 拾取 %s" % _get_display_weapon_label()
		prompt.visible = true


func play_drop_animation(start_global_position: Vector2, end_global_position: Vector2) -> void:
	if _drop_tween != null:
		_drop_tween.kill()

	global_position = start_global_position
	scale = Vector2(0.42, 0.42)
	modulate = Color(1, 1, 1, 0.0)
	pickup_area.set_deferred("monitoring", false)
	prompt.visible = false

	_drop_tween = create_tween()
	_drop_tween.set_parallel(true)
	_drop_tween.tween_property(self, "global_position", end_global_position, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(self, "scale", Vector2.ONE, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(self, "modulate", Color.WHITE, 0.18).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(glow, "scale", Vector2(1.18, 1.18), 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_drop_tween.finished.connect(_on_drop_animation_finished)


func _on_drop_animation_finished() -> void:
	if _picked_up:
		return
	pickup_area.set_deferred("monitoring", true)


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _picked_up or not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	_awaiting_slot_selection = false
	if prompt is Label:
		(prompt as Label).text = "按 F 拾取 %s" % _get_display_weapon_label()
	prompt.visible = true


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	_awaiting_slot_selection = false
	prompt.visible = false


func _get_pressed_replacement_slot_from_event(event: InputEvent) -> int:
	for slot_index in range(4):
		var action_name := "weapon_slot_%d" % (slot_index + 1)
		if InputMap.has_action(action_name) and event.is_action_pressed(action_name):
			return slot_index
	return -1


func _get_display_weapon_label() -> String:
	return WEAPON_AFFIX_SERVICE.format_weapon_name(weapon_label, weapon_affixes)
