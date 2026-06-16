extends Node2D


signal weapon_loadout_changed
signal weapon_equipped(slot_index: int)

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
	if weapon_scene == null:
		return

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
		weapon_equipped.emit(current_weapon_index)
		weapon_loadout_changed.emit()
	else:
		push_error("%s is not a LabWeapon." % weapon_scene.resource_path)
		weapon.queue_free()


func equip_weapon_by_index(index: int) -> void:
	if index < 0 or index >= weapon_scenes.size():
		return
	if weapon_scenes[index] == null:
		return
	if current_weapon_index == index:
		return
	equip_weapon(weapon_scenes[index])


func add_weapon_scene(weapon_scene: PackedScene, equip_immediately := false) -> int:
	if weapon_scene == null:
		return -1

	var existing_index := find_weapon_scene_index(weapon_scene)
	if existing_index >= 0:
		if equip_immediately:
			equip_weapon_by_index(existing_index)
		return existing_index

	var new_index := _find_empty_weapon_slot()
	if new_index >= 0:
		weapon_scenes[new_index] = weapon_scene
	else:
		weapon_scenes.append(weapon_scene)
		new_index = weapon_scenes.size() - 1
	if equip_immediately:
		equip_weapon_by_index(new_index)
	else:
		weapon_loadout_changed.emit()
	return new_index


func add_weapon_scene_to_slot(weapon_scene: PackedScene, slot_index: int, equip_immediately := false) -> int:
	if weapon_scene == null or slot_index < 0:
		return -1

	var existing_index := find_weapon_scene_index(weapon_scene)
	if existing_index >= 0:
		if equip_immediately:
			equip_weapon_by_index(existing_index)
		return existing_index

	while weapon_scenes.size() <= slot_index:
		weapon_scenes.append(null)

	weapon_scenes[slot_index] = weapon_scene
	if equip_immediately:
		equip_weapon_by_index(slot_index)
	else:
		weapon_loadout_changed.emit()
	return slot_index


func set_weapon_loadout(new_weapon_scenes: Array, equip_index := 0) -> void:
	if current_weapon != null:
		current_weapon.unequip()
		current_weapon.queue_free()
		current_weapon = null

	weapon_scenes.clear()
	for weapon_scene in new_weapon_scenes:
		if weapon_scene is PackedScene:
			weapon_scenes.append(weapon_scene)

	current_weapon_index = -1
	starting_weapon_scene = weapon_scenes[0] if not weapon_scenes.is_empty() else null
	if not weapon_scenes.is_empty():
		equip_weapon_by_index(clampi(equip_index, 0, weapon_scenes.size() - 1))
	else:
		weapon_loadout_changed.emit()


func get_quick_weapon_slots(max_slots := 4) -> Array:
	var slots := []
	for index in range(max_slots):
		var weapon_scene: PackedScene = null
		if index < weapon_scenes.size():
			weapon_scene = weapon_scenes[index]

		var slot_info := {
			"slot": index + 1,
			"scene": weapon_scene,
			"equipped": index == current_weapon_index,
			"name": "Empty",
			"size": Vector2i(1, 1),
			"color": Color(0.18, 0.2, 0.23, 1.0),
		}

		if weapon_scene != null:
			slot_info.merge(_get_weapon_scene_inventory_info(weapon_scene), true)
		slots.append(slot_info)
	return slots


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


func has_weapon_scene(weapon_scene: PackedScene) -> bool:
	return find_weapon_scene_index(weapon_scene) >= 0


func find_weapon_scene_index(weapon_scene: PackedScene) -> int:
	var incoming_key := get_weapon_scene_key(weapon_scene)
	for index in range(weapon_scenes.size()):
		var existing_scene := weapon_scenes[index]
		if existing_scene == weapon_scene:
			return index
		if existing_scene != null and incoming_key != "" and get_weapon_scene_key(existing_scene) == incoming_key:
			return index
	return -1


func get_owned_weapon_scene_keys() -> Dictionary:
	var owned := {}
	for weapon_scene in weapon_scenes:
		_add_owned_weapon_scene_key(owned, weapon_scene)
	_add_owned_weapon_scene_key(owned, starting_weapon_scene)
	return owned


func get_weapon_scene_key(weapon_scene: PackedScene) -> String:
	if weapon_scene == null:
		return ""
	var weapon_id := _get_weapon_scene_weapon_id(weapon_scene)
	if weapon_id != "":
		return weapon_id
	if weapon_scene.resource_path != "":
		return weapon_scene.resource_path
	return str(weapon_scene.get_instance_id())


func _handle_weapon_switch() -> void:
	for index in range(weapon_scenes.size()):
		if weapon_scenes[index] == null:
			continue
		var action_name: String = "weapon_slot_%d" % (index + 1)
		if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
			equip_weapon_by_index(index)


func _find_empty_weapon_slot() -> int:
	for index in range(weapon_scenes.size()):
		if weapon_scenes[index] == null:
			return index
	return -1


func _add_owned_weapon_scene_key(owned: Dictionary, weapon_scene) -> void:
	if not weapon_scene is PackedScene:
		return

	var key := get_weapon_scene_key(weapon_scene as PackedScene)
	if key == "":
		return
	owned[key] = true


func _get_weapon_scene_weapon_id(weapon_scene: PackedScene) -> String:
	var weapon := weapon_scene.instantiate()
	if weapon == null:
		return ""

	var key := ""
	if weapon is LabWeapon:
		key = (weapon as LabWeapon).get_weapon_id()
	weapon.free()
	return key


func _get_weapon_scene_inventory_info(weapon_scene: PackedScene) -> Dictionary:
	var info := {
		"name": _fallback_weapon_name(weapon_scene),
		"size": Vector2i(2, 1),
		"color": Color(0.26, 0.62, 0.9, 1.0),
	}

	var weapon := weapon_scene.instantiate()
	if weapon is LabWeapon:
		info["name"] = weapon.get_inventory_display_name()
		info["size"] = weapon.get_inventory_size()
		info["color"] = weapon.get_inventory_color()
	weapon.free()
	return info


func _fallback_weapon_name(weapon_scene: PackedScene) -> String:
	if weapon_scene == null or weapon_scene.resource_path == "":
		return "武器"

	match weapon_scene.resource_path:
		"res://tiny_wizard/player/weapons/laser_pointer/laser_pointer.tscn":
			return "校准激光笔"
		"res://tiny_wizard/player/weapons/containment_nailgun/containment_nailgun.tscn":
			return "封控钉枪"
		"res://tiny_wizard/player/weapons/energy_saber/energy_saber.tscn":
			return "能量光剑"
		"res://tiny_wizard/player/weapons/power_gauntlets/power_gauntlets.tscn":
			return "动力拳套"
		"res://tiny_wizard/player/weapons/test_sword/test_sword.tscn":
			return "检疫刃"

	var base_name := weapon_scene.resource_path.get_file().get_basename()
	if base_name != "":
		return "未命名武器：%s" % base_name
	return "未命名武器"
