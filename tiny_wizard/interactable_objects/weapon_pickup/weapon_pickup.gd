class_name LabWeaponPickup
extends Node2D


signal weapon_picked_up(slot_index: int)

@export var weapon_scene: PackedScene
@export var weapon_label := "Weapon"
@export var equip_on_pickup := false
@export_range(0, 8) var target_slot_number := 0
@export var preview_rotation := -0.28
@export var preview_scale := Vector2(1.28, 1.28)

var _candidate_character: Node2D
var _picked_up := false
var _drop_tween: Tween
var _preview_instance: Node2D

@onready var pickup_area: Area2D = $PickupArea
@onready var prompt: CanvasItem = $Prompt
@onready var weapon_preview: Node2D = $WeaponPreview
@onready var glow: CanvasItem = $Glow


func _ready() -> void:
	prompt.visible = false
	_build_weapon_preview()
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


func _process(_delta: float) -> void:
	if _picked_up or _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		_pick_up(_candidate_character)


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


func _pick_up(character: Node2D) -> void:
	if weapon_scene == null:
		return

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		return

	var slot_index := -1
	if target_slot_number > 0 and weapon_holder.has_method("add_weapon_scene_to_slot"):
		slot_index = int(weapon_holder.add_weapon_scene_to_slot(weapon_scene, target_slot_number - 1, equip_on_pickup))
	else:
		slot_index = int(weapon_holder.add_weapon_scene(weapon_scene, equip_on_pickup))
	if slot_index < 0:
		return

	_picked_up = true
	prompt.visible = false
	visible = false
	pickup_area.monitoring = false
	weapon_picked_up.emit(slot_index)
	print("%s added to weapon slot %d." % [weapon_label, slot_index + 1])


func play_drop_animation(start_global_position: Vector2, end_global_position: Vector2) -> void:
	if _drop_tween != null:
		_drop_tween.kill()

	global_position = start_global_position
	scale = Vector2(0.42, 0.42)
	modulate = Color(1, 1, 1, 0.0)
	pickup_area.monitoring = false
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
	pickup_area.monitoring = true


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _picked_up or not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	prompt.visible = true


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
