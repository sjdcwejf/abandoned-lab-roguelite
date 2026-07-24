class_name ProtomatterDropEnemy
extends QuiverCharacter


const PROTOMATTER_FRAGMENT_ITEM := preload("res://tiny_wizard/items/protomatter_fragment/protomatter_fragment.tres")
const GREEN_BLOOD_SPLATTER_SCRIPT := preload("res://tiny_wizard/effects/green_blood_splatter.gd")
const SAFE_DROP_LOCAL_MIN := Vector2(96.0, 126.0)
const SAFE_DROP_LOCAL_MAX := Vector2(928.0, 462.0)
const BOTTOM_DOOR_CENTER_X := 512.0
const BOTTOM_DOOR_SAFE_HALF_WIDTH := 128.0
const BOTTOM_DOOR_SAFE_Y := 420.0

@export_range(0.0, 1.0, 0.01) var protomatter_drop_chance := 0.45
@export_range(0, 8, 1) var protomatter_min_drop := 1
@export_range(0, 8, 1) var protomatter_max_drop := 1
@export var protomatter_drop_spread := 22.0
@export_range(0.0, 1.0, 0.01) var relic_drop_chance := 0.0
@export var relic_pool_tag: StringName = &""
@export var green_blood_splatter_enabled := true
@export var green_blood_spawn_offset := Vector2(0.0, -28.0)
@export_range(0.2, 4.0, 0.1) var green_blood_splatter_scale := 1.0

var _protomatter_dropped := false
var _relic_dropped := false
var _debug_progression_context := {}


func set_debug_progression_context(context: Dictionary) -> void:
	_debug_progression_context = context.duplicate(true)


func hit(damage := 1, from := Vector2.ZERO) -> void:
	if green_blood_splatter_enabled and int(damage) > 0 and character_stats != null and character_stats.current_life > 0:
		_spawn_green_blood_splatter(from)
	var relic_controller := _find_active_relic_controller()
	if relic_controller != null:
		relic_controller.try_apply_condensation_to_target(self)
	super.hit(damage, from)


func die() -> void:
	_drop_protomatter_fragments()
	_drop_relic_from_pool()
	RelicCombatEventBus.notify_enemy_killed(self)
	super.die()


func _drop_protomatter_fragments() -> void:
	if _protomatter_dropped:
		return
	_protomatter_dropped = true

	if _debug_drops_blocked():
		return
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
		var drop_position := _get_safe_drop_position(drop_parent, global_position + Vector2.from_angle(angle) * distance)
		if drop_parent is Node2D:
			item_node.position = (drop_parent as Node2D).to_local(drop_position)
		else:
			item_node.global_position = drop_position
		drop_parent.call_deferred("add_child", item_node)


func _drop_relic_from_pool() -> bool:
	if _relic_dropped:
		return false
	_relic_dropped = true

	if _debug_drops_blocked():
		return false
	if relic_drop_chance <= 0.0 or randf() > relic_drop_chance:
		return false

	var drop_parent := _get_drop_parent()
	if drop_parent == null:
		return false

	var relic_controller := _find_active_relic_controller()
	if relic_controller == null:
		return false

	var drop_position := _get_safe_drop_position(drop_parent, global_position + Vector2(16.0, -8.0))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return RelicDropService.try_drop_relic_from_pool(drop_parent, relic_controller, drop_position, relic_pool_tag, rng)


func _debug_drops_blocked() -> bool:
	if _debug_progression_context.is_empty():
		return false
	if not bool(_debug_progression_context.get("debug_mode", false)):
		return false
	return not bool(_debug_progression_context.get("debug_combat_drops_enabled", false))


func _get_drop_parent() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	if parent.name == "Enemies" and parent.get_parent() != null:
		return parent.get_parent()
	return parent


func _find_active_relic_controller() -> RelicController:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return RelicDropService.find_relic_controller(scene)


func _get_safe_drop_position(drop_parent: Node, desired_global_position: Vector2) -> Vector2:
	if not drop_parent is Room:
		return desired_global_position

	var room := drop_parent as Room
	var local_position := desired_global_position - room.get_room_global_position()
	local_position.x = clampf(local_position.x, SAFE_DROP_LOCAL_MIN.x, SAFE_DROP_LOCAL_MAX.x)
	local_position.y = clampf(local_position.y, SAFE_DROP_LOCAL_MIN.y, SAFE_DROP_LOCAL_MAX.y)

	var is_near_bottom_door := (
		local_position.y > BOTTOM_DOOR_SAFE_Y
		and absf(local_position.x - BOTTOM_DOOR_CENTER_X) < BOTTOM_DOOR_SAFE_HALF_WIDTH
	)
	if is_near_bottom_door:
		local_position.y = BOTTOM_DOOR_SAFE_Y

	return room.get_room_global_position() + local_position


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
