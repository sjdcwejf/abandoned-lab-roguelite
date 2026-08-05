extends "res://tiny_wizard/enemies/fusion_boss/fusion_boss.gd"


signal module_state_changed(part_id: StringName, installed: bool)

const RIVET_SCENE := preload("res://tiny_wizard/enemies/r0_reverse_assembler/r0_rivet_projectile.tscn")
const SCRAP_PROJECTILE_SCRIPT := preload("res://tiny_wizard/enemies/r0_reverse_assembler/r0_scrap_projectile.gd")
const BASE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter4/r0/r0_selected_model_128x128.png")
const PHASE_TEXTURES := {
	1: preload("res://tiny_wizard/assets/art/enemies/chapter4/r0/r0_phase1_rivet_128x128_8f.png"),
	2: preload("res://tiny_wizard/assets/art/enemies/chapter4/r0/r0_phase2_hydraulic_plate_128x128_8f.png"),
	3: preload("res://tiny_wizard/assets/art/enemies/chapter4/r0/r0_phase3_overload_128x128_8f.png"),
}
const PLATE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter4/r0/r0_armor_plate_20x14_4f.png")

const PHASE_ONE := 1
const PHASE_TWO := 2
const PHASE_THREE := 3
const BOSS_ORIGIN_OFFSET := Vector2(0.0, -64.0)
const BOSS_BATTLE_RECT := Rect2(122, 100, 780, 400)
const BOSS_BATTLE_MARGIN := 24.0
const RIVET_REQUESTED_DISTANCE := 220.0
const HYDRAULIC_REQUESTED_DISTANCE := 250.0
const SCRAP_REQUESTED_DISTANCES := [216.0, 256.0]
const CLEANUP_PART_IDS := [&"left_rivet", &"right_plate", &"north_rotor"]

@export var phase_one_threshold := 0.70
@export var phase_two_threshold := 0.35
@export var attack_cooldown := 1.15
@export var absorption_cooldown := 1.8
@export var core_vulnerability_multiplier := 1.5

@onready var body_sprite := $Visual/BodySprite as Sprite2D
@onready var shadow_sprite := $Visual/Shadow as Sprite2D
@onready var player_detector := $Behavior/PlayerDetector

var _phase := PHASE_ONE
var _phase_transition_timer := 0.0
var _attack_cooldown := 0.0
var _absorption_cooldown := 1.8
var _attack_elapsed := 0.0
var _attack_duration := 0.0
var _attack_name: StringName = &""
var _attack_executed := false
var _busy := false
var _locked_direction := Vector2.DOWN
var _core_vulnerable := false
var _installed_parts: Dictionary = {}
var _bound_parts: Dictionary = {}
var _arena_cleanup_started := false
var _pending_cleanup_parts: Dictionary = {}


func _ready() -> void:
	super._ready()
	boss_display_name = "逆向总装机 R-0「返炉」"
	protomatter_drop_chance = 0.0
	relic_drop_chance = 0.0
	green_blood_splatter_enabled = false
	if body_sprite != null:
		body_sprite.texture = BASE_TEXTURE
		body_sprite.hframes = 1
		body_sprite.frame = 0
		body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if shadow_sprite != null:
		shadow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_bind_room_parts")


func _process(delta: float) -> void:
	if _defeated:
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_absorption_cooldown = maxf(0.0, _absorption_cooldown - delta)
	_phase_transition_timer = maxf(0.0, _phase_transition_timer - delta)
	_sync_phase()
	if _phase_transition_timer > 0.0:
		return
	if _busy:
		if not _attack_name.is_empty():
			_animate_current_attack(delta)
		return

	var target_position := _get_player_position()
	if target_position == Vector2.INF:
		return
	if _absorption_cooldown <= 0.0 and _try_start_absorption():
		return
	if _attack_cooldown > 0.0:
		return

	var origin := global_position + BOSS_ORIGIN_OFFSET
	_locked_direction = origin.direction_to(target_position)
	if _locked_direction.length() < 0.01:
		_locked_direction = Vector2.DOWN
	_start_attack(_attack_for_phase())


