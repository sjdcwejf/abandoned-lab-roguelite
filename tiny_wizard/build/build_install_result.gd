class_name BuildInstallResult
extends Resource

enum Status {
	SUCCESS,
	INVALID_ITEM,
	DUPLICATE_ITEM,
	NO_CAPACITY,
	INCOMPATIBLE,
	ITEM_DISABLED,
	INVALID_ITEM_TYPE,
	INVALID_SLOT,
	MAX_STACKS,
	UNIQUE_CONFLICT,
	MISSING_REQUIREMENT,
	EXCLUDED_CONFLICT,
}

@export var status: Status = Status.SUCCESS
@export var item: BuildItemDefinition
@export var message: String
@export var slot_index: int = -1
@export var stack_count: int = 0


func is_success() -> bool:
	return status == Status.SUCCESS


func is_valid() -> bool:
	return item != null and (status != Status.SUCCESS or item.is_valid())
