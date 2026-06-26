class_name BuildInstallResult
extends Resource

enum Reason {
	OK,
	NULL_DEFINITION,
	DISABLED,
	WRONG_ITEM_TYPE,
	WRONG_RELIC_SCOPE,
	MAX_STACKS_REACHED,
	UNIQUE_GROUP_BLOCKED,
	REQUIRED_ITEM_MISSING,
	EXCLUDED_ITEM_OWNED,
	CHARACTER_SCOPE_MISMATCH,
	UNKNOWN
}

@export var success := false
@export_enum("OK", "NULL_DEFINITION", "DISABLED", "WRONG_ITEM_TYPE", "WRONG_RELIC_SCOPE", "MAX_STACKS_REACHED", "UNIQUE_GROUP_BLOCKED", "REQUIRED_ITEM_MISSING", "EXCLUDED_ITEM_OWNED", "CHARACTER_SCOPE_MISMATCH", "UNKNOWN") var reason: int = Reason.UNKNOWN
@export var message := ""


static func ok(message_text := "") -> BuildInstallResult:
	var result := BuildInstallResult.new()
	result.success = true
	result.reason = Reason.OK
	result.message = message_text
	return result


static func fail(reason_value: Reason, message_text := "") -> BuildInstallResult:
	var result := BuildInstallResult.new()
	result.success = false
	result.reason = reason_value
	result.message = message_text
	return result