func hit(damage := 1, from := Vector2.ZERO) -> void:
	var adjusted_damage := maxi(1, int(damage))
	if _core_vulnerable:
		adjusted_damage = maxi(1, ceili(float(adjusted_damage) * core_vulnerability_multiplier))
	super.hit(adjusted_damage, from)


func _sync_phase() -> void:
	if character_stats == null or character_stats.max_life <= 0:
		return
	var ratio := float(character_stats.current_life) / float(character_stats.max_life)
	var next_phase := PHASE_ONE
	if ratio <= phase_two_threshold:
		next_phase = PHASE_THREE
	elif ratio <= phase_one_threshold:
		next_phase = PHASE_TWO
	if next_phase == _phase:
		return
	_phase = next_phase
	_phase_transition_timer = 0.72
	_busy = not _pending_cleanup_parts.is_empty()
	_attack_name = &""
	_core_vulnerable = false
	_set_idle_texture()
	_spawn_phase_transition()


func _attack_for_phase() -> StringName:
	match _phase:
		PHASE_ONE:
			return &"magnetic_rivet"
		PHASE_TWO:
			return &"hydraulic_plate"
		PHASE_THREE:
			return &"scrap_overload"
	return &"magnetic_rivet"


func _start_attack(attack_name: StringName) -> void:
	_attack_name = attack_name
	_attack_elapsed = 0.0
	_attack_executed = false
	_busy = true
	_attack_duration = 1.55
	if attack_name == &"hydraulic_plate":
		_attack_duration = 2.05
	elif attack_name == &"scrap_overload":
		_attack_duration = 2.65
	_set_attack_texture()
	_spawn_attack_warning(attack_name)


func _animate_current_attack(delta: float) -> void:
	if not _busy:
		return
	_attack_elapsed += delta
	if body_sprite != null and body_sprite.hframes == 8:
		body_sprite.frame = mini(7, int(floor(_attack_elapsed / _attack_duration * 8.0)))
	var trigger_time := 0.66
	if _attack_name == &"hydraulic_plate":
		trigger_time = 0.76
	elif _attack_name == &"scrap_overload":
		trigger_time = 0.58
	if not _attack_executed and _attack_elapsed >= trigger_time:
		_attack_executed = true
		_execute_attack()
	if _attack_elapsed >= _attack_duration:
		_finish_attack()


func _execute_attack() -> void:
	match _attack_name:
		&"magnetic_rivet":
			_execute_magnetic_rivet()
		&"hydraulic_plate":
			_execute_hydraulic_plate()
		&"scrap_overload":
			_execute_scrap_overload()


func _finish_attack() -> void:
	_busy = false
	_attack_executed = false
	_attack_name = &""
	_attack_elapsed = 0.0
	_attack_cooldown = attack_cooldown
	_core_vulnerable = false
	_set_idle_texture()


func _execute_magnetic_rivet() -> void:
	var effect_parent := _get_room_node()
	if effect_parent == null:
		return
	var origin := global_position + BOSS_ORIGIN_OFFSET
	var directions := [
		Vector2.UP,
		Vector2(0.72, -0.72).normalized(),
		Vector2(0.72, 0.72).normalized(),
		Vector2.DOWN,
		Vector2(-0.72, 0.72).normalized(),
		Vector2(-0.72, -0.72).normalized(),
	]
	for direction in directions:
		var rivet := RIVET_SCENE.instantiate() as Area2D
		if rivet == null:
			continue
		effect_parent.add_child(rivet)
		var distance := _distance_inside_battle_area(origin, direction, RIVET_REQUESTED_DISTANCE)
		rivet.call("setup", origin, direction, distance, 2)


