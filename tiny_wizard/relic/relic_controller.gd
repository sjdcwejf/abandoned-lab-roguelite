class_name RelicController
extends Node

signal relic_added(relic_id, stack_count)
signal relic_removed(relic_id)
signal relics_changed
signal relic_install_failed(relic_id, reason)
signal synergy_activated(synergy_id)
signal synergy_deactivated(synergy_id)

const DEFAULT_SYNERGY_DEFINITIONS: Array[BuildSynergyDefinition] = [
	preload("res://tiny_wizard/build/test_synergies/neutral_split_growth.tres"),
	preload("res://tiny_wizard/build/test_synergies/tiemu_spine_growth.tres"),
	preload("res://tiny_wizard/build/test_synergies/tiemu_living_spine.tres"),
]
const PROTOMATTER_FRAGMENT_ITEM := preload("res://tiny_wizard/items/protomatter_fragment/protomatter_fragment.tres")

const RELIC_SPLIT_EMBRYO_CORE := &"split_embryo_core"
const RELIC_FUNGAL_MEMORY_CAP := &"fungal_memory_cap"
const RELIC_TIEMU_SPINE_SHIELD_FRAGMENT := &"tiemu_spine_shield_fragment"
const RELIC_TIEMU_LIVING_ARMOR_PLATE := &"tiemu_living_armor_plate"

const SPLIT_EXTRA_FRAGMENT_CHANCE := 0.18
const SPINE_COUNTER_CHANCE := 0.35
const SPINE_COUNTER_RADIUS := 92.0
const SPINE_COUNTER_DAMAGE := 1

var character: Node
var item_catalog: BuildCatalog
var character_id: StringName
@export var synergy_definitions: Array[BuildSynergyDefinition] = []

var _relics: Dictionary = {}
var _tag_counts: Dictionary = {}
var _unique_groups: Dictionary = {}
var _active_synergies: Dictionary = {}


func initialize(owner_character: Node, catalog: BuildCatalog) -> void:
	character = owner_character
	item_catalog = catalog
	if character_id == &"":
		character_id = _resolve_character_id(owner_character)


func can_add_relic(definition: BuildItemDefinition) -> BuildInstallResult:
	if definition == null:
		return BuildInstallResult.fail(BuildInstallResult.Reason.NULL_DEFINITION, "Relic definition is null.")
	if not definition.enabled:
		return BuildInstallResult.fail(BuildInstallResult.Reason.DISABLED, "Relic is disabled.")
	if definition.item_type != BuildItemDefinition.ItemType.RELIC:
		return BuildInstallResult.fail(BuildInstallResult.Reason.WRONG_ITEM_TYPE, "Definition is not a relic.")
	if definition.relic_scope == BuildItemDefinition.RelicScope.NONE:
		return BuildInstallResult.fail(BuildInstallResult.Reason.WRONG_RELIC_SCOPE, "Relic scope is none.")
	if definition.relic_scope == BuildItemDefinition.RelicScope.CHARACTER_EXCLUSIVE:
		if definition.owner_character_id == &"":
			return BuildInstallResult.fail(BuildInstallResult.Reason.CHARACTER_SCOPE_MISMATCH, "Exclusive relic has no owner character.")
		if definition.owner_character_id != character_id:
			return BuildInstallResult.fail(BuildInstallResult.Reason.CHARACTER_SCOPE_MISMATCH, "Relic is exclusive to %s." % definition.owner_character_id)

	var relic_id := definition.item_id
	var current_stack := get_relic_stack(relic_id)
	if current_stack >= max(1, definition.max_stacks):
		return BuildInstallResult.fail(BuildInstallResult.Reason.MAX_STACKS_REACHED, "Relic stack limit reached.")

	if definition.unique_group != &"":
		var blocking_relic_id: StringName = _unique_groups.get(definition.unique_group, &"")
		if blocking_relic_id != &"" and blocking_relic_id != relic_id:
			return BuildInstallResult.fail(BuildInstallResult.Reason.UNIQUE_GROUP_BLOCKED, "Unique group already owned.")

	for required_id in definition.required_item_ids:
		if not has_relic(required_id):
			return BuildInstallResult.fail(BuildInstallResult.Reason.REQUIRED_ITEM_MISSING, "Required relic is missing.")

	for excluded_id in definition.excluded_item_ids:
		if has_relic(excluded_id):
			return BuildInstallResult.fail(BuildInstallResult.Reason.EXCLUDED_ITEM_OWNED, "Excluded relic is already owned.")

	return BuildInstallResult.ok()


