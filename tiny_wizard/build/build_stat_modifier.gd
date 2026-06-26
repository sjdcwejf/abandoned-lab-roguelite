class_name BuildStatModifier
extends Resource

enum Operation {
	ADD,
	MULTIPLY,
	SET
}

@export var stat_id: StringName
@export_enum("ADD", "MULTIPLY", "SET") var operation: int = Operation.ADD
@export var value := 0.0
