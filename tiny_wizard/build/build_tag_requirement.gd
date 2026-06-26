class_name BuildTagRequirement
extends Resource

@export var tag: StringName
@export var min_count := 1
@export var max_count := -1


func is_met(tag_count: int) -> bool:
	if tag_count < min_count:
		return false
	if max_count >= 0 and tag_count > max_count:
		return false
	return true
