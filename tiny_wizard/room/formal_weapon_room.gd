extends Room


const WEAPON_PICKUP_SCENE := preload("res://tiny_wizard/interactable_objects/weapon_pickup/weapon_pickup.tscn")
const WEAPON_CATALOG := preload("res://tiny_wizard/player/weapons/weapon_catalog.gd")
const WEAPON_AFFIX_SERVICE := preload("res://tiny_wizard/player/weapons/weapon_affix_service.gd")

@export_range(1, 3, 1) var weapon_option_count := 1
@export_range(0.0, 1.0, 0.05) var affix_roll_chance := 0.0
@export_range(0, 2, 1) var max_affix_count := 1
@export var allow_equipment_refresh := false

var _weapon_holder: Node
var _weapon_spawned := false
var _refresh_used := false
var _refresh_area: Area2D
var _refresh_prompt: Label
var _refresh_candidate: Node2D


func set_weapon_holder(weapon_holder: Node) -> void:
	_weapon_holder = weapon_holder


func enter_room() -> void:
	super.enter_room()
	if not _weapon_spawned:
		_weapon_spawned = true
		call_deferred("_spawn_random_weapon")


func _ready() -> void:
	super._ready()
	if allow_equipment_refresh:
		_create_refresh_terminal()


func _process(_delta: float) -> void:
	if not allow_equipment_refresh or _refresh_candidate == null or _refresh_used:
		return
	if Input.is_action_just_pressed("interact"):
		_refresh_used = true
		_clear_spawned_pickups()
		_spawn_random_weapon()
		_update_refresh_prompt()


func _spawn_random_weapon() -> void:
	var weapon_pool := WEAPON_CATALOG.get_weapon_pool_for_context(self)
	if weapon_pool.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var weapon_scenes := _pick_unowned_weapon_scenes(rng, weapon_pool, weapon_option_count)
	if weapon_scenes.is_empty():
		print("Weapon room has no unowned weapon to drop.")
		return

	var target_positions: Array = _get_option_positions(weapon_scenes.size())
	var room_position: Vector2 = get_room_global_position()
	for index in range(weapon_scenes.size()):
		var weapon_scene := weapon_scenes[index] as PackedScene
		var weapon_pickup := WEAPON_PICKUP_SCENE.instantiate() as LabWeaponPickup
		if weapon_pickup == null:
			continue

		var affixes := WEAPON_AFFIX_SERVICE.roll_affixes(rng, affix_roll_chance, max_affix_count)
		var base_label := _get_weapon_label(weapon_scene)
		var target_offset: Vector2 = target_positions[index] as Vector2
		var target_position: Vector2 = room_position + target_offset
		var start_position: Vector2 = target_position + Vector2(0, -76)
		weapon_pickup.weapon_scene = weapon_scene
		weapon_pickup.weapon_label = base_label
		weapon_pickup.weapon_affixes = affixes
		weapon_pickup.equip_on_pickup = false
		weapon_pickup.preview_rotation = -0.22
		add_child(weapon_pickup)
		weapon_pickup.play_drop_animation(start_position, target_position)


func _pick_unowned_weapon_scenes(rng: RandomNumberGenerator, weapon_pool: Array[PackedScene], count: int) -> Array[PackedScene]:
	var candidates := []
	var owned_weapon_keys := _get_owned_weapon_keys()
	var weapon_holder := _get_active_weapon_holder()
	for weapon_scene in weapon_pool:
		var packed_scene := weapon_scene as PackedScene
		if packed_scene == null:
			continue
		if owned_weapon_keys.has(_weapon_scene_key(packed_scene)):
			continue
		if weapon_holder != null and weapon_holder.has_method("has_weapon_scene") and bool(weapon_holder.call("has_weapon_scene", packed_scene)):
			continue
		candidates.append(packed_scene)

	if candidates.is_empty():
		return []
	_shuffle_array(candidates, rng)
	var selected := []
	for index in range(mini(count, candidates.size())):
		selected.append(candidates[index])
	print("Raven Armory Cache dropped %d weapon option(s) from %d unowned candidates." % [selected.size(), candidates.size()])
	return selected


