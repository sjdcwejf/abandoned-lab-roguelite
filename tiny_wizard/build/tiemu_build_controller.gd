class_name TiemuBuildController
extends Node

signal build_changed
signal item_installed(item_id: StringName, slot_index: int, stack_count: int)
signal item_removed(item_id: StringName, slot_index: int)
signal item_replaced(old_item_id: StringName, new_item_id: StringName, slot_index: int)
signal installation_failed(item_id: StringName, reason: String)
signal synergy_activated(synergy_id: StringName)
signal synergy_deactivated(synergy_id: StringName)
signal derived_stats_changed(snapshot: Dictionary)

@export_range(0, 999, 1, "or_greater") var organ_capacity: int = 6
@export_range(0, 999, 1, "or_greater") var relic_capacity: int = 4
@export var debug_logging: bool = true

class InstalledEntry extends RefCounted:
	var definition: BuildItemDefinition
	var slot_index: int
	var occupied_slots: Array[int] = []
	var stack_count: int = 1
	var install_order: int

var _character: Node
var _item_catalog: Array[BuildItemDefinition] = []
var _synergy_catalog: Array[BuildSynergyDefinition] = []
var _slots: Array[InstalledEntry] = []
var _entries: Array[InstalledEntry] = []
var _tag_counts: Dictionary[StringName, int] = {}
var _active_synergies: Dictionary[StringName, BuildSynergyDefinition] = {}
var _derived_stats_snapshot: Dictionary = {}
var _next_install_order: int = 0
var _base_stat_values: Dictionary[StringName, Variant] = {}
var _effect_last_triggered_msec: Dictionary[int, int] = {}


func _ready() -> void:
	if _character == null:
		_character = get_parent()
	_ensure_slot_storage()
	var resolver := CombatResolver.get_instance()
	if resolver != null and not resolver.event_emitted.is_connected(_on_combat_event):
		resolver.event_emitted.connect(_on_combat_event)


func initialize(character: Node, item_catalog: Variant, synergy_catalog: Variant) -> void:
	_restore_all_applied_stats()
	_character = character
	_base_stat_values.clear()
	_item_catalog = _extract_items(item_catalog)
	_synergy_catalog = _extract_synergies(synergy_catalog)
	reset_run()


func can_install(definition: BuildItemDefinition, preferred_slot: int = -1) -> BuildInstallResult:
	_ensure_slot_storage()
	if definition == null or not definition.is_valid():
		return _result(BuildInstallResult.Status.INVALID_ITEM, definition, "Invalid item definition")
	if not definition.enabled:
		return _result(BuildInstallResult.Status.ITEM_DISABLED, definition, "Item is disabled")
	if definition.item_type != BuildItemDefinition.ItemType.ORGAN and definition.item_type != BuildItemDefinition.ItemType.RELIC:
		return _result(BuildInstallResult.Status.INVALID_ITEM_TYPE, definition, "Unsupported item type")

	var existing := _find_entry(definition.id)
	if existing != null:
		if existing.stack_count >= definition.max_stacks:
			return _result(BuildInstallResult.Status.MAX_STACKS, definition, "Maximum stacks reached", existing.slot_index, existing.stack_count)
		return _result(BuildInstallResult.Status.SUCCESS, definition, "Stack can be added", existing.slot_index, existing.stack_count + 1)

	var compatibility_error := _validate_compatibility(definition)
	if compatibility_error != null:
		return compatibility_error

	var slot_index := _find_available_slot(definition, preferred_slot)
	if slot_index < 0:
		var status := BuildInstallResult.Status.INVALID_SLOT if preferred_slot >= 0 or definition.organ_slot >= 0 else BuildInstallResult.Status.NO_CAPACITY
		return _result(status, definition, "No compatible slot range is available")
	return _result(BuildInstallResult.Status.SUCCESS, definition, "Item can be installed", slot_index, 1)


