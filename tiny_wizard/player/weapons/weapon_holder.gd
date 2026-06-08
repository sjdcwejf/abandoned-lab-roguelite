extends Node2D


@export var starting_weapon_scene: PackedScene
@export var owner_character_path: NodePath

var current_weapon: LabWeapon
var aim_direction := Vector2.RIGHT

@onready var owner_character := get_node_or_null(owner_character_path) as Node2D


func _ready() -> void:
	if starting_weapon_scene != null:
		equip_weapon(starting_weapon_scene)


func _process(_delta: float) -> void:
	if current_weapon == null:
		return
	if not Input.is_action_pressed("fire"):
		current_weapon.primary_released()
	if not Input.is_action_pressed("secondary_fire"):
		current_weapon.secondary_released()


func equip_weapon(weapon_scene: PackedScene) -> void:
	if current_weapon != null:
		current_weapon.unequip()
		current_weapon.queue_free()
		current_weapon = null

	var weapon := weapon_scene.instantiate()
	add_child(weapon)

	if weapon is LabWeapon:
		current_weapon = weapon
		current_weapon.equip(owner_character)
		current_weapon.set_aim_direction(aim_direction)
	else:
		push_error("%s is not a LabWeapon." % weapon_scene.resource_path)


func set_aim_direction(direction: Vector2) -> void:
	if direction.length() == 0:
		return
	aim_direction = direction.normalized()
	rotation = aim_direction.angle()
	if current_weapon != null:
		current_weapon.set_aim_direction(aim_direction)


func primary_fire() -> void:
	if current_weapon != null:
		current_weapon.primary_pressed()


func secondary_fire() -> void:
	if current_weapon != null:
		current_weapon.secondary_pressed()