func add_relic(definition: BuildItemDefinition) -> BuildInstallResult:
	var result := can_add_relic(definition)
	if not result.success:
		var failed_id: StringName = &""
		if definition != null:
			failed_id = definition.item_id
		relic_install_failed.emit(failed_id, result.reason)
		return result

	var relic_id := definition.item_id
	var entry: Dictionary = _relics.get(relic_id, {
		"definition": definition,
		"stack_count": 0,
	})
	entry["definition"] = definition
	entry["stack_count"] = int(entry["stack_count"]) + 1
	_relics[relic_id] = entry

	if definition.unique_group != &"":
		_unique_groups[definition.unique_group] = relic_id

	for tag in definition.tags:
		_tag_counts[tag] = int(_tag_counts.get(tag, 0)) + 1

	_refresh_synergies()
	relic_added.emit(relic_id, int(entry["stack_count"]))
	relics_changed.emit()
	return result


func remove_relic(relic_id: StringName) -> bool:
	if not _relics.has(relic_id):
		return false

	var entry: Dictionary = _relics[relic_id]
	var definition: BuildItemDefinition = entry.get("definition", null)
	_relics.erase(relic_id)

	if definition != null:
		if definition.unique_group != &"" and _unique_groups.get(definition.unique_group, &"") == relic_id:
			_unique_groups.erase(definition.unique_group)
		for tag in definition.tags:
			var next_count := int(_tag_counts.get(tag, 0)) - int(entry.get("stack_count", 1))
			if next_count > 0:
				_tag_counts[tag] = next_count
			else:
				_tag_counts.erase(tag)

	_refresh_synergies()
	relic_removed.emit(relic_id)
	relics_changed.emit()
	return true


func remove_one_relic(relic_id: StringName) -> bool:
	if not _relics.has(relic_id):
		return false

	var entry: Dictionary = _relics[relic_id]
	var definition: BuildItemDefinition = entry.get("definition", null)
	var stack_count := int(entry.get("stack_count", 0))
	if stack_count <= 0:
		_relics.erase(relic_id)
		return false

	stack_count -= 1
	_decrement_definition_tags(definition, 1)
	if stack_count > 0:
		entry["stack_count"] = stack_count
		_relics[relic_id] = entry
	else:
		_relics.erase(relic_id)
		if definition != null and definition.unique_group != &"" and _unique_groups.get(definition.unique_group, &"") == relic_id:
			_unique_groups.erase(definition.unique_group)

	_refresh_synergies()
	relic_removed.emit(relic_id)
	relics_changed.emit()
	return true


func has_relic(relic_id: StringName) -> bool:
	return _relics.has(relic_id)


func get_relic_stack(relic_id: StringName) -> int:
	if not _relics.has(relic_id):
		return 0
	return int(_relics[relic_id].get("stack_count", 0))


func get_total_relic_count() -> int:
	var total := 0
	for relic_id in _relics.keys():
		total += int(_relics[relic_id].get("stack_count", 0))
	return total


func get_first_relic_id() -> StringName:
	for relic_id in _relics.keys():
		if int(_relics[relic_id].get("stack_count", 0)) > 0:
			return relic_id
	return &""


func has_tag(tag: StringName) -> bool:
	return get_tag_count(tag) > 0


func get_tag_count(tag: StringName) -> int:
	return int(_tag_counts.get(tag, 0))


func get_relic_snapshot() -> Dictionary:
	var relic_list: Array[Dictionary] = []
	for relic_id in _relics.keys():
		var entry: Dictionary = _relics[relic_id]
		var definition: BuildItemDefinition = entry.get("definition", null)
		relic_list.append({
			"relic_id": relic_id,
			"stack_count": int(entry.get("stack_count", 0)),
			"display_name": definition.display_name if definition != null else "",
			"placeholder_text": definition.placeholder_text if definition != null else "",
			"icon": definition.icon if definition != null else null,
			"tags": definition.tags.duplicate() if definition != null else [],
		})

	return {
		"relics": relic_list,
		"synergies": _build_synergy_snapshot(),
		"stacks": _build_stack_snapshot(),
		"tag_counts": _tag_counts.duplicate(),
	}


