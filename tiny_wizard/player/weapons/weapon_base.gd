class_name LabWeapon
extends Node2D


const ENEMY_PROJECTILE_GROUP := &"enemy_projectiles"
const WEAPON_AFFIX_SERVICE := preload("res://tiny_wizard/player/weapons/weapon_affix_service.gd")


@export var display_name := ""
@export var weapon_id := ""
@export var inventory_size := Vector2i(2, 1)
@export var inventory_color := Color(0.26, 0.62, 0.9, 1.0)
@export var rarity_name := "制式"
@export var combat_role := "通用"
@export_multiline var weapon_description := ""
@export var stat_damage_text := ""
@export var stat_rate_text := ""
@export var stat_energy_text := "无消耗"
@export var stat_range_text := ""
@export var special_text := ""

var owner_character: Node2D
var aim_direction := Vector2.RIGHT
var weapon_affixes: Array = []
var _visual_root: Node2D
var _visual_root_base_scale := Vector2.ONE
var _muzzle_nodes: Array[Node2D] = []
var _muzzle_base_positions := {}
var _orientation_nodes_ready := false


func get_inventory_display_name() -> String:
	var base_name := ""
	if display_name != "":
		base_name = display_name
	elif name != "":
		base_name = name
	else:
		base_name = "武器"
	return WEAPON_AFFIX_SERVICE.format_weapon_name(base_name, weapon_affixes)


func get_weapon_id() -> String:
	if weapon_id != "":
		return weapon_id
	if scene_file_path != "":
		return scene_file_path
	return name


func get_inventory_size() -> Vector2i:
	return Vector2i(maxi(1, inventory_size.x), maxi(1, inventory_size.y))


func get_inventory_color() -> Color:
	return inventory_color


func get_weapon_compare_info() -> Dictionary:
	return {
		"name": get_inventory_display_name(),
		"id": get_weapon_id(),
		"rarity": rarity_name,
		"role": combat_role,
		"description": _resolve_weapon_description(),
		"damage": _resolve_damage_text(),
		"rate": _resolve_rate_text(),
		"energy": _resolve_energy_text(),
		"range": _resolve_range_text(),
		"special": _resolve_special_text(),
		"size": get_inventory_size(),
		"color": get_inventory_color(),
		"affixes": weapon_affixes.duplicate(),
	}


func equip(new_owner: Node2D) -> void:
	owner_character = new_owner


func set_weapon_affixes(affixes: Array) -> void:
	weapon_affixes = WEAPON_AFFIX_SERVICE.normalize_affixes(affixes)


func get_weapon_affixes() -> Array:
	return weapon_affixes.duplicate()


func unequip() -> void:
	primary_released()
	secondary_released()
	owner_character = null


func set_aim_direction(direction: Vector2) -> void:
	if direction.length() == 0:
		return
	aim_direction = direction.normalized()
	if not is_node_ready():
		call_deferred("_apply_visual_orientation")
		return
	_apply_visual_orientation()


func primary_pressed() -> void:
	pass


func primary_released() -> void:
	pass


func secondary_pressed() -> void:
	pass


func secondary_released() -> void:
	pass


func get_fire_cooldown_multiplier() -> float:
	var multiplier := WEAPON_AFFIX_SERVICE.get_cooldown_multiplier(weapon_affixes)
	if owner_character != null:
		var ability_controller := owner_character.get_node_or_null("AbilityController") as LabPlayerAbilityController
		if ability_controller != null:
			multiplier *= ability_controller.get_fire_cooldown_multiplier()
	return multiplier


func get_scaled_damage(amount: int) -> int:
	return maxi(1, int(ceil(float(amount) * WEAPON_AFFIX_SERVICE.get_damage_multiplier(weapon_affixes))))


func get_modified_hit_damage(amount: int) -> int:
	return get_scaled_damage(amount) + WEAPON_AFFIX_SERVICE.roll_extra_hit_damage(weapon_affixes)


func get_fire_origin() -> Vector2:
	var muzzle := get_node_or_null("Muzzle") as Node2D
	if muzzle != null:
		return muzzle.global_position
	if owner_character != null:
		return owner_character.global_position + aim_direction * 22.0
	return global_position


func get_spawn_parent() -> Node:
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	if owner_character != null and owner_character.get_parent() != null:
		return owner_character.get_parent()
	return get_parent()


func find_damage_target(target: Object) -> Object:
	if target == null or target == owner_character:
		return null
	if target.has_method("hit"):
		return target
	if not target is Node:
		return null

	var current := (target as Node).get_parent()
	while current != null:
		if current == owner_character:
			return null
		if current.has_method("hit"):
			return current
		current = current.get_parent()
	return null


func apply_damage_to_target(target: Object, amount: int, hit_from := Vector2.ZERO, hit_origin := Vector2.ZERO) -> bool:
	var damage_target := find_damage_target(target)
	if damage_target == null:
		return false

	var final_hit_from := hit_from
	if final_hit_from == Vector2.ZERO and hit_origin != Vector2.ZERO and damage_target is Node2D:
		final_hit_from = ((damage_target as Node2D).global_position - hit_origin).normalized()

	var modified_amount := get_modified_hit_damage(amount)
	damage_target.hit(modified_amount, final_hit_from)
	_notify_owner_weapon_hit(damage_target, modified_amount)
	return true


func try_destroy_enemy_projectile(target: Object, deflect_direction := Vector2.ZERO) -> bool:
	if not target is Node:
		return false

	var projectile := target as Node
	if not projectile.is_in_group(ENEMY_PROJECTILE_GROUP):
		return false

	if projectile.has_method("deflect_by_melee"):
		projectile.call("deflect_by_melee", deflect_direction)
	else:
		projectile.queue_free()
	return true


