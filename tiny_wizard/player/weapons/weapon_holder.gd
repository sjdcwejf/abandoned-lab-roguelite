extends Node2D


signal weapon_loadout_changed
signal weapon_equipped(slot_index: int)

const MAX_QUICK_SLOTS := 4

@export var starting_weapon_scene: PackedScene
@export var weapon_scenes: Array[PackedScene] = []
@export var owner_character_path: NodePath

var current_weapon: LabWeapon
var current_weapon_index := -1
var aim_direction := Vector2.RIGHT
var weapon_affixes: Array = []

@onready var owner_character := get_node_or_null(owner_character_path) as Node2D


func _ready() -> void:
	if weapon_scenes.is_empty() and starting_weapon_scene != null:
		weapon_scenes.append(starting_weapon_scene)
	_ensure_affix_slots()
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
		current_weapon.set_weapon_affixes(get_weapon_affixes_at_slot(current_weapon_index))
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
	return add_weapon_scene_with_affixes(weapon_scene, [], equip_immediately)


func add_weapon_scene_with_affixes(weapon_scene: PackedScene, affixes: Array, equip_immediately := false) -> int:
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
	elif weapon_scenes.size() < MAX_QUICK_SLOTS:
		weapon_scenes.append(weapon_scene)
		new_index = weapon_scenes.size() - 1
	else:
		return -1
	_set_weapon_affixes_at_slot(new_index, affixes)
	if equip_immediately:
		equip_weapon_by_index(new_index)
	else:
		weapon_loadout_changed.emit()
	return new_index


func add_weapon_scene_to_slot(weapon_scene: PackedScene, slot_index: int, equip_immediately := false) -> int:
	return add_weapon_scene_to_slot_with_affixes(weapon_scene, slot_index, [], equip_immediately)


func add_weapon_scene_to_slot_with_affixes(weapon_scene: PackedScene, slot_index: int, affixes: Array, equip_immediately := false) -> int:
	if weapon_scene == null or slot_index < 0 or slot_index >= MAX_QUICK_SLOTS:
		return -1

	var existing_index := find_weapon_scene_index(weapon_scene)
	if existing_index >= 0:
		if equip_immediately:
			equip_weapon_by_index(existing_index)
		return existing_index

	while weapon_scenes.size() <= slot_index:
		weapon_scenes.append(null)
		weapon_affixes.append([])

	weapon_scenes[slot_index] = weapon_scene
	_set_weapon_affixes_at_slot(slot_index, affixes)
	if equip_immediately:
		equip_weapon_by_index(slot_index)
	else:
		weapon_loadout_changed.emit()
	return slot_index


func replace_current_weapon_scene(weapon_scene: PackedScene) -> int:
	var target_index := current_weapon_index
	if target_index < 0 or target_index >= MAX_QUICK_SLOTS:
		target_index = 0
	return replace_weapon_scene_in_slot(weapon_scene, target_index)


func replace_weapon_scene_in_slot(weapon_scene: PackedScene, slot_index: int) -> int:
	return replace_weapon_scene_in_slot_with_affixes(weapon_scene, slot_index, [])


func replace_weapon_scene_in_slot_with_affixes(weapon_scene: PackedScene, slot_index: int, affixes: Array) -> int:
	if weapon_scene == null or slot_index < 0 or slot_index >= MAX_QUICK_SLOTS:
		return -1

	var existing_index := find_weapon_scene_index(weapon_scene)
	if existing_index >= 0:
		equip_weapon_by_index(existing_index)
		return existing_index

	while weapon_scenes.size() <= slot_index:
		weapon_scenes.append(null)
		weapon_affixes.append([])
	weapon_scenes[slot_index] = weapon_scene
	_set_weapon_affixes_at_slot(slot_index, affixes)
	current_weapon_index = -1
	equip_weapon_by_index(slot_index)
	return slot_index


func has_free_quick_slot() -> bool:
	return _find_empty_weapon_slot() >= 0 or weapon_scenes.size() < MAX_QUICK_SLOTS