func _execute_hydraulic_plate() -> void:
	var effect_parent := _get_room_node()
	if effect_parent == null:
		return
	var origin := global_position + BOSS_ORIGIN_OFFSET
	var center := _clamp_to_battle_area(origin + _locked_direction * HYDRAULIC_REQUESTED_DISTANCE)
	var normal := _locked_direction.rotated(PI * 0.5)
	for index in range(3):
		var offset := float(index - 1) * 72.0
		var target := _clamp_to_battle_area(center + normal * offset)
		_spawn_plate_marker(effect_parent, target, float(index) * 0.18)


func _spawn_plate_marker(parent: Node, target: Vector2, delay: float) -> void:
	var plate := Sprite2D.new()
	plate.name = "R0HydraulicPlateMarker"
	plate.texture = PLATE_TEXTURE
	plate.hframes = 4
	plate.frame = 0
	plate.scale = Vector2(2.4, 2.4)
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plate.z_index = 8
	parent.add_child(plate)
	plate.global_position = target
	plate.modulate = Color(1.0, 0.68, 0.22, 0.18)
	var telegraph := plate.create_tween()
	telegraph.set_loops(2)
	telegraph.tween_property(plate, "modulate", Color(1.0, 0.18, 0.08, 0.84), 0.16)
	telegraph.tween_property(plate, "modulate", Color(1.0, 0.68, 0.22, 0.22), 0.16)
	_run_hydraulic_plate(plate, delay)


func _run_hydraulic_plate(plate: Sprite2D, delay: float) -> void:
	await get_tree().create_timer(0.46 + delay).timeout
	if not is_instance_valid(plate) or _defeated:
		return
	plate.frame = 2
	plate.modulate = Color(1.0, 0.22, 0.10, 1.0)
	_damage_circle(plate.global_position, 48.0, 3)
	_spawn_impact(plate.global_position, Color(1.0, 0.33, 0.12, 0.92), 44.0)
	var finish := plate.create_tween()
	finish.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	finish.tween_property(plate, "scale", Vector2(3.3, 3.3), 0.12)
	finish.parallel().tween_property(plate, "modulate", Color(1.0, 0.2, 0.1, 0.0), 0.22)
	finish.tween_callback(plate.queue_free)


func _execute_scrap_overload() -> void:
	var effect_parent := _get_room_node()
	if effect_parent == null:
		return
	var origin := global_position + BOSS_ORIGIN_OFFSET
	for index in range(10):
		var angle := TAU * float(index) / 10.0
		var direction := Vector2.from_angle(angle)
		var scrap := SCRAP_PROJECTILE_SCRIPT.new() as Area2D
		if scrap == null:
			continue
		effect_parent.add_child(scrap)
		var requested_distance: float = SCRAP_REQUESTED_DISTANCES[index % SCRAP_REQUESTED_DISTANCES.size()]
		var distance := _distance_inside_battle_area(origin, direction, requested_distance)
		scrap.call("setup", origin, direction, distance, 2)
	_open_core_after_overload()


func _open_core_after_overload() -> void:
	await get_tree().create_timer(0.88).timeout
	if _defeated or not is_instance_valid(self):
		return
	_core_vulnerable = true
	_spawn_core_pulse()
	await get_tree().create_timer(1.75).timeout
	_core_vulnerable = false


func _try_start_absorption() -> bool:
	if _busy or _arena_cleanup_started:
		return false
	_arena_cleanup_started = true
	_busy = true
	_absorption_cooldown = 999.0
	var target_position := global_position + BOSS_ORIGIN_OFFSET
	for part_id in CLEANUP_PART_IDS:
		var part := _bound_parts.get(part_id) as Node
		if part == null or not is_instance_valid(part) or part.get("_destroyed") == true:
			_open_room_source(part_id)
			_retract_room_source_visuals(part_id)
			continue
		_pending_cleanup_parts[part_id] = true
		_spawn_absorption_warning(part.global_position)
		var started := bool(part.call("begin_absorption", target_position))
		if not started:
			_pending_cleanup_parts.erase(part_id)
			_open_room_source(part_id)
			_retract_room_source_visuals(part_id)
	if _pending_cleanup_parts.is_empty():
		_busy = false
		_absorption_cooldown = 0.35
		_spawn_core_pulse()
	return true


