class_name LabWeaponCatalog
extends RefCounted


const DEFAULT_CHAPTER_ID := 1

const LASER_POINTER := preload("res://tiny_wizard/player/weapons/laser_pointer/laser_pointer.tscn")
const CONTAINMENT_NAILGUN := preload("res://tiny_wizard/player/weapons/containment_nailgun/containment_nailgun.tscn")
const ENERGY_SABER := preload("res://tiny_wizard/player/weapons/energy_saber/energy_saber.tscn")
const POWER_GAUNTLETS := preload("res://tiny_wizard/player/weapons/power_gauntlets/power_gauntlets.tscn")
const TEST_SWORD := preload("res://tiny_wizard/player/weapons/test_sword/test_sword.tscn")
const QUARANTINE_SHOTGUN := preload("res://tiny_wizard/player/weapons/quarantine_shotgun/quarantine_shotgun.tscn")
const BREACH_CHAINSAW := preload("res://tiny_wizard/player/weapons/breach_chainsaw/breach_chainsaw.tscn")

const CHAPTER_WEAPON_POOLS := {
	1: [
		LASER_POINTER,
		CONTAINMENT_NAILGUN,
		ENERGY_SABER,
		POWER_GAUNTLETS,
		TEST_SWORD,
		QUARANTINE_SHOTGUN,
		BREACH_CHAINSAW,
	],
	4: [
		CONTAINMENT_NAILGUN,
		QUARANTINE_SHOTGUN,
		POWER_GAUNTLETS,
		BREACH_CHAINSAW,
		LASER_POINTER,
		ENERGY_SABER,
		TEST_SWORD,
	],
}


static func get_chapter_weapon_pool(chapter_id := DEFAULT_CHAPTER_ID) -> Array[PackedScene]:
	var pool := CHAPTER_WEAPON_POOLS.get(chapter_id, CHAPTER_WEAPON_POOLS[DEFAULT_CHAPTER_ID]) as Array
	var result: Array[PackedScene] = []
	for weapon_scene in pool:
		if weapon_scene is PackedScene:
			result.append(weapon_scene)
	return result


static func get_weapon_pool_for_context(context: Node) -> Array[PackedScene]:
	return get_chapter_weapon_pool(get_chapter_id_for_context(context))


static func get_chapter_id_for_context(context: Node) -> int:
	var room := find_owning_room(context)
	if room != null and room.has_meta("chapter_id"):
		return int(room.get_meta("chapter_id"))
	return DEFAULT_CHAPTER_ID


static func find_owning_room(context: Node) -> Node:
	var current := context
	while current != null:
		if current.has_meta("chapter_id") or current.has_meta("room_type"):
			return current
		current = current.get_parent()
	return null


static func get_weapon_key(weapon_scene: PackedScene, weapon_holder: Node = null) -> String:
	if weapon_scene == null:
		return ""
	if weapon_holder != null and weapon_holder.has_method("get_weapon_scene_key"):
		return str(weapon_holder.call("get_weapon_scene_key", weapon_scene))

	var weapon := weapon_scene.instantiate()
	if weapon is LabWeapon:
		var weapon_id := (weapon as LabWeapon).get_weapon_id()
		weapon.free()
		if weapon_id != "":
			return weapon_id
	elif weapon != null:
		weapon.free()

	if weapon_scene.resource_path != "":
		return weapon_scene.resource_path
	return str(weapon_scene.get_instance_id())


static func get_weapon_display_name(weapon_scene: PackedScene) -> String:
	if weapon_scene == null:
		return "未知武器"

	var weapon := weapon_scene.instantiate()
	if weapon is LabWeapon:
		var label := (weapon as LabWeapon).get_inventory_display_name()
		weapon.free()
		if label != "":
			return label
	elif weapon != null:
		weapon.free()

	var base_name := weapon_scene.resource_path.get_file().get_basename()
	if base_name != "":
		return "未命名武器：%s" % base_name
	return "未命名武器"
