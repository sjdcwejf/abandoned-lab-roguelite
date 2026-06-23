class_name CombatResolver
extends Node

signal event_emitted(event: CombatEvent)
signal hit(event: CombatEvent)
signal damage_dealt(event: CombatEvent)
signal enemy_died(event: CombatEvent)

static var _instance: CombatResolver


func _enter_tree() -> void:
	_instance = self


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


static func get_instance() -> CombatResolver:
	return _instance


static func resolve_damage(event: CombatEvent, hit_from: Vector2 = Vector2.ZERO) -> bool:
	if _instance != null and is_instance_valid(_instance):
		return _instance._resolve_damage(event, hit_from)
	return _apply_legacy_damage(event, hit_from)


func _resolve_damage(event: CombatEvent, hit_from: Vector2) -> bool:
	if not _can_damage(event):
		return false
	event.room = _find_room(event.target)
	event.final_amount = event.base_amount
	_emit_event(event.copy_with_type(CombatEvent.EventType.HIT))

	var life_before := _get_current_life(event.target)
	event.target.call("hit", event.base_amount, hit_from)
	var life_after := _get_current_life(event.target)
	if life_before >= 0.0 and life_after >= 0.0:
		event.final_amount = maxf(0.0, life_before - life_after)
		event.is_lethal = life_before > 0.0 and life_after <= 0.0
	else:
		event.final_amount = event.base_amount
		event.is_lethal = false
	_emit_event(event.copy_with_type(CombatEvent.EventType.DAMAGE_DEALT))
	if event.is_lethal:
		_emit_event(event.copy_with_type(CombatEvent.EventType.KILL))
	return true


static func _apply_legacy_damage(event: CombatEvent, hit_from: Vector2) -> bool:
	if event == null or event.target == null or not event.target.has_method("hit"):
		return false
	event.target.call("hit", event.base_amount, hit_from)
	return true


func _can_damage(event: CombatEvent) -> bool:
	return event != null and event.target != null and event.target.has_method("hit")


func _emit_event(event: CombatEvent) -> void:
	event_emitted.emit(event)
	match event.event_type:
		CombatEvent.EventType.HIT:
			hit.emit(event)
		CombatEvent.EventType.DAMAGE_DEALT:
			damage_dealt.emit(event)
		CombatEvent.EventType.KILL, CombatEvent.EventType.ENEMY_DIED:
			enemy_died.emit(event)


func _get_current_life(target: Object) -> float:
	if not target is Node:
		return -1.0
	var stats: Variant = (target as Node).get("character_stats")
	if stats == null:
		return -1.0
	var life: Variant = stats.get("current_life")
	return float(life) if life != null else -1.0


func _find_room(target: Object) -> Node:
	if not target is Node:
		return null
	var current := target as Node
	while current != null:
		if current is Room:
			return current
		current = current.get_parent()
	return null