func _notify_owner_weapon_hit(damage_target: Object, amount: int) -> void:
	if owner_character == null:
		return
	var ability_controller := owner_character.get_node_or_null("AbilityController") as LabPlayerAbilityController
	if ability_controller == null:
		return
	ability_controller.notify_weapon_hit(damage_target, amount)


func _resolve_weapon_description() -> String:
	if weapon_description != "":
		return weapon_description
	return "该武器尚未录入完整说明。"


func _resolve_damage_text() -> String:
	var suffix := _affix_stat_suffix()
	if stat_damage_text != "":
		return stat_damage_text + suffix
	if _has_weapon_property("damage"):
		return str(get_scaled_damage(int(get("damage")))) + suffix
	return "特殊" + suffix


func _resolve_rate_text() -> String:
	var suffix := " +速射" if WEAPON_AFFIX_SERVICE.normalize_affixes(weapon_affixes).has(WEAPON_AFFIX_SERVICE.AFFIX_RAPID) else ""
	if stat_rate_text != "":
		return stat_rate_text + suffix
	if not _has_weapon_property("cooldown"):
		return "持续" + suffix

	var cooldown_value := float(get("cooldown"))
	if cooldown_value <= 0.16:
		return "极快" + suffix
	if cooldown_value <= 0.3:
		return "快" + suffix
	if cooldown_value <= 0.48:
		return "中" + suffix
	return "慢" + suffix


func _resolve_energy_text() -> String:
	if stat_energy_text != "":
		return stat_energy_text
	return "无消耗"


func _resolve_range_text() -> String:
	if stat_range_text != "":
		return stat_range_text
	if _has_weapon_property("range"):
		return "远程"
	if _has_weapon_property("active_time"):
		return "近战"
	return "中程"


func _resolve_special_text() -> String:
	var notes := []
	var affix_line := WEAPON_AFFIX_SERVICE.format_affix_line(weapon_affixes)
	if affix_line != "":
		notes.append(affix_line)
	if special_text != "":
		notes.append(special_text)
		return "；".join(notes)
	if _has_weapon_property("can_destroy_enemy_projectiles") and bool(get("can_destroy_enemy_projectiles")):
		notes.append("挥击可打消敌方弹幕")
	if _has_weapon_property("pellet_count") and int(get("pellet_count")) > 1:
		notes.append("扇形多弹丸")
	if _has_weapon_property("knockback_multiplier") or _has_weapon_property("punch_knockback_multiplier"):
		notes.append("命中造成击退")
	if notes.is_empty():
		return "无特殊词条"
	return "；".join(notes)


func _affix_stat_suffix() -> String:
	if WEAPON_AFFIX_SERVICE.has_visible_affixes(weapon_affixes):
		return "（词条）"
	return ""


func _has_weapon_property(property_name: String) -> bool:
	for property_info in get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true
	return false


func _apply_visual_orientation() -> void:
	_ensure_orientation_nodes()
	var aim_angle := aim_direction.angle()
	var facing_left := absf(aim_angle) > PI * 0.5

	if _visual_root != null:
		var visual_scale := _visual_root_base_scale
		visual_scale.y = -absf(_visual_root_base_scale.y) if facing_left else absf(_visual_root_base_scale.y)
		_visual_root.scale = visual_scale

	for muzzle in _muzzle_nodes:
		if muzzle == null:
			continue
		var key := muzzle.get_instance_id()
		if not _muzzle_base_positions.has(key):
			continue
		var base_position := _muzzle_base_positions[key] as Vector2
		muzzle.position = Vector2(base_position.x, -base_position.y if facing_left else base_position.y)


func _ensure_orientation_nodes() -> void:
	if _orientation_nodes_ready:
		return
	_orientation_nodes_ready = true

	var existing_visual_root := get_node_or_null("VisualRoot") as Node2D
	if existing_visual_root != null:
		_visual_root = existing_visual_root
	else:
		var visual_candidates := _collect_visual_children_for_mirroring()
		if not visual_candidates.is_empty():
			_visual_root = Node2D.new()
			_visual_root.name = "VisualRoot"
			add_child(_visual_root)
			move_child(_visual_root, 0)
			for visual_node in visual_candidates:
				if visual_node != null and visual_node.get_parent() == self:
					visual_node.owner = null
					visual_node.reparent(_visual_root, false)

	if _visual_root != null:
		_visual_root_base_scale = _visual_root.scale

	_cache_muzzle_positions()


func _collect_visual_children_for_mirroring() -> Array[Node2D]:
	var visual_nodes: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and _is_visual_child_for_mirroring(child):
			visual_nodes.append(child as Node2D)
	return visual_nodes


func _is_visual_child_for_mirroring(child: Node) -> bool:
	if child == null:
		return false
	if child.name in [&"VisualRoot", &"Muzzle", &"HitArea", &"PunchArea", &"Beam"]:
		return false
	if child is Marker2D:
		return false
	if child is CollisionObject2D or child is CollisionShape2D:
		return false
	return child is CanvasItem


func _cache_muzzle_positions() -> void:
	_muzzle_nodes.clear()
	_muzzle_base_positions.clear()
	var muzzle := get_node_or_null("Muzzle") as Node2D
	if muzzle != null:
		_muzzle_nodes.append(muzzle)
		_muzzle_base_positions[muzzle.get_instance_id()] = muzzle.position
