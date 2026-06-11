class_name ProtomatterDropEnemy
extends QuiverCharacter


const PROTOMATTER_FRAGMENT_ITEM := preload("res://tiny_wizard/items/protomatter_fragment/protomatter_fragment.tres")

@export_range(0.0, 1.0, 0.01) var protomatter_drop_chance := 0.45
@export_range(0, 8, 1) var protomatter_min_drop := 1
@export_range(0, 8, 1) var protomatter_max_drop := 1
@export var protomatter_drop_spread := 22.0

var _protomatter_dropped := false


func die() -> void:
	_drop_protomatter_fragments()
	super.die()


func _drop_protomatter_fragments() -> void:
	if _protomatter_dropped:
		return
	_protomatter_dropped = true

	if PROTOMATTER_FRAGMENT_ITEM == null:
		return
	if randf() > protomatter_drop_chance:
		return

	var drop_parent := _get_drop_parent()
	if drop_parent == null:
		return

	var min_drop := mini(protomatter_min_drop, protomatter_max_drop)
	var max_drop := maxi(protomatter_min_drop, protomatter_max_drop)
	var drop_count := randi_range(min_drop, max_drop)
	for index in range(drop_count):
		var item_node := PROTOMATTER_FRAGMENT_ITEM.create_pickable_item() as Node2D
		if item_node == null:
			continue

		var angle := randf() * TAU
		var distance := randf_range(0.0, protomatter_drop_spread)
		var drop_position := global_position + Vector2.from_angle(angle) * distance
		if drop_parent is Node2D:
			item_node.position = (drop_parent as Node2D).to_local(drop_position)
		else:
			item_node.global_position = drop_position
		drop_parent.call_deferred("add_child", item_node)


func _get_drop_parent() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	if parent.name == "Enemies" and parent.get_parent() != null:
		return parent.get_parent()
	return parent