func _get_owned_weapon_keys() -> Dictionary:
	var owned := {}
	var weapon_holder := _get_active_weapon_holder()
	if weapon_holder == null:
		return owned

	if weapon_holder.has_method("get_owned_weapon_scene_keys"):
		return weapon_holder.call("get_owned_weapon_scene_keys") as Dictionary

	var weapon_scenes := weapon_holder.get("weapon_scenes") as Array
	if weapon_scenes == null:
		return owned

	for weapon_scene in weapon_scenes:
		if weapon_scene is PackedScene:
			owned[_weapon_scene_key(weapon_scene as PackedScene)] = true
	return owned


func _get_active_weapon_holder() -> Node:
	if _weapon_holder != null and is_instance_valid(_weapon_holder):
		return _weapon_holder

	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null

	_weapon_holder = _find_weapon_holder(tree.current_scene)
	return _weapon_holder


func _find_weapon_holder(root: Node) -> Node:
	if root.name == "WeaponHolder" and root.has_method("add_weapon_scene"):
		return root

	for child in root.get_children():
		var found := _find_weapon_holder(child)
		if found != null:
			return found
	return null


func _weapon_scene_key(weapon_scene: PackedScene) -> String:
	return WEAPON_CATALOG.get_weapon_key(weapon_scene, _get_active_weapon_holder())


func _get_weapon_label(weapon_scene: PackedScene) -> String:
	return WEAPON_CATALOG.get_weapon_display_name(weapon_scene)


func _get_option_positions(count: int) -> Array:
	match count:
		1:
			return [Vector2(512, 322)]
		2:
			return [Vector2(450, 322), Vector2(574, 322)]
	return [Vector2(392, 322), Vector2(512, 322), Vector2(632, 322)]


func _clear_spawned_pickups() -> void:
	for child in get_children():
		if child is LabWeaponPickup:
			child.queue_free()


func _create_refresh_terminal() -> void:
	_refresh_area = Area2D.new()
	_refresh_area.name = "EquipmentRefreshArea"
	_refresh_area.position = Vector2(512, 246)
	_refresh_area.collision_layer = 0
	_refresh_area.collision_mask = 2
	add_child(_refresh_area)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 42.0
	shape.shape = circle
	_refresh_area.add_child(shape)

	_refresh_prompt = Label.new()
	_refresh_prompt.name = "EquipmentRefreshPrompt"
	_refresh_prompt.position = Vector2(-76, -62)
	_refresh_prompt.size = Vector2(152, 28)
	_refresh_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refresh_prompt.add_theme_font_size_override("font_size", 12)
	_refresh_prompt.add_theme_color_override("font_color", Color(0.68, 1.0, 0.96, 1.0))
	_refresh_prompt.visible = false
	_refresh_area.add_child(_refresh_prompt)
	_update_refresh_prompt()

	_refresh_area.body_entered.connect(_on_refresh_area_body_entered)
	_refresh_area.body_exited.connect(_on_refresh_area_body_exited)


func _update_refresh_prompt() -> void:
	if _refresh_prompt == null:
		return
	_refresh_prompt.text = "已刷新" if _refresh_used else "按 F 刷新装备"


func _on_refresh_area_body_entered(body: Node2D) -> void:
	if not body.has_node("Visual/WeaponHolder"):
		return
	_refresh_candidate = body
	if _refresh_prompt != null:
		_update_refresh_prompt()
		_refresh_prompt.visible = true


func _on_refresh_area_body_exited(body: Node2D) -> void:
	if body != _refresh_candidate:
		return
	_refresh_candidate = null
	if _refresh_prompt != null:
		_refresh_prompt.visible = false


func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
