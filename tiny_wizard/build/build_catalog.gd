class_name BuildCatalog
extends Resource

@export var items: Array[BuildItemDefinition] = []
@export var synergies: Array[BuildSynergyDefinition] = []


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var known_ids: Dictionary[StringName, bool] = {}
	for item in items:
		if item == null or not item.is_valid():
			errors.append("items contains an invalid entry")
			continue
		if known_ids.has(item.id):
			errors.append("duplicate build id: %s" % item.id)
		known_ids[item.id] = true
	for synergy in synergies:
		if synergy == null or not synergy.is_valid():
			errors.append("synergies contains an invalid entry")
			continue
		if known_ids.has(synergy.id):
			errors.append("duplicate build id: %s" % synergy.id)
		known_ids[synergy.id] = true
	return errors


func find_item(item_id: StringName) -> BuildItemDefinition:
	for item in items:
		if item != null and item.id == item_id:
			return item
	return null


func find_synergy(synergy_id: StringName) -> BuildSynergyDefinition:
	for synergy in synergies:
		if synergy != null and synergy.id == synergy_id:
			return synergy
	return null