func install(definition: BuildItemDefinition, preferred_slot: int = -1) -> BuildInstallResult:
	var result := can_install(definition, preferred_slot)
	if not result.is_success():
		_emit_installation_failed(definition, result.message)
		return result

	var existing := _find_entry(definition.id)
	if existing != null:
		existing.stack_count += 1
		result.stack_count = existing.stack_count
		_after_build_mutation()
		item_installed.emit(definition.id, existing.slot_index, existing.stack_count)
		_log("Stacked %s to %d" % [definition.id, existing.stack_count])
		return result

	var entry := _create_entry(definition, result.slot_index)
	_entries.append(entry)
	_fill_slots(entry)
	_after_build_mutation()
	item_installed.emit(definition.id, entry.slot_index, entry.stack_count)
	_log("Installed %s at slot %d" % [definition.id, entry.slot_index])
	return result


func replace(slot_index: int, definition: BuildItemDefinition) -> BuildInstallResult:
	var old_entry := _entry_at(slot_index)
	if old_entry == null:
		var empty_result := _result(BuildInstallResult.Status.INVALID_SLOT, definition, "No installed item at slot")
		_emit_installation_failed(definition, empty_result.message)
		return empty_result
	if definition != null and definition.id != old_entry.definition.id and has_item(definition.id):
		var duplicate_result := _result(BuildInstallResult.Status.DUPLICATE_ITEM, definition, "Replacement item is installed in another slot")
		_emit_installation_failed(definition, duplicate_result.message)
		return duplicate_result

	var old_active_synergies := _active_synergies.duplicate()
	var old_derived_stats := _derived_stats_snapshot.duplicate(true)
	var old_index := _entries.find(old_entry)
	_entries.remove_at(old_index)
	_clear_slots(old_entry)
	_rebuild_runtime_caches(false)
	var result := can_install(definition, old_entry.slot_index)
	if not result.is_success():
		_entries.insert(old_index, old_entry)
		_fill_slots(old_entry)
		_rebuild_runtime_caches(false)
		_emit_installation_failed(definition, result.message)
		return result

	var new_entry := _create_entry(definition, result.slot_index)
	_entries.insert(old_index, new_entry)
	_fill_slots(new_entry)
	_active_synergies = old_active_synergies
	_derived_stats_snapshot = old_derived_stats
	_after_build_mutation()
	item_replaced.emit(old_entry.definition.id, definition.id, new_entry.slot_index)
	_log("Replaced %s with %s at slot %d" % [old_entry.definition.id, definition.id, new_entry.slot_index])
	return result


func remove_at(slot_index: int) -> bool:
	var entry := _entry_at(slot_index)
	if entry == null:
		return false
	_entries.erase(entry)
	_clear_slots(entry)
	_after_build_mutation()
	item_removed.emit(entry.definition.id, entry.slot_index)
	_log("Removed %s from slot %d" % [entry.definition.id, entry.slot_index])
	return true


func has_item(item_id: StringName) -> bool:
	return _find_entry(item_id) != null


func get_stack_count(item_id: StringName) -> int:
	var entry := _find_entry(item_id)
	return entry.stack_count if entry != null else 0


func has_tag(tag: StringName) -> bool:
	return get_tag_count(tag) > 0


func get_tag_count(tag: StringName) -> int:
	return _tag_counts.get(tag, 0)


func get_installed_organs() -> Array:
	return _get_installed_by_type(BuildItemDefinition.ItemType.ORGAN)


func get_installed_relics() -> Array:
	return _get_installed_by_type(BuildItemDefinition.ItemType.RELIC)


func get_active_synergies() -> Array:
	var definitions: Array[BuildSynergyDefinition] = []
	for synergy in _synergy_catalog:
		if _active_synergies.has(synergy.id):
			definitions.append(synergy)
	return definitions


