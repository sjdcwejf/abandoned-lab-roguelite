class_name LabProjectile
extends Area2D


@export var speed := 560.0
@export_range(1, 10, 1) var damage := 1
@export var lifetime := 1.25

var direction := Vector2.RIGHT
var owner_character: Node2D
var weapon_id: StringName


func _ready() -> void:
	collision_layer = 0
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func launch(new_direction: Vector2, new_owner: Node2D, new_damage := -1, new_speed := -1.0, new_collision_mask := -1, new_weapon_id: StringName = &"") -> void:
	if new_direction.length() > 0.0:
		direction = new_direction.normalized()
	owner_character = new_owner
	weapon_id = new_weapon_id
	if new_damage > 0:
		damage = new_damage
	if new_speed > 0.0:
		speed = new_speed
	if new_collision_mask >= 0:
		collision_mask = new_collision_mask


func _physics_process(delta: float) -> void:
	var start := global_position
	var end := start + direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(start, end)
	query.collision_mask = collision_mask
	if owner_character is CollisionObject2D:
		query.exclude = [(owner_character as CollisionObject2D).get_rid()]

	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.size() > 0:
		global_position = result["position"]
		_hit_collider(result["collider"])
		return

	global_position = end
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	_hit_collider(body)


func _hit_collider(target: Object) -> void:
	var damage_target := _find_damage_target(target)
	if damage_target != null:
		var hit_from := Vector2.ZERO
		if damage_target is Node2D:
			hit_from = ((damage_target as Node2D).global_position - global_position).normalized()
		var event := CombatEvent.new()
		event.attacker = owner_character
		event.target = damage_target
		event.source = self
		event.weapon_id = weapon_id
		event.damage_type = CombatEvent.DamageType.PHYSICAL
		event.base_amount = damage
		event.final_amount = damage
		event.hit_position = global_position
		event.tags = [&"projectile", &"weapon"]
		if CombatResolver.resolve_damage(event, hit_from):
			_notify_owner_weapon_hit(damage_target)
	queue_free()


func _notify_owner_weapon_hit(damage_target: Object) -> void:
	if owner_character == null:
		return
	var ability_controller := owner_character.get_node_or_null("AbilityController") as LabPlayerAbilityController
	if ability_controller == null:
		return
	ability_controller.notify_weapon_hit(damage_target, damage)


func _find_damage_target(target: Object) -> Object:
	if target == null or target == owner_character:
		return null
	if target.has_method("hit"):
		return target
	if not target is Node:
		return null

	var current := (target as Node).get_parent()
	while current != null:
		if current == owner_character:
			return null
		if current.has_method("hit"):
			return current
		current = current.get_parent()
	return null
