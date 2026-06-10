class_name LabWeapon
extends Node2D


@export var display_name := ""
@export var inventory_size := Vector2i(2, 1)
@export var inventory_color := Color(0.26, 0.62, 0.9, 1.0)

var owner_character: Node2D
var aim_direction := Vector2.RIGHT


func get_inventory_display_name() -> String:
	if display_name != "":
		return display_name
	if name != "":
		return name
	return "Weapon"


func get_inventory_size() -> Vector2i:
	return Vector2i(maxi(1, inventory_size.x), maxi(1, inventory_size.y))


func get_inventory_color() -> Color:
	return inventory_color


func equip(new_owner: Node2D) -> void:
	owner_character = new_owner


func unequip() -> void:
	primary_released()
	secondary_released()
	owner_character = null


func set_aim_direction(direction: Vector2) -> void:
	if direction.length() == 0:
		return
	aim_direction = direction.normalized()


func primary_pressed() -> void:
	pass


func primary_released() -> void:
	pass


func secondary_pressed() -> void:
	pass


func secondary_released() -> void:
	pass


func get_fire_origin() -> Vector2:
	var muzzle := get_node_or_null("Muzzle") as Node2D
	if muzzle != null:
		return muzzle.global_position
	if owner_character != null:
		return owner_character.global_position + aim_direction * 22.0
	return global_position


func get_spawn_parent() -> Node:
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	if owner_character != null and owner_character.get_parent() != null:
		return owner_character.get_parent()
	return get_parent()


func find_damage_target(target: Object) -> Object:
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


func apply_damage_to_target(target: Object, amount: int, hit_from := Vector2.ZERO, hit_origin := Vector2.ZERO) -> bool:
	var damage_target := find_damage_target(target)
	if damage_target == null:
		return false

	var final_hit_from := hit_from
	if final_hit_from == Vector2.ZERO and hit_origin != Vector2.ZERO and damage_target is Node2D:
		final_hit_from = ((damage_target as Node2D).global_position - hit_origin).normalized()

	damage_target.hit(amount, final_hit_from)
	return true