func get_build_snapshot() -> Dictionary:
	var installed: Array[Dictionary] = []
	var installed_organs: Array[Dictionary] = []
	var installed_relics: Array[Dictionary] = []
	var ordered_entries := _entries.duplicate()
	ordered_entries.sort_custom(func(a: InstalledEntry, b: InstalledEntry) -> bool: return a.install_order < b.install_order)
	for entry in ordered_entries:
		var item_snapshot: Dictionary = {
			"item_id": entry.definition.id,
			"display_name": entry.definition.display_name,
			"item_type": entry.definition.item_type,
			"slot_index": entry.slot_index,
			"occupied_slots": entry.occupied_slots.duplicate(),
			"stack_count": entry.stack_count,
			"install_order": entry.install_order,
		}
		installed.append(item_snapshot)
		if entry.definition.item_type == BuildItemDefinition.ItemType.ORGAN:
			installed_organs.append(item_snapshot)
		else:
			installed_relics.append(item_snapshot)
	return {
		"character": _character,
		"organ_capacity": organ_capacity,
		"relic_capacity": relic_capacity,
		"installed": installed,
		"installed_organs": installed_organs,
		"installed_relics": installed_relics,
		"tag_counts": _tag_counts.duplicate(),
		"active_synergy_ids": _active_synergies.keys(),
		"derived_stats": _derived_stats_snapshot.duplicate(true),
	}


func reset_run() -> void:
	var previous_synergy_ids := _active_synergies.keys()
	_restore_all_applied_stats()
	_slots.clear()
	_slots.resize(organ_capacity + relic_capacity)
	_entries.clear()
	_tag_counts.clear()
	_active_synergies.clear()
	_derived_stats_snapshot.clear()
	_effect_last_triggered_msec.clear()
	_next_install_order = 0
	for synergy_id in previous_synergy_ids:
		synergy_deactivated.emit(synergy_id)
	build_changed.emit()
	derived_stats_changed.emit({})
	_log("Build state reset")


func _extract_items(source: Variant) -> Array[BuildItemDefinition]:
	var definitions: Array[BuildItemDefinition] = []
	var values: Array = source.items if source is BuildCatalog else source if source is Array else []
	for value in values:
		if value is BuildItemDefinition:
			definitions.append(value)
	return definitions


func _extract_synergies(source: Variant) -> Array[BuildSynergyDefinition]:
	var definitions: Array[BuildSynergyDefinition] = []
	var values: Array = source.synergies if source is BuildCatalog else source if source is Array else []
	for value in values:
		if value is BuildSynergyDefinition:
			definitions.append(value)
	return definitions


func _validate_compatibility(definition: BuildItemDefinition) -> BuildInstallResult:
	if not definition.unique_group.is_empty():
		for entry in _entries:
			if entry.definition.unique_group == definition.unique_group:
				return _result(BuildInstallResult.Status.UNIQUE_CONFLICT, definition, "Unique group is already occupied: %s" % definition.unique_group)
	for required_id in definition.required_item_ids:
		if not has_item(required_id):
			return _result(BuildInstallResult.Status.MISSING_REQUIREMENT, definition, "Required item is missing: %s" % required_id)
	for excluded_id in definition.excluded_item_ids:
		if has_item(excluded_id):
			return _result(BuildInstallResult.Status.EXCLUDED_CONFLICT, definition, "Excluded item is installed: %s" % excluded_id)
	for required_tag in definition.required_tags:
		if not has_tag(required_tag):
			return _result(BuildInstallResult.Status.MISSING_REQUIREMENT, definition, "Required tag is missing: %s" % required_tag)
	for excluded_tag in definition.excluded_tags:
		if has_tag(excluded_tag):
			return _result(BuildInstallResult.Status.EXCLUDED_CONFLICT, definition, "Excluded tag is present: %s" % excluded_tag)
	return null


func _find_available_slot(definition: BuildItemDefinition, preferred_slot: int) -> int:
	var segment_start := 0 if definition.item_type == BuildItemDefinition.ItemType.ORGAN else organ_capacity
	var segment_end := organ_capacity if definition.item_type == BuildItemDefinition.ItemType.ORGAN else organ_capacity + relic_capacity
	var requested_slot := preferred_slot
	if definition.item_type == BuildItemDefinition.ItemType.ORGAN and definition.organ_slot >= 0:
		var required_slot := segment_start + definition.organ_slot
		if preferred_slot >= 0 and preferred_slot != required_slot:
			return -1
		requested_slot = required_slot
	if requested_slot >= 0:
		return requested_slot if _slot_range_is_free(requested_slot, definition.slot_cost, segment_start, segment_end) else -1
	for slot_index in range(segment_start, segment_end):
		if _slot_range_is_free(slot_index, definition.slot_cost, segment_start, segment_end):
			return slot_index
	return -1