func reset_run() -> void:
	_relics.clear()
	_tag_counts.clear()
	_unique_groups.clear()
	_refresh_synergies()
	relics_changed.emit()


func modify_incoming_damage(amount: int, context := {}) -> int:
	var final_amount := maxi(0, amount)
	if _event_has_secondary_tag(context):
		return final_amount
	if has_relic(RELIC_TIEMU_LIVING_ARMOR_PLATE) and character_id == &"tiemu" and _character_has_shield():
		final_amount = maxi(0, final_amount - 1)
		print("活体甲片触发：护盾减伤。")
	return final_amount


func handle_combat_event(event_id: StringName, payload: Dictionary) -> void:
	var tags := _payload_tags(payload)
	if tags.has(RelicCombatEventBus.TAG_SECONDARY_EFFECT):
		return

	match event_id:
		&"enemy_killed":
			_handle_enemy_killed(payload)
		&"character_damaged":
			_handle_character_damaged(payload)


func handle_room_event(event_id: StringName, payload: Dictionary) -> void:
	match event_id:
		&"room_cleared":
			_handle_room_cleared(payload)


func _build_stack_snapshot() -> Dictionary:
	var stacks := {}
	for relic_id in _relics.keys():
		stacks[relic_id] = int(_relics[relic_id].get("stack_count", 0))
	return stacks


func _decrement_definition_tags(definition: BuildItemDefinition, amount: int) -> void:
	if definition == null:
		return
	for tag in definition.tags:
		var next_count := int(_tag_counts.get(tag, 0)) - amount
		if next_count > 0:
			_tag_counts[tag] = next_count
		else:
			_tag_counts.erase(tag)


func _resolve_character_id(owner_character: Node) -> StringName:
	if owner_character == null:
		return &""
	if owner_character.has_meta("character_id"):
		return StringName(str(owner_character.get_meta("character_id")))
	var ability_controller := owner_character.get_node_or_null("AbilityController")
	if ability_controller != null:
		var ability_id := str(ability_controller.get("ability_id"))
		if ability_id != "":
			return StringName(ability_id)
	return StringName(owner_character.name.to_lower())


func _handle_enemy_killed(payload: Dictionary) -> void:
	if not has_relic(RELIC_SPLIT_EMBRYO_CORE):
		return
	if randf() > SPLIT_EXTRA_FRAGMENT_CHANCE:
		return

	var enemy := payload.get("enemy", null) as Node
	var drop_parent := enemy.get_parent() if enemy != null else null
	if drop_parent != null and drop_parent.name == "Enemies" and drop_parent.get_parent() != null:
		drop_parent = drop_parent.get_parent()
	if drop_parent == null or PROTOMATTER_FRAGMENT_ITEM == null:
		return

	var item_node := PROTOMATTER_FRAGMENT_ITEM.create_pickable_item() as Node2D
	if item_node == null:
		return

	var drop_position := payload.get("global_position", Vector2.ZERO) as Vector2
	drop_position += Vector2(randf_range(-18.0, 18.0), randf_range(-12.0, 12.0))
	if drop_parent is Node2D:
		item_node.position = (drop_parent as Node2D).to_local(drop_position)
	else:
		item_node.global_position = drop_position
	drop_parent.call_deferred("add_child", item_node)
	print("裂殖胚核触发：生成额外原质碎片。")


func _handle_room_cleared(_payload: Dictionary) -> void:
	if not has_relic(RELIC_FUNGAL_MEMORY_CAP):
		return
	var stats := _get_character_stats()
	if stats == null:
		return
	if "current_shield" in stats:
		stats.set("current_shield", int(stats.get("current_shield")) + 1)
		print("菌忆伞盖触发：获得短暂护盾。")
		return
	if "current_life" in stats and "max_life" in stats:
		stats.set("current_life", mini(int(stats.get("max_life")), int(stats.get("current_life")) + 1))
		print("菌忆伞盖触发：恢复生命。")


func _handle_character_damaged(payload: Dictionary) -> void:
	if character_id != &"tiemu" or not has_relic(RELIC_TIEMU_SPINE_SHIELD_FRAGMENT):
		return
	if randf() > SPINE_COUNTER_CHANCE:
		return
	var owner := payload.get("character", character) as Node2D
	if owner == null:
		return
	var counter_count := _counter_damage_nearby_enemies(owner)
	if counter_count > 0:
		print("脊盾残片触发：反震 %d 个目标。" % counter_count)