func _bind_room_parts() -> void:
	var room := _get_room_node()
	if room == null:
		return
	var part_names := {
		&"left_rivet": "R0RoomParts/LeftRivetCassette",
		&"right_plate": "R0RoomParts/RightArmorPlate",
		&"north_rotor": "R0RoomParts/NorthMagneticRotor",
	}
	for part_id in part_names:
		var part := room.get_node_or_null(part_names[part_id]) as Node
		if part == null:
			continue
		_bound_parts[part_id] = part
		part.set("part_id", part_id)
		var destroyed_callable := Callable(self, "_on_part_destroyed")
		if part.has_signal("part_destroyed") and not part.is_connected("part_destroyed", destroyed_callable):
			part.connect("part_destroyed", destroyed_callable)
		var completed_callable := Callable(self, "_on_absorption_completed")
		if part.has_signal("absorption_completed") and not part.is_connected("absorption_completed", completed_callable):
			part.connect("absorption_completed", completed_callable)
		var retract_callable := Callable(self, "_on_retract_started")
		if part.has_signal("retract_started") and not part.is_connected("retract_started", retract_callable):
			part.connect("retract_started", retract_callable)


func _on_retract_started(part: Node) -> void:
	var part_id := StringName(str(part.get("part_id")))
	_open_room_source(part_id)
	_retract_room_source_visuals(part_id)


func _on_absorption_completed(part: Node) -> void:
	var part_id := StringName(str(part.get("part_id")))
	_installed_parts[part_id] = true
	module_state_changed.emit(part_id, true)
	_finish_cleanup_part(part_id)


func _on_part_destroyed(part: Node) -> void:
	var part_id := StringName(str(part.get("part_id")))
	module_state_changed.emit(part_id, false)
	_spawn_impact(part.global_position, Color(0.82, 0.28, 0.18, 0.9), 28.0)
	if _pending_cleanup_parts.has(part_id):
		_finish_cleanup_part(part_id)
	elif not _arena_cleanup_started:
		_absorption_cooldown = minf(_absorption_cooldown, 0.35)


func _finish_cleanup_part(part_id: StringName) -> void:
	_pending_cleanup_parts.erase(part_id)
	if not _pending_cleanup_parts.is_empty():
		return
	_busy = false
	_absorption_cooldown = 0.35
	_spawn_core_pulse()


func _open_room_source(part_id: StringName) -> void:
	var room := _get_room_node()
	if room == null:
		return
	var paths: Array[String] = []
	match part_id:
		&"left_rivet":
			paths = ["LeftMechBayBlocker", "ExosuitFactoryOverlay/SolidBlockerBossLeftMechRail"]
		&"right_plate":
			paths = ["RightMechBayBlocker", "ExosuitFactoryOverlay/SolidBlockerBossRightMechRail"]
		&"north_rotor":
			paths = ["NorthHeavyGateBlocker", "ExosuitFactoryOverlay/SolidBlockerBossNorthHeavyGate"]
	for path in paths:
		var node := room.get_node_or_null(path)
		if node != null:
			_disable_collision_tree(node)


func _retract_room_source_visuals(part_id: StringName) -> void:
	var room := _get_room_node()
	if room == null:
		return
	var overlay := room.get_node_or_null("ExosuitFactoryOverlay")
	if overlay != null and overlay.has_method("retract_boss_decor"):
		overlay.call("retract_boss_decor", part_id, global_position + BOSS_ORIGIN_OFFSET)


func _disable_collision_tree(node: Node) -> void:
	if node is CollisionObject2D:
		(node as CollisionObject2D).collision_layer = 0
		(node as CollisionObject2D).collision_mask = 0
	if node is CollisionShape2D:
		(node as CollisionShape2D).set_deferred("disabled", true)
	for child in node.get_children():
		_disable_collision_tree(child)


