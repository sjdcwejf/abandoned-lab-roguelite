class_name BuildSynergyDefinition
extends Resource

@export_category("Identity")
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D

@export_category("Activation Requirements")
@export var tag_requirements: Array[BuildTagRequirement] = []

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
	if tag_requirements.is_empty():
		errors.append("at least one tag requirement is required")
	for requirement in tag_requirements:
		if requirement == null or not requirement.is_valid():
			errors.append("tag_requirements contains an invalid entry")
	for modifier in stat_modifiers:
		if modifier == null or not modifier.is_valid():
			errors.append("stat_modifiers contains an invalid entry")
	for effect in event_effects:
		if effect == null or not effect.is_valid():
			errors.append("event_effects contains an invalid entry")
	return errors
