class_name BuildEventEffect
extends Resource

enum Trigger {
	ON_INSTALL,
	ON_UNINSTALL,
	ON_ROOM_ENTERED,
	ON_DAMAGE_DEALT,
	ON_DAMAGE_TAKEN,
	ON_ENEMY_DEFEATED,
}

enum EffectType {
	DEAL_DAMAGE,
	HEAL,
	APPLY_STATUS,
	SPAWN_SCENE,
	MODIFY_RESOURCE,
}

enum Target {
	OWNER,
	SOURCE,
	EVENT_TARGET,
	NEAREST_ENEMY,
	ALL_ENEMIES,
}

@export var trigger: Trigger = Trigger.ON_DAMAGE_DEALT
@export var effect_type: EffectType = EffectType.DEAL_DAMAGE
@export var target: Target = Target.EVENT_TARGET
@export var magnitude: float = 0.0
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var duration: float = 0.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var cooldown: float = 0.0
@export_range(0.0, 4096.0, 1.0, "or_greater") var radius: float = 0.0
@export var event_tags: Array[StringName] = []
@export var status_id: StringName
@export var resource_id: StringName
@export var scene: PackedScene


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_finite(magnitude):
		errors.append("magnitude must be finite")
	if chance < 0.0 or chance > 1.0:
		errors.append("chance must be between 0 and 1")
	if duration < 0.0:
		errors.append("duration must not be negative")
	if cooldown < 0.0:
		errors.append("cooldown must not be negative")
	if effect_type == EffectType.APPLY_STATUS and status_id.is_empty():
		errors.append("status_id is required for APPLY_STATUS")
	if effect_type == EffectType.MODIFY_RESOURCE and resource_id.is_empty():
		errors.append("resource_id is required for MODIFY_RESOURCE")
	if effect_type == EffectType.SPAWN_SCENE and scene == null:
		errors.append("scene is required for SPAWN_SCENE")
	return errors