func _spawn_attack_warning(attack_name: StringName) -> void:
	var room := _get_room_node()
	if room == null:
		return
	var origin := global_position + BOSS_ORIGIN_OFFSET
	match attack_name:
		&"magnetic_rivet":
			for direction in [
				Vector2.UP,
				Vector2(0.72, -0.72).normalized(),
				Vector2(0.72, 0.72).normalized(),
				Vector2.DOWN,
				Vector2(-0.72, 0.72).normalized(),
				Vector2(-0.72, -0.72).normalized(),
			]:
				var distance := _distance_inside_battle_area(origin, direction, RIVET_REQUESTED_DISTANCE)
				_spawn_warning_line(room, origin, origin + direction * distance, 4.0, 0.66)
		&"hydraulic_plate":
			var center := _clamp_to_battle_area(origin + _locked_direction * HYDRAULIC_REQUESTED_DISTANCE)
			var normal := _locked_direction.rotated(PI * 0.5)
			for index in range(3):
				var target := _clamp_to_battle_area(center + normal * float(index - 1) * 72.0)
				_spawn_warning_circle(room, target, 42.0, 0.76 + float(index) * 0.18)
		&"scrap_overload":
			for index in range(10):
				var angle := TAU * float(index) / 10.0
				var direction := Vector2.from_angle(angle)
				var requested_distance: float = SCRAP_REQUESTED_DISTANCES[index % SCRAP_REQUESTED_DISTANCES.size()]
				var distance := _distance_inside_battle_area(origin, direction, requested_distance)
				_spawn_warning_line(room, origin, origin + direction * distance, 3.0, 0.58)


func _spawn_absorption_warning(source: Vector2) -> void:
	var room := _get_room_node()
	if room == null:
		return
	var line := Line2D.new()
	line.name = "R0AbsorptionWarning"
	line.z_index = 7
	line.width = 4.0
	line.default_color = Color(0.96, 0.56, 0.16, 0.84)
	line.points = PackedVector2Array([room.to_local(source), room.to_local(global_position + BOSS_ORIGIN_OFFSET)])
	room.add_child(line)
	var tween := line.create_tween()
	tween.set_loops(3)
	tween.tween_property(line, "modulate", Color(1.0, 0.2, 0.08, 0.18), 0.16)
	tween.tween_property(line, "modulate", Color.WHITE, 0.16)
	tween.tween_callback(line.queue_free)


func _spawn_warning_line(parent: Node, start: Vector2, end: Vector2, width: float, duration: float) -> void:
	var line := Line2D.new()
	line.name = "R0AttackWarning"
	line.z_index = 6
	line.width = width
	line.default_color = Color(0.95, 0.28, 0.12, 0.78)
	line.points = PackedVector2Array([parent.to_local(start), parent.to_local(end)])
	parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate", Color(1.0, 0.72, 0.18, 0.12), duration)
	tween.tween_callback(line.queue_free)


func _spawn_warning_circle(parent: Node, center: Vector2, radius: float, duration: float) -> void:
	var ring := Line2D.new()
	ring.name = "R0AttackWarningCircle"
	ring.z_index = 6
	ring.width = 3.0
	ring.default_color = Color(0.95, 0.28, 0.12, 0.76)
	var points := PackedVector2Array()
	for index in range(25):
		points.append(parent.to_local(center) + Vector2.from_angle(TAU * float(index) / 24.0) * radius)
	ring.points = points
	parent.add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate", Color(1.0, 0.72, 0.18, 0.1), duration)
	tween.tween_callback(ring.queue_free)


func _damage_circle(center: Vector2, radius: float, damage: int) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = 2
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var hit_ids := {}
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var target := result.get("collider") as Node
		if target == null or not target.has_method("hit"):
			continue
		var target_id := target.get_instance_id()
		if hit_ids.has(target_id):
			continue
		hit_ids[target_id] = true
		target.call("hit", damage, center.direction_to(target.global_position))