func get_current_weapon_display_name() -> String:
	if current_weapon_index < 0 or current_weapon_index >= weapon_scenes.size():
		return "当前武器"
	return get_weapon_display_name_at_slot(current_weapon_index)


func get_weapon_display_name_at_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= weapon_scenes.size():
		return "当前武器"
	var weapon_scene := weapon_scenes[slot_index] as PackedScene
	if weapon_scene == null:
		return "当前武器"
	return str(_get_weapon_scene_inventory_info(weapon_scene, get_weapon_affixes_at_slot(slot_index)).get("name", "当前武器"))


func get_weapon_affixes_at_slot(slot_index: int) -> Array:
	if slot_index < 0:
		return []
	_ensure_affix_slots()
	if slot_index >= weapon_affixes.size():
		return []
	var slot_affixes := weapon_affixes[slot_index]
	if slot_affixes is Array:
		return (slot_affixes as Array).duplicate()
	return []


func set_weapon_loadout(new_weapon_scenes: Array, equip_index := 0) -> void:
	if current_weapon != null:
		current_weapon.unequip()
		current_weapon.queue_free()
		current_weapon = null

	weapon_scenes.clear()
	weapon_affixes.clear()
	for weapon_scene in new_weapon_scenes:
		if weapon_scene is PackedScene and weapon_scenes.size() < MAX_QUICK_SLOTS:
			weapon_scenes.append(weapon_scene)
			weapon_affixes.append([])

	current_weapon_index = -1
	starting_weapon_scene = weapon_scenes[0] if not weapon_scenes.is_empty() else null
	if not weapon_scenes.is_empty():
		equip_weapon_by_index(clampi(equip_index, 0, weapon_scenes.size() - 1))
	else:
		weapon_loadout_changed.emit()


func get_quick_weapon_slots(max_slots := MAX_QUICK_SLOTS) -> Array:
	var slots := []
	for index in range(mini(max_slots, MAX_QUICK_SLOTS)):
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
			slot_info.merge(_get_weapon_scene_inventory_info(weapon_scene, get_weapon_affixes_at_slot(index)), true)
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
	for index in range(mini(weapon_scenes.size(), MAX_QUICK_SLOTS)):
		if weapon_scenes[index] == null:
			continue
		var action_name: String = "weapon_slot_%d" % (index + 1)
		if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
			equip_weapon_by_index(index)


func _find_empty_weapon_slot() -> int:
	_ensure_affix_slots()
	for index in range(mini(weapon_scenes.size(), MAX_QUICK_SLOTS)):
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


func _get_weapon_scene_inventory_info(weapon_scene: PackedScene, affixes := []) -> Dictionary:
	var info := {
		"name": _fallback_weapon_name(weapon_scene),
		"size": Vector2i(2, 1),
		"color": Color(0.26, 0.62, 0.9, 1.0),
		"affixes": affixes.duplicate() if affixes is Array else [],
	}

	var weapon := weapon_scene.instantiate()
	if weapon is LabWeapon:
		(weapon as LabWeapon).set_weapon_affixes(info["affixes"])
		info.merge((weapon as LabWeapon).get_weapon_compare_info(), true)
	weapon.free()
	return info


func _ensure_affix_slots() -> void:
	while weapon_affixes.size() < weapon_scenes.size():
		weapon_affixes.append([])
	while weapon_affixes.size() > weapon_scenes.size():
		weapon_affixes.pop_back()


func _set_weapon_affixes_at_slot(slot_index: int, affixes: Array) -> void:
	_ensure_affix_slots()
	while weapon_affixes.size() <= slot_index:
		weapon_affixes.append([])
	weapon_affixes[slot_index] = affixes.duplicate()


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
		"res://tiny_wizard/player/weapons/quarantine_shotgun/quarantine_shotgun.tscn":
			return "检疫霰弹枪"

	var base_name := weapon_scene.resource_path.get_file().get_basename()
	if base_name != "":
		return "未命名武器：%s" % base_name
	return "未命名武器"
