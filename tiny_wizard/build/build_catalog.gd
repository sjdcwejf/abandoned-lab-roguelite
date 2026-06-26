class_name BuildCatalog
extends Resource

@export var items: Array[BuildItemDefinition] = []
@export var synergies: Array[BuildSynergyDefinition] = []

var _items_by_id: Dictionary = {}


func _setup_local_to_scene() -> void:
	rebuild_index()


func rebuild_index() -> void:
	_items_by_id.clear()
	for item in items:
		if item == null or item.item_id == &"":
			continue
		_items_by_id[item.item_id] = item


func get_item(item_id: StringName) -> BuildItemDefinition:
	if _items_by_id.is_empty() and not items.is_empty():
		rebuild_index()
	return _items_by_id.get(item_id, null)


func has_item(item_id: StringName) -> bool:
	return get_item(item_id) != null


func get_items_by_pool_tag(pool_tag: StringName) -> Array[BuildItemDefinition]:
	var result: Array[BuildItemDefinition] = []
	for item in items:
		if item != null and item.pool_tags.has(pool_tag):
			result.append(item)
	return result
