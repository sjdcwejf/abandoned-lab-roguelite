extends Room


const WEAPON_PICKUP_SCENE := preload("res://tiny_wizard/interactable_objects/weapon_pickup/weapon_pickup.tscn")
const WEAPON_POOL := [
	preload("res://tiny_wizard/player/weapons/laser_pointer/laser_pointer.tscn"),
	preload("res://tiny_wizard/player/weapons/containment_nailgun/containment_nailgun.tscn"),
	preload("res://tiny_wizard/player/weapons/energy_saber/energy_saber.tscn"),
	preload("res://tiny_wizard/player/weapons/power_gauntlets/power_gauntlets.tscn"),
	preload("res://tiny_wizard/player/weapons/test_sword/test_sword.tscn"),
]

var _weapon_holder: Node
var _weapon_spawned := false


func set_weapon_holder(weapon_holder: Node) -> void:
	_weapon_holder = weapon_holder


func enter_room() -> void:
	super.enter_room()
	if not _weapon_spawned:
		_weapon_spawned = true
		call_deferred("_spawn_random_weapon")


func _spawn_random_weapon() -> void:
	if WEAPON_POOL.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var weapon_scene := _pick_unowned_weapon_scene(rng)
	if weapon_scene == null:
		print("Weapon room has no unowned weapon to drop.")
		return

	var weapon_pickup := WEAPON_PICKUP_SCENE.instantiate() as LabWeaponPickup
	if weapon_pickup == null:
		return

	var target_position := get_room_global_position() + Vector2(512, 322)
	var start_position := target_position + Vector2(0, -76)
	weapon_pickup.weapon_scene = weapon_scene
	weapon_pickup.weapon_label = _get_weapon_label(weapon_scene)
	weapon_pickup.equip_on_pickup = false
	weapon_pickup.preview_rotation = -0.22
	add_child(weapon_pickup)
	weapon_pickup.play_drop_animation(start_position, target_position)


func _pick_unowned_weapon_scene(rng: RandomNumberGenerator) -> PackedScene:
	var candidates := []
	var owned_weapon_paths := _get_owned_weapon_paths()
	for weapon_scene in WEAPON_POOL:
		var packed_scene := weapon_scene as PackedScene
		if packed_scene == null:
			continue
		if owned_weapon_paths.has(_weapon_scene_key(packed_scene)):
			continue
		candidates.append(packed_scene)

	if candidates.is_empty():
		return null
	return candidates[rng.randi_range(0, candidates.size() - 1)] as PackedScene


func _get_owned_weapon_paths() -> Dictionary:
	var owned := {}
	if _weapon_holder == null or not is_instance_valid(_weapon_holder):
		return owned

	var weapon_scenes := _weapon_holder.get("weapon_scenes") as Array
	if weapon_scenes == null:
		return owned

	for weapon_scene in weapon_scenes:
		if weapon_scene is PackedScene:
			owned[_weapon_scene_key(weapon_scene as PackedScene)] = true
	return owned


func _weapon_scene_key(weapon_scene: PackedScene) -> String:
	if weapon_scene == null:
		return ""
	if weapon_scene.resource_path != "":
		return weapon_scene.resource_path
	return str(weapon_scene.get_instance_id())


func _get_weapon_label(weapon_scene: PackedScene) -> String:
	if weapon_scene == null:
		return "Weapon"

	var weapon := weapon_scene.instantiate()
	if weapon == null:
		return "Weapon"
	if weapon is LabWeapon:
		var label := (weapon as LabWeapon).get_inventory_display_name()
		weapon.free()
		return label

	weapon.free()
	return weapon_scene.resource_path.get_file().get_basename().replace("_", " ").capitalize()
