extends Node2D


@export var starting_weapon_scene: PackedScene
@export var weapon_scenes: Array[PackedScene] = []
@export var owner_character_path: NodePath

var current_weapon: LabWeapon
var current_weapon_index := -1
var aim_direction := Vector2.RIGHT

@onready var owner_character := get_node_or_null(owner_character_path) as Node2D


func _ready() -> void:
	if weapon_scenes.is_empty() and starting_weapon_scene != null:
		weapon_scenes.append(starting_weapon_scene)
	if starting_weapon_scene != null:
		equip_weapon(starting_weapon_scene)
	elif not weapon_scenes.is_empty():
		equip_weapon_by_index(0)


func _process(_delta: float) -> void:
	_handle_weapon_switch()

	if current_weapon == null:
		return
	if not Input.is_action_pressed("fire"):
		current_weapon.primary_released()
	if Input.is_action_pressed("secondary_fire"):
		current_weapon.secondary_pressed()
	else:
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
		current_weapon_index = weapon_scenes.find(weapon_scene)
		current_weapon.equip(owner_character)
		current_weapon.set_aim_direction(aim_direction)
	else:
		push_error("%s is not a LabWeapon." % weapon_scene.resource_path)
		weapon.queue_free()


func equip_weapon_by_index(index: int) -> void:
	if index < 0 or index >= weapon_scenes.size():
		return
	if current_weapon_index == index:
		return
	equip_weapon(weapon_scenes[index])


func add_weapon_scene(weapon_scene: PackedScene, equip_immediately := false) -> int:
	if weapon_scene == null:
		return -1

	var existing_index := _find_weapon_scene_index(weapon_scene)
	if existing_index >= 0:
		if equip_immediately:
			equip_weapon_by_index(existing_index)
		return existing_index

	weapon_scenes.append(weapon_scene)
	var new_index := weapon_scenes.size() - 1
	if equip_immediately:
		equip_weapon_by_index(new_index)
	return new_index


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


func _handle_weapon_switch() -> void:
	for index in range(weapon_scenes.size()):
		var action_name: String = "weapon_slot_%d" % (index + 1)
		if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
			equip_weapon_by_index(index)


func _find_weapon_scene_index(weapon_scene: PackedScene) -> int:
	var incoming_path := weapon_scene.resource_path
	for index in range(weapon_scenes.size()):
		var existing_scene := weapon_scenes[index]
		if existing_scene == weapon_scene:
			return index
		if existing_scene != null and incoming_path != "" and existing_scene.resource_path == incoming_path:
			return index
	return -1
