class_name BuildSynergyDefinition
extends Resource

enum SynergyScope {
	NEUTRAL,
	CHARACTER_EXCLUSIVE
}

@export var synergy_id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var enabled := true
@export_enum("NEUTRAL", "CHARACTER_EXCLUSIVE") var synergy_scope: int = SynergyScope.NEUTRAL
@export var owner_character_id: StringName
@export var exclusive_group: StringName
@export_range(1, 99, 1) var tier := 1
@export var priority := 0
@export_multiline var placeholder_text := ""
@export var required_tags: Array[BuildTagRequirement] = []
@export var required_tag_counts: Array[BuildTagRequirement] = []
@export var required_item_ids: Array[StringName] = []
@export var result_display_as_relic := true
@export var hide_required_items_in_ui := true
@export var stat_modifiers: Array[BuildStatModifier] = []
@export var event_effects: Array[BuildEventEffect] = []


func get_all_tag_requirements() -> Array[BuildTagRequirement]:
	var result: Array[BuildTagRequirement] = []
	result.append_array(required_tags)
	result.append_array(required_tag_counts)
	return result
