class_name RelicCombatEventBus
extends RefCounted

const META_COMBAT_EVENT_TAGS := "lab_combat_event_tags"
const TAG_SECONDARY_EFFECT := &"secondary_effect"


static func notify_enemy_killed(enemy: Node) -> void:
	if enemy == null:
		return
	var tags := get_event_tags(enemy)
	if tags.has(TAG_SECONDARY_EFFECT):
		return
	var controller := RelicDropService.find_relic_controller(enemy.get_tree().current_scene)
	if controller != null:
		controller.handle_combat_event("enemy_killed", {
			"enemy": enemy,
			"global_position": enemy.global_position if enemy is Node2D else Vector2.ZERO,
			"tags": tags,
		})


static func notify_character_damaged(character: Node, amount: int, from: Vector2, tags: Array[StringName]) -> void:
	var controller := character.get_node_or_null("RelicController") as RelicController
	if controller == null:
		return
	controller.handle_combat_event("character_damaged", {
		"character": character,
		"amount": amount,
		"from": from,
		"tags": tags,
	})


static func notify_room_cleared(room: Room) -> void:
	if room == null:
		return
	var controller := RelicDropService.find_relic_controller(room.get_tree().current_scene)
	if controller != null:
		controller.handle_room_event("room_cleared", {
			"room": room,
			"global_position": room.get_room_global_position() + Room.ROOM_SIZE * 0.5,
		})


static func apply_secondary_damage(target: Object, amount: int, hit_from := Vector2.ZERO) -> bool:
	if target == null or amount <= 0 or not target.has_method("hit"):
		return false

	var previous_tags: Array[StringName] = get_event_tags(target)
	var next_tags: Array[StringName] = previous_tags.duplicate()
	if not next_tags.has(TAG_SECONDARY_EFFECT):
		next_tags.append(TAG_SECONDARY_EFFECT)
	target.set_meta(META_COMBAT_EVENT_TAGS, next_tags)
	target.call("hit", amount, hit_from)
	if previous_tags.is_empty():
		target.remove_meta(META_COMBAT_EVENT_TAGS)
	else:
		target.set_meta(META_COMBAT_EVENT_TAGS, previous_tags)
	return true


static func get_event_tags(target: Object) -> Array[StringName]:
	var result: Array[StringName] = []
	if target != null and target.has_meta(META_COMBAT_EVENT_TAGS):
		var raw_tags: Variant = target.get_meta(META_COMBAT_EVENT_TAGS)
		if raw_tags is Array:
			for tag in raw_tags:
				result.append(StringName(str(tag)))
	return result