func _slot_range_is_free(slot_index: int, cost: int, segment_start: int, segment_end: int) -> bool:
	if slot_index < segment_start or slot_index + cost > segment_end:
		return false
	for index in range(slot_index, slot_index + cost):
		if index < 0 or index >= _slots.size():
			return false
		if _slots[index] != null:
			return false
	return true


func _ensure_slot_storage() -> void:
	var expected_size := organ_capacity + relic_capacity
	if _slots.size() == expected_size:
		return
	_slots.clear()
	_slots.resize(expected_size)
	for entry in _entries:
		for index in entry.occupied_slots:
			if index >= 0 and index < _slots.size():
				_slots[index] = entry


func _create_entry(definition: BuildItemDefinition, slot_index: int) -> InstalledEntry:
	var entry := InstalledEntry.new()
	entry.definition = definition
	entry.slot_index = slot_index
	entry.install_order = _next_install_order
	_next_install_order += 1
	for index in range(slot_index, slot_index + definition.slot_cost):
		entry.occupied_slots.append(index)
	return entry


func _fill_slots(entry: InstalledEntry) -> void:
	for index in entry.occupied_slots:
		_slots[index] = entry


func _clear_slots(entry: InstalledEntry) -> void:
	for index in entry.occupied_slots:
		_slots[index] = null


func _entry_at(slot_index: int) -> InstalledEntry:
	if slot_index < 0 or slot_index >= _slots.size():
		return null
	return _slots[slot_index]


func _find_entry(item_id: StringName) -> InstalledEntry:
	for entry in _entries:
		if entry.definition.id == item_id:
			return entry
	return null


func _get_installed_by_type(item_type: BuildItemDefinition.ItemType) -> Array:
	var definitions: Array[BuildItemDefinition] = []
	for entry in _entries:
		if entry.definition.item_type == item_type:
			definitions.append(entry.definition)
	return definitions


func _after_build_mutation() -> void:
	_rebuild_runtime_caches(true)
	build_changed.emit()


func _rebuild_runtime_caches(emit_changes: bool) -> void:
	_rebuild_tag_counts()
	_rebuild_synergies(emit_changes)
	_rebuild_derived_stats(emit_changes)


func _rebuild_tag_counts() -> void:
	_tag_counts.clear()
	for entry in _entries:
		for tag in entry.definition.tags:
			_tag_counts[tag] = _tag_counts.get(tag, 0) + entry.stack_count


func _rebuild_synergies(emit_changes: bool) -> void:
	var previous := _active_synergies.duplicate()
	_active_synergies.clear()
	for synergy in _synergy_catalog:
		if synergy != null and synergy.is_valid() and _is_synergy_active(synergy):
			_active_synergies[synergy.id] = synergy
	if not emit_changes:
		return
	for synergy_id in _active_synergies:
		if not previous.has(synergy_id):
			synergy_activated.emit(synergy_id)
			_log("Activated synergy %s" % synergy_id)
	for synergy_id in previous:
		if not _active_synergies.has(synergy_id):
			synergy_deactivated.emit(synergy_id)
			_log("Deactivated synergy %s" % synergy_id)


func _is_synergy_active(synergy: BuildSynergyDefinition) -> bool:
	for requirement in synergy.tag_requirements:
		if not requirement.is_satisfied_by(get_tag_count(requirement.tag)):
			return false
	return true


func _rebuild_derived_stats(emit_changes: bool) -> void:
	var next_snapshot: Dictionary = {}
	for entry in _entries:
		for modifier in entry.definition.stat_modifiers:
			_accumulate_modifier(next_snapshot, modifier, entry.stack_count)
	for synergy in _active_synergies.values():
		for modifier in synergy.stat_modifiers:
			_accumulate_modifier(next_snapshot, modifier, 1)
	var changed := next_snapshot != _derived_stats_snapshot
	_derived_stats_snapshot = next_snapshot
	_apply_derived_stats_to_character()
	if emit_changes and changed:
		derived_stats_changed.emit(_derived_stats_snapshot.duplicate(true))


