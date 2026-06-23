class_name BuildTagRequirement
extends Resource

enum Comparison {
	AT_LEAST,
	AT_MOST,
	EXACTLY,
}

@export var tag: StringName
@export var comparison: Comparison = Comparison.AT_LEAST
@export_range(0, 999, 1, "or_greater") var count: int = 1


func is_valid() -> bool:
	return not tag.is_empty() and count >= 0


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if tag.is_empty():
		errors.append("tag must not be empty")
	if count < 0:
		errors.append("count must not be negative")
	return errors


func is_satisfied_by(tag_count: int) -> bool:
	match comparison:
		Comparison.AT_LEAST:
			return tag_count >= count
		Comparison.AT_MOST:
			return tag_count <= count
		Comparison.EXACTLY:
			return tag_count == count
	return false
