class_name BuildStatModifier
extends Resource

enum Operation {
	ADD,
	MULTIPLY,
	OVERRIDE,
}

@export var stat_id: StringName
@export var operation: Operation = Operation.ADD
@export var value: float = 0.0
@export var priority: int = 0


func is_valid() -> bool:
	return not stat_id.is_empty() and is_finite(value)


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if stat_id.is_empty():
		errors.append("stat_id must not be empty")
	if not is_finite(value):
		errors.append("value must be finite")
	return errors