func _accumulate_modifier(snapshot: Dictionary, modifier: BuildStatModifier, stacks: int) -> void:
	if modifier == null or not modifier.is_valid():
		return
	var stat: Dictionary = snapshot.get(modifier.stat_id, {
		"add": 0.0,
		"multiply": 1.0,
		"override": null,
		"override_priority": -2147483648,
	})
	match modifier.operation:
		BuildStatModifier.Operation.ADD:
			stat["add"] += modifier.value * stacks
		BuildStatModifier.Operation.MULTIPLY:
			stat["multiply"] *= pow(modifier.value, stacks)
		BuildStatModifier.Operation.OVERRIDE:
			if modifier.priority >= stat["override_priority"]:
				stat["override"] = modifier.value
				stat["override_priority"] = modifier.priority
	snapshot[modifier.stat_id] = stat


func _result(status: BuildInstallResult.Status, item: BuildItemDefinition, message: String, slot_index: int = -1, stack_count: int = 0) -> BuildInstallResult:
	var result := BuildInstallResult.new()
	result.status = status
	result.item = item
	result.message = message
	result.slot_index = slot_index
	result.stack_count = stack_count
	return result


func _emit_installation_failed(definition: BuildItemDefinition, reason: String) -> void:
	var item_id: StringName = definition.id if definition != null else &""
	installation_failed.emit(item_id, reason)
	_log("Installation failed for %s: %s" % [item_id, reason])


func _log(message: String) -> void:
	if debug_logging:
		print("[TiemuBuildController] ", message)


func _on_combat_event(event: CombatEvent) -> void:
	if event.attacker == _character or event.target == _character:
		dispatch_combat_event(event)


func dispatch_combat_event(event: CombatEvent) -> void:
	if event == null:
		return
	_log("Combat event %s: %s -> %s, amount=%s" % [
		CombatEvent.EventType.keys()[event.event_type],
		event.attacker,
		event.target,
		event.final_amount,
	])
	if event.tags.has(&"secondary_effect"):
		return
	var trigger := _get_effect_trigger(event)
	if trigger < 0:
		return
	for entry in _entries:
		for stack_index in entry.stack_count:
			for effect in entry.definition.event_effects:
				_try_execute_event_effect(effect, trigger, event)
	for synergy in _active_synergies.values():
		for effect in synergy.event_effects:
			_try_execute_event_effect(effect, trigger, event)


func _get_effect_trigger(event: CombatEvent) -> int:
	if event.event_type == CombatEvent.EventType.DAMAGE_DEALT and event.target == _character:
		return BuildEventEffect.Trigger.ON_DAMAGE_TAKEN
	if event.event_type == CombatEvent.EventType.DAMAGE_DEALT and event.attacker == _character:
		return BuildEventEffect.Trigger.ON_DAMAGE_DEALT
	if (event.event_type == CombatEvent.EventType.KILL or event.event_type == CombatEvent.EventType.ENEMY_DIED) and event.attacker == _character:
		return BuildEventEffect.Trigger.ON_ENEMY_DEFEATED
	return -1


func _try_execute_event_effect(effect: BuildEventEffect, trigger: int, event: CombatEvent) -> void:
	if effect == null or not effect.is_valid() or effect.trigger != trigger:
		return
	var effect_key := effect.get_instance_id()
	var now := Time.get_ticks_msec()
	var cooldown_msec := int(effect.cooldown * 1000.0)
	if cooldown_msec > 0 and now - _effect_last_triggered_msec.get(effect_key, -cooldown_msec) < cooldown_msec:
		return
	if randf() > effect.chance:
		return
	_effect_last_triggered_msec[effect_key] = now
	match effect.effect_type:
		BuildEventEffect.EffectType.DEAL_DAMAGE:
			_execute_secondary_damage(effect, event)
		BuildEventEffect.EffectType.SPAWN_SCENE:
			_execute_spawn_effect(effect, event)


