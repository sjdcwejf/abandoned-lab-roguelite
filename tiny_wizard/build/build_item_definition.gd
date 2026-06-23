class_name BuildItemDefinition
extends Resource

enum ItemType {
	ORGAN,
	RELIC,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY,
}

enum OrganSlot {
	ANY = -1,
	HEART = 0,
	GLAND = 1,
	SKELETAL = 2,
	NEURAL = 3,
}

@export_category("Identity")
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D

@export_category("Classification")
@export var enabled: bool = true
@export var item_type: ItemType = ItemType.ORGAN
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []
@export var pool_tags: Array[StringName] = []

@export_category("Installation")
@export var organ_slot: OrganSlot = OrganSlot.ANY
@export_range(1, 999, 1, "or_greater") var slot_cost: int = 1
@export_range(1, 999, 1, "or_greater") var max_stacks: int = 1
@export var unique_group: StringName
@export var required_item_ids: Array[StringName] = []
@export var excluded_item_ids: Array[StringName] = []
@export var required_tags: Array[StringName] = []
@export var excluded_tags: Array[StringName] = []

@export_category("Static Effects")
@export var stat_modifiers: Array[BuildStatModifier] = []
@export var event_effects: Array[BuildEventEffect] = []


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("id must not be empty")
	if display_name.strip_edges().is_empty():
		errors.append("display_name must not be empty")
	if organ_slot < -1:
		errors.append("organ_slot must be -1 or greater")
	if item_type == ItemType.RELIC and organ_slot != -1:
		errors.append("organ_slot is only valid for organs")
	if slot_cost < 1:
		errors.append("slot_cost must be at least 1")
	if max_stacks < 1:
		errors.append("max_stacks must be at least 1")
	for modifier in stat_modifiers:
		if modifier == null or not modifier.is_valid():
			errors.append("stat_modifiers contains an invalid entry")
	for effect in event_effects:
		if effect == null or not effect.is_valid():
			errors.append("event_effects contains an invalid entry")
	return errors
