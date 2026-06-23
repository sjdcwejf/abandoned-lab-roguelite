class_name CombatEvent
extends RefCounted

enum EventType {
	HIT,
	DAMAGE_DEALT,
	KILL,
	ENEMY_DIED,
}

enum DamageType {
	PHYSICAL,
	ENERGY,
	BIOLOGICAL,
	TRUE,
}

var event_type: EventType = EventType.HIT
var attacker: Node
var target: Object
var source: Object
var weapon_id: StringName
var damage_type: DamageType = DamageType.PHYSICAL
var base_amount: float = 0.0
var final_amount: float = 0.0
var hit_position: Vector2 = Vector2.ZERO
var tags: Array[StringName] = []
var is_critical: bool = false
var is_lethal: bool = false
var room: Node


func copy_with_type(new_event_type: EventType) -> CombatEvent:
	var copy := CombatEvent.new()
	copy.event_type = new_event_type
	copy.attacker = attacker
	copy.target = target
	copy.source = source
	copy.weapon_id = weapon_id
	copy.damage_type = damage_type
	copy.base_amount = base_amount
	copy.final_amount = final_amount
	copy.hit_position = hit_position
	copy.tags = tags.duplicate()
	copy.is_critical = is_critical
	copy.is_lethal = is_lethal
	copy.room = room
	return copy