func _execute_secondary_damage(effect: BuildEventEffect, event: CombatEvent) -> void:
	for target in _find_effect_targets(effect, event):
		var secondary := CombatEvent.new()
		secondary.attacker = _character
		secondary.target = target
		secondary.source = effect
		secondary.weapon_id = &"build.secondary_effect"
		secondary.damage_type = CombatEvent.DamageType.PHYSICAL
		secondary.base_amount = effect.magnitude
		secondary.final_amount = effect.magnitude
		secondary.hit_position = (_character as Node2D).global_position if _character is Node2D else event.hit_position
		secondary.tags = effect.event_tags.duplicate()
		if not secondary.tags.has(&"secondary_effect"):
			secondary.tags.append(&"secondary_effect")
		CombatResolver.resolve_damage(secondary)


func _execute_spawn_effect(effect: BuildEventEffect, event: CombatEvent) -> void:
	if effect.scene == null:
		return
	var parent := _get_effect_spawn_parent(event)
	if parent == null:
		return
	var count := maxi(1, int(round(effect.magnitude)))
	for index in count:
		var spawned := effect.scene.instantiate() as Node2D
		if spawned == null:
			continue
		var spawn_position := event.hit_position
		if event.target is Node2D:
			spawn_position = (event.target as Node2D).global_position
		if parent is Node2D:
			spawned.position = (parent as Node2D).to_local(spawn_position)
		else:
			spawned.position = spawn_position
		parent.call_deferred("add_child", spawned)


func _find_effect_targets(effect: BuildEventEffect, event: CombatEvent) -> Array[Object]:
	var candidates: Array[Object] = []
	var room := _get_effect_room(event)
	var search_root: Node = room.get_node_or_null("Enemies") if room != null else get_tree().current_scene
	if search_root == null:
		return candidates
	_collect_damage_targets(search_root, candidates, effect.radius)
	if effect.target == BuildEventEffect.Target.NEAREST_ENEMY and candidates.size() > 1:
		candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			return a.global_position.distance_squared_to((_character as Node2D).global_position) < b.global_position.distance_squared_to((_character as Node2D).global_position)
		)
		candidates.resize(1)
	return candidates


func _collect_damage_targets(root: Node, output: Array[Object], radius: float) -> void:
	for child in root.get_children():
		if child != _character and child is Node2D and child.has_method("hit"):
			if radius <= 0.0 or not _character is Node2D or (child as Node2D).global_position.distance_to((_character as Node2D).global_position) <= radius:
				output.append(child)
		_collect_damage_targets(child, output, radius)


func _get_effect_room(event: CombatEvent) -> Node:
	if event.room != null and is_instance_valid(event.room):
		return event.room
	if _character != null and _character.get_parent() != null and _character.get_parent().has_method("get_current_room"):
		return _character.get_parent().call("get_current_room") as Node
	return null


func _get_effect_spawn_parent(event: CombatEvent) -> Node:
	var room := _get_effect_room(event)
	if room != null:
		return room
	if event.target is Node and (event.target as Node).get_parent() != null:
		return (event.target as Node).get_parent()
	return get_tree().current_scene


func _apply_derived_stats_to_character() -> void:
	if _character == null:
		return
	var stats: Object = _character.get("character_stats")
	if stats == null:
		return
	for stat_id in _derived_stats_snapshot:
		if not stat_id in stats:
			continue
		if not _base_stat_values.has(stat_id):
			_base_stat_values[stat_id] = stats.get(stat_id)
		var values: Dictionary = _derived_stats_snapshot[stat_id]
		var resolved := float(_base_stat_values[stat_id])
		resolved = (resolved + float(values.get("add", 0.0))) * float(values.get("multiply", 1.0))
		if values.get("override") != null:
			resolved = float(values["override"])
		stats.set(stat_id, int(round(resolved)) if _base_stat_values[stat_id] is int else resolved)
	var removed_stats: Array[StringName] = []
	for stat_id in _base_stat_values:
		if not _derived_stats_snapshot.has(stat_id):
			stats.set(stat_id, _base_stat_values[stat_id])
			removed_stats.append(stat_id)
	for stat_id in removed_stats:
		_base_stat_values.erase(stat_id)


func _restore_all_applied_stats() -> void:
	if _character != null:
		var stats: Object = _character.get("character_stats")
		if stats != null:
			for stat_id in _base_stat_values:
				if stat_id in stats:
					stats.set(stat_id, _base_stat_values[stat_id])
	_base_stat_values.clear()