func _counter_damage_nearby_enemies(owner: Node2D) -> int:
	var space_state := owner.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = SPINE_COUNTER_RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, owner.global_position)
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit_count := 0
	var results := space_state.intersect_shape(query, 16)
	for result in results:
		var collider := result.get("collider", null) as Object
		var damage_target := _find_damage_target(collider)
		if damage_target == null or damage_target == owner:
			continue
		var hit_from := Vector2.ZERO
		if damage_target is Node2D:
			hit_from = owner.global_position.direction_to((damage_target as Node2D).global_position)
		if RelicCombatEventBus.apply_secondary_damage(damage_target, SPINE_COUNTER_DAMAGE, hit_from):
			hit_count += 1
	return hit_count


func _find_damage_target(target: Object) -> Object:
	var current := target
	while current != null:
		if current.has_method("hit"):
			return current
		if current is Node:
			current = (current as Node).get_parent()
		else:
			current = null
	return null


func _get_character_stats() -> Resource:
	if character == null:
		return null
	return character.get("character_stats") as Resource


func _character_has_shield() -> bool:
	var stats := _get_character_stats()
	return stats != null and "current_shield" in stats and int(stats.get("current_shield")) > 0


func _payload_tags(payload: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	var raw_tags := payload.get("tags", []) as Array
	for tag in raw_tags:
		result.append(StringName(str(tag)))
	return result


func _event_has_secondary_tag(context: Dictionary) -> bool:
	var tags := _payload_tags(context)
	return tags.has(RelicCombatEventBus.TAG_SECONDARY_EFFECT)


func _refresh_synergies() -> void:
	var next_synergies := _evaluate_synergies()

	for synergy_id in _active_synergies.keys():
		if not next_synergies.has(synergy_id):
			synergy_deactivated.emit(synergy_id)

	for synergy_id in next_synergies.keys():
		if not _active_synergies.has(synergy_id):
			synergy_activated.emit(synergy_id)

	_active_synergies = next_synergies


func _evaluate_synergies() -> Dictionary:
	var eligible: Array[BuildSynergyDefinition] = []
	for synergy in _get_synergy_definitions():
		if _is_synergy_eligible(synergy):
			eligible.append(synergy)

	eligible.sort_custom(func(a: BuildSynergyDefinition, b: BuildSynergyDefinition) -> bool:
		if a.priority == b.priority:
			return a.tier > b.tier
		return a.priority > b.priority
	)

	var selected := {}
	var used_exclusive_groups := {}
	for synergy in eligible:
		if synergy.exclusive_group != &"":
			if used_exclusive_groups.has(synergy.exclusive_group):
				continue
			used_exclusive_groups[synergy.exclusive_group] = true
		selected[synergy.synergy_id] = synergy
	return selected


func _is_synergy_eligible(synergy: BuildSynergyDefinition) -> bool:
	if synergy == null or not synergy.enabled:
		return false
	if synergy.synergy_id == &"":
		return false
	if synergy.synergy_scope == BuildSynergyDefinition.SynergyScope.CHARACTER_EXCLUSIVE:
		if synergy.owner_character_id == &"" or synergy.owner_character_id != character_id:
			return false

	for relic_id in synergy.required_item_ids:
		if not has_relic(relic_id):
			return false

	for requirement in synergy.get_all_tag_requirements():
		if requirement == null:
			continue
		if not requirement.is_met(get_tag_count(requirement.tag)):
			return false

	return true


func _get_synergy_definitions() -> Array[BuildSynergyDefinition]:
	var result: Array[BuildSynergyDefinition] = []
	result.append_array(DEFAULT_SYNERGY_DEFINITIONS)
	if item_catalog != null:
		result.append_array(item_catalog.synergies)
	result.append_array(synergy_definitions)
	return result


func _build_synergy_snapshot() -> Array[Dictionary]:
	var synergy_list: Array[Dictionary] = []
	for synergy_id in _active_synergies.keys():
		var synergy: BuildSynergyDefinition = _active_synergies[synergy_id]
		if synergy == null:
			continue
		synergy_list.append({
			"synergy_id": synergy_id,
			"display_name": synergy.display_name,
			"placeholder_text": synergy.placeholder_text,
			"tier": synergy.tier,
			"priority": synergy.priority,
			"exclusive_group": synergy.exclusive_group,
		})
	return synergy_list
