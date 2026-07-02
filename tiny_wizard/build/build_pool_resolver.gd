class_name BuildPoolResolver
extends RefCounted

const DEFAULT_RELIC_DEFINITIONS: Array[BuildItemDefinition] = [
	preload("res://tiny_wizard/build/test_relics/split_embryo_core.tres"),
	preload("res://tiny_wizard/build/test_relics/fungal_memory_cap.tres"),
	preload("res://tiny_wizard/build/test_relics/hollow_tail_segment.tres"),
	preload("res://tiny_wizard/build/test_relics/tiemu_spine_shield_fragment.tres"),
	preload("res://tiny_wizard/build/test_relics/tiemu_living_armor_plate.tres"),
	preload("res://tiny_wizard/build/chapter3_relics/condensation_protocol.tres"),
	preload("res://tiny_wizard/build/chapter3_relics/stasis_protocol.tres"),
	preload("res://tiny_wizard/build/chapter3_relics/thermal_lining.tres"),
	preload("res://tiny_wizard/build/chapter3_relics/broken_coolant_valve.tres"),
	preload("res://tiny_wizard/build/chapter3_relics/stasis_tag.tres"),
]


static func get_available_relics(
	catalog: BuildCatalog,
	relic_controller: RelicController,
	pool_tag: StringName = &""
) -> Array[BuildItemDefinition]:
	var result: Array[BuildItemDefinition] = []
	if catalog == null:
		return result

	var candidates: Array[BuildItemDefinition]
	if pool_tag == &"":
		candidates = catalog.items
	else:
		candidates = catalog.get_items_by_pool_tag(pool_tag)

	for item in candidates:
		if item == null:
			continue
		if item.item_type != BuildItemDefinition.ItemType.RELIC:
			continue
		if not _is_relic_available_for_controller(item, relic_controller):
			continue
		result.append(item)

	return result


static func get_available_relics_from_items(
	items: Array[BuildItemDefinition],
	relic_controller: RelicController,
	pool_tag: StringName = &""
) -> Array[BuildItemDefinition]:
	var result: Array[BuildItemDefinition] = []
	for item in items:
		if item == null:
			continue
		if pool_tag != &"" and not item.pool_tags.has(pool_tag):
			continue
		if item.item_type != BuildItemDefinition.ItemType.RELIC:
			continue
		if not _is_relic_available_for_controller(item, relic_controller):
			continue
		result.append(item)
	return result


static func get_default_available_relics(
	relic_controller: RelicController,
	pool_tag: StringName = &""
) -> Array[BuildItemDefinition]:
	return get_available_relics_from_items(DEFAULT_RELIC_DEFINITIONS, relic_controller, pool_tag)


static func pick_random_relic(
	relic_controller: RelicController,
	rng: RandomNumberGenerator,
	pool_tag: StringName = &""
) -> BuildItemDefinition:
	var candidates := get_default_available_relics(relic_controller, pool_tag)
	if candidates.is_empty():
		return null
	if rng == null:
		return candidates.pick_random()
	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func _is_relic_available_for_controller(
	definition: BuildItemDefinition,
	relic_controller: RelicController
) -> bool:
	if definition == null:
		return false
	if relic_controller == null:
		return definition.relic_scope != BuildItemDefinition.RelicScope.NONE
	if relic_controller.has_relic(definition.item_id):
		return false
	var install_result := relic_controller.can_add_relic(definition)
	return install_result.success
