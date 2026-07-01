class_name BuildItemDefinition
extends Resource

enum ItemType {
	ORGAN,
	RELIC
}

enum RelicScope {
	NONE,
	NEUTRAL,
	CHARACTER_EXCLUSIVE
}

@export var item_id: StringName
@export var display_name := ""
@export var enabled := true
@export_enum("ORGAN", "RELIC") var item_type: int = ItemType.RELIC
@export_enum("NONE", "NEUTRAL", "CHARACTER_EXCLUSIVE") var relic_scope: int = RelicScope.NONE
@export var owner_character_id: StringName
@export_multiline var placeholder_text := ""
@export var icon: Texture2D
@export var pool_tags: Array[StringName] = []
@export var tags: Array[StringName] = []
@export var required_item_ids: Array[StringName] = []
@export var excluded_item_ids: Array[StringName] = []
@export var unique_group: StringName
@export_range(1, 999, 1) var max_stacks := 1
@export_range(0, 999, 1) var base_price := 20
@export var stat_modifiers: Array[BuildStatModifier] = []
@export var event_effects: Array[BuildEventEffect] = []


func get_id() -> StringName:
	return item_id