func _spawn_impact(position: Vector2, color: Color, radius: float) -> void:
	var room := _get_room_node()
	if room == null:
		return
	var pulse := Line2D.new()
	pulse.name = "R0Impact"
	pulse.z_index = 9
	pulse.width = 4.0
	pulse.default_color = color
	var points := PackedVector2Array()
	for index in range(17):
		points.append(room.to_local(position) + Vector2.from_angle(TAU * float(index) / 16.0) * radius)
	pulse.points = points
	pulse.closed = true
	pulse.scale = Vector2(0.35, 0.35)
	room.add_child(pulse)
	var tween := pulse.create_tween()
	tween.tween_property(pulse, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(pulse, "modulate", Color(color.r, color.g, color.b, 0.0), 0.28)
	tween.tween_callback(pulse.queue_free)


func _spawn_core_pulse() -> void:
	var room := _get_room_node()
	if room == null:
		return
	_spawn_impact(global_position + BOSS_ORIGIN_OFFSET, Color(0.20, 0.88, 0.92, 0.9), 58.0)


func _spawn_phase_transition() -> void:
	_spawn_core_pulse()
	if body_sprite != null:
		body_sprite.texture = PHASE_TEXTURES.get(_phase, BASE_TEXTURE)
		body_sprite.hframes = 8
		body_sprite.frame = 0


func _set_attack_texture() -> void:
	if body_sprite == null:
		return
	body_sprite.texture = PHASE_TEXTURES.get(_phase, BASE_TEXTURE)
	body_sprite.hframes = 8
	body_sprite.frame = 0


func _set_idle_texture() -> void:
	if body_sprite == null:
		return
	body_sprite.texture = BASE_TEXTURE
	body_sprite.hframes = 1
	body_sprite.frame = 0


func _get_player_position() -> Vector2:
	if player_detector == null or not player_detector.has_method("player_is_in_range"):
		return Vector2.INF
	if not player_detector.player_is_in_range():
		return Vector2.INF
	return player_detector.get_player_position()


func _get_room_node() -> Node:
	var enemies_parent := get_parent()
	if enemies_parent == null:
		return null
	return enemies_parent.get_parent()


func _clamp_to_battle_area(point: Vector2) -> Vector2:
	var room := _get_room_node() as Node2D
	if room == null:
		return point
	var safe_rect := BOSS_BATTLE_RECT.grow(-BOSS_BATTLE_MARGIN)
	var local_point: Vector2 = room.to_local(point)
	local_point.x = clampf(local_point.x, safe_rect.position.x, safe_rect.end.x)
	local_point.y = clampf(local_point.y, safe_rect.position.y, safe_rect.end.y)
	return room.to_global(local_point)


func _distance_inside_battle_area(origin: Vector2, direction: Vector2, requested_distance: float) -> float:
	var room := _get_room_node() as Node2D
	if room == null:
		return requested_distance
	var local_origin: Vector2 = room.to_local(origin)
	var local_direction := direction.normalized()
	var safe_rect := BOSS_BATTLE_RECT.grow(-BOSS_BATTLE_MARGIN)
	var distance := requested_distance
	if absf(local_direction.x) > 0.001:
		var edge_x := safe_rect.end.x if local_direction.x > 0.0 else safe_rect.position.x
		var candidate_x: float = (edge_x - local_origin.x) / local_direction.x
		if candidate_x > 0.0:
			distance = minf(distance, candidate_x)
	if absf(local_direction.y) > 0.001:
		var edge_y := safe_rect.end.y if local_direction.y > 0.0 else safe_rect.position.y
		var candidate_y: float = (edge_y - local_origin.y) / local_direction.y
		if candidate_y > 0.0:
			distance = minf(distance, candidate_y)
	return maxf(48.0, distance)
