class_name LabCryoPod
extends StaticBody2D


signal cryo_pod_checked(pod: LabCryoPod)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const PROTOMATTER_FRAGMENT_ITEM := preload("res://tiny_wizard/items/protomatter_fragment/protomatter_fragment.tres")

@export var max_health := 3
@export var display_name := "冷冻舱"
@export var checked_display_name := "冷冻舱已检查"
@export var releases_enemy := false
@export var enemy_scene: PackedScene
@export_range(0, 5, 1) var protomatter_reward := 1

var _health := 0
var _checked := false
var _nearby_character: Node

@onready var label: Label = get_node_or_null("Label") as Label
@onready var interaction_area: Area2D = get_node_or_null("InteractionArea") as Area2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var intact_visual: Polygon2D = get_node_or_null("IntactVisual") as Polygon2D
@onready var cracked_visual: Line2D = get_node_or_null("CrackedGlass") as Line2D


func _ready() -> void:
	add_to_group("cryo_pods")
	add_to_group("room_event_targets")
	collision_layer = 9
	collision_mask = 15
	_health = max_health
	if label != null:
		label.text = display_name
	if interaction_area != null:
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	_update_visual()


func _process(_delta: float) -> void:
	if _checked or _nearby_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		check_pod(_nearby_character)


func hit(damage := 1, _from := Vector2.ZERO) -> void:
	if _checked:
		return
	_health = maxi(0, _health - maxi(1, int(damage)))
	_update_visual()
	if _health <= 0:
		check_pod(null)


func check_pod(character: Node) -> void:
	if _checked:
		return
	_checked = true
	if label != null:
		label.text = checked_display_name
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	_spawn_result(character)
	_update_visual()
	cryo_pod_checked.emit(self)


func get_interaction_prompt(_character: Node) -> String:
	if _checked:
		return ""
	return "按 F 检查冷冻舱"


func _spawn_result(_character: Node) -> void:
	if releases_enemy:
		_spawn_enemy()
	else:
		_drop_protomatter()


func _spawn_enemy() -> void:
	var room := _find_parent_room()
	if room == null or enemy_scene == null:
		return
	var enemies := room.get_node_or_null("Enemies")
	if enemies == null:
		return
	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.position = room.to_local(global_position + Vector2(randf_range(-22.0, 22.0), 36.0))
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	enemies.call_deferred("add_child", enemy)


func _drop_protomatter() -> void:
	if PROTOMATTER_FRAGMENT_ITEM == null or protomatter_reward <= 0:
		return
	var room := _find_parent_room()
	if room == null:
		return
	for index in range(protomatter_reward):
		var item_node := PROTOMATTER_FRAGMENT_ITEM.create_pickable_item() as Node2D
		if item_node == null:
			continue
		var offset := Vector2(randf_range(-22.0, 22.0), randf_range(20.0, 42.0))
		item_node.position = room.to_local(global_position + offset)
		room.call_deferred("add_child", item_node)


func _find_parent_room() -> Room:
	var current := get_parent()
	while current != null:
		if current is Room:
			return current as Room
		current = current.get_parent()
	return null


func _on_interaction_body_entered(body: Node) -> void:
	if body != null and body.has_node("Visual/WeaponHolder"):
		_nearby_character = body


func _on_interaction_body_exited(body: Node) -> void:
	if body == _nearby_character:
		_nearby_character = null


func _update_visual() -> void:
	var health_ratio := 1.0 if max_health <= 0 else clampf(float(_health) / float(max_health), 0.0, 1.0)
	if intact_visual != null:
		intact_visual.color = Color(0.35, 0.78, 1.0, 0.28 + health_ratio * 0.24) if not _checked else Color(0.18, 0.42, 0.52, 0.18)
	if cracked_visual != null:
		cracked_visual.visible = _checked or health_ratio < 0.7
		cracked_visual.default_color = Color(0.8, 0.96, 1.0, 0.78)
