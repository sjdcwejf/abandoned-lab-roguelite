class_name LabWeapon
extends Node2D


var owner_character: Node2D
var aim_direction := Vector2.RIGHT


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
