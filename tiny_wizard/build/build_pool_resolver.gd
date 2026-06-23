class_name BuildPoolResolver
extends RefCounted


static func get_candidates(character: Node, catalog: Variant, required_pool_tags: Array[StringName] = []) -> Array[BuildItemDefinition]:
	var candidates: Array[BuildItemDefinition] = []
	if character == null:
		return candidates
	var controller := character.get_node_or_null("TiemuBuildController") as TiemuBuildController
	if controller == null:
		return candidates
	var definitions: Array = catalog.items if catalog is BuildCatalog else catalog if catalog is Array else []
	for value in definitions:
		var definition := value as BuildItemDefinition
		if definition == null or not definition.enabled:
			continue
		if not _has_all_pool_tags(definition, required_pool_tags):
			continue
		if controller.can_install(definition).is_success():
			candidates.append(definition)
	return candidates


static func pick_candidate(character: Node, catalog: Variant, required_pool_tags: Array[StringName] = [], rng: RandomNumberGenerator = null) -> BuildItemDefinition:
	var candidates := get_candidates(character, catalog, required_pool_tags)
	if candidates.is_empty():
		return null
	if rng == null:
		return candidates.pick_random()
	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func find_tiemu_character(root: Node) -> Node:
	if root == null:
		return null
	if root.get_node_or_null("TiemuBuildController") is TiemuBuildController:
		return root
	for child in root.get_children():
		var found := find_tiemu_character(child)
		if found != null:
			return found
	return null


static func _has_all_pool_tags(definition: BuildItemDefinition, required_pool_tags: Array[StringName]) -> bool:
	for tag in required_pool_tags:
		if not definition.pool_tags.has(tag):
			return false
	return true
