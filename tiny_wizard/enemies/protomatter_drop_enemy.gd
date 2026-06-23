class_name ProtomatterDropEnemy
extends QuiverCharacter


const PROTOMATTER_FRAGMENT_ITEM := preload("res://tiny_wizard/items/protomatter_fragment/protomatter_fragment.tres")
const GREEN_BLOOD_SPLATTER_SCRIPT := preload("res://tiny_wizard/effects/green_blood_splatter.gd")
const BUILD_ITEM_PICKUP_SCENE := preload("res://tiny_wizard/build/build_item_pickup.tscn")
const TEST_BUILD_CATALOG := preload("res://tiny_wizard/build/test_data/test_build_catalog.tres")

@export_range(0.0, 1.0, 0.01) var protomatter_drop_chance := 0.45
@export_range(0, 8, 1) var protomatter_min_drop := 1
@export_range(0, 8, 1) var protomatter_max_drop := 1
@export var protomatter_drop_spread := 22.0
@export var green_blood_splatter_enabled := true
@export var green_blood_spawn_offset := Vector2(0.0, -28.0)
@export_range(0.2, 4.0, 0.1) var green_blood_splatter_scale := 1.0
@export var build_item_drop_enabled := false
@export_range(0.0, 1.0, 0.01) var build_item_drop_chance := 0.08

var _protomatter_dropped := false


func hit(damage := 1, from := Vector2.ZERO) -> void:
	if green_blood_splatter_enabled and int(damage) > 0 and character_stats != null and character_stats.current_life > 0:
		_spawn_green_blood_splatter(from)
	super.hit(damage, from)


func die() -> void:
	_drop_protomatter_fragments()
	_try_drop_build_item()
	super.die()


func _try_drop_build_item() -> void:
	if not build_item_drop_enabled or randf() > build_item_drop_chance:
		return
	var scene_root := get_tree().current_scene
	var character := BuildPoolResolver.find_tiemu_character(scene_root)
	var definition := BuildPoolResolver.pick_candidate(character, TEST_BUILD_CATALOG, [&"enemy"])
	if definition == null:
		return
	var drop_parent := _get_drop_parent()
	if drop_parent == null:
		return
	var pickup := BUILD_ITEM_PICKUP_SCENE.instantiate() as BuildItemPickup
	pickup.setup(definition)
	if drop_parent is Node2D:
		pickup.position = (drop_parent as Node2D).to_local(global_position)
	else:
		pickup.global_position = global_position
	drop_parent.call_deferred("add_child", pickup)


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


func _spawn_green_blood_splatter(hit_from: Vector2) -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return

	var splatter: Node2D = GREEN_BLOOD_SPLATTER_SCRIPT.new() as Node2D
	if splatter == null:
		return

	splatter.name = "GreenBloodSplatter"
	splatter.call("setup", hit_from, green_blood_splatter_scale)
	var spawn_position := global_position + green_blood_spawn_offset
	if effect_parent is Node2D:
		splatter.position = (effect_parent as Node2D).to_local(spawn_position)
	else:
		splatter.global_position = spawn_position
	effect_parent.call_deferred("add_child", splatter)
