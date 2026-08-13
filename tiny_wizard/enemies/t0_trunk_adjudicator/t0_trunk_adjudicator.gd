class_name Chapter5T0TrunkAdjudicator
extends "res://tiny_wizard/enemies/fusion_boss/fusion_boss.gd"

const TELEGRAPH := preload("res://tiny_wizard/enemies/chapter5_pixel_telegraph.gd")
const ORB_SCENE := preload("res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_forwarded_orb.tscn")
const PLATE_SCENE := preload("res://tiny_wizard/enemies/t0_trunk_adjudicator/t0_compression_plate.tscn")
const BASE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_trunk_adjudicator_idle_128x128.png")
const IDLE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_idle_128x128_6f.png")
const HIT_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_hit_128x128_4f.png")
const PHASE2_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_phase2_transition_128x128_10f.png")
const PHASE3_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_phase3_transition_128x128_12f.png")
const DEATH_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_death_128x128_14f.png")
const ATTACK_TEXTURES := {
	&"three_track": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_route_right_attack_128x128_10f.png"),
	&"route_direct": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_route_direct_body_128x128_15f.png"),
	&"data_sweep": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_data_sweep_body_128x128_20f.png"),
	&"cross_validation": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_cross_validation_body_128x128_19f.png"),
	&"forwarded_orb": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_forwarded_orb_body_128x128_21f.png"),
	&"compression": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_compression_body_128x128_20f.png"),
	&"intermittent_route": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_intermittent_route_body_128x128_21f.png"),
	&"ring_triple": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_ring_triple_body_128x128_28f.png"),
	&"terminal_adjudication": preload("res://tiny_wizard/assets/art/enemies/chapter5/t0/t0_terminal_adjudication_body_128x128_22f.png"),
}

const PHASE_ONE := 1
const PHASE_TWO := 2
const PHASE_THREE := 3
const BATTLE_RECT := Rect2(122, 100, 780, 400)
const PHASE3_ROOT_BOUNDS := Rect2(280, 280, 464, 190)
const ENDPOINTS := [Vector2(188, 158), Vector2(836, 158), Vector2(188, 442), Vector2(836, 442)]

@export var phase_one_threshold := 0.65
@export var phase_two_threshold := 0.30
@export var attack_cooldown := 1.25
@export var attack_damage := 1

@onready var body_sprite := $Visual/BodySprite as Sprite2D
@onready var player_detector := $Behavior/PlayerDetector

var _phase := PHASE_ONE
var _attack_cooldown := 1.0
var _attack_elapsed := 0.0
var _attack_duration := 0.0
var _attack_name: StringName = &""
var _attack_executed := false
var _attack_index := 0
var _phase_transition := 0.0
var _phase3_velocity := Vector2(58.0, 28.0)
var _death_pending := false


func _ready() -> void:
	super._ready()
	boss_display_name = "主干裁定核心 T-0"
	protomatter_drop_chance = 0.0
	relic_drop_chance = 0.0
	if body_sprite != null:
		body_sprite.texture = BASE_TEXTURE
		body_sprite.hframes = 1
		body_sprite.frame = 0
		body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func hit(damage := 1, from := Vector2.ZERO) -> void:
	if _death_pending:
		return
	super.hit(damage, from)


func die() -> void:
	if _defeated or _death_pending:
		return
	_death_pending = true
	_attack_name = &""
	_attack_cooldown = 999.0
	if body_sprite == null:
		_finish_death()
		return
	body_sprite.texture = DEATH_TEXTURE
	body_sprite.hframes = 14
	body_sprite.frame = 0
	var frame_tween := create_tween()
	frame_tween.tween_method(_set_death_frame, 0.0, 13.0, 0.72)
	get_tree().create_timer(0.74).timeout.connect(_finish_death)


func _process(delta: float) -> void:
	if _defeated:
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_phase_transition = maxf(0.0, _phase_transition - delta)
	_sync_phase()
	if _phase_transition > 0.0:
		return
	if _phase == PHASE_THREE and _attack_name.is_empty():
		_tick_phase_three_movement(delta)
	if not _attack_name.is_empty():
		_tick_attack(delta)
		return
	_set_idle_visual()
	if _attack_cooldown > 0.0 or player_detector == null or not player_detector.player_is_in_range():
		return
	_start_attack(_choose_attack())


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
	_phase_transition = 1.0
	_attack_name = &""
	_attack_cooldown = 1.0
	if body_sprite != null:
		body_sprite.texture = PHASE3_TEXTURE if _phase == PHASE_THREE else PHASE2_TEXTURE
		body_sprite.hframes = 12 if _phase == PHASE_THREE else 10
		body_sprite.frame = 0


func _choose_attack() -> StringName:
	var attacks: Array[StringName] = []
	match _phase:
		PHASE_ONE:
			attacks = [&"three_track", &"route_direct", &"data_sweep"]
		PHASE_TWO:
			attacks = [&"cross_validation", &"forwarded_orb", &"compression"]
		PHASE_THREE:
			attacks = [&"intermittent_route", &"ring_triple", &"terminal_adjudication"]
	var selected := attacks[_attack_index % attacks.size()]
	_attack_index += 1
	return selected


func _start_attack(attack_name: StringName) -> void:
	_attack_name = attack_name
	_attack_elapsed = 0.0
	_attack_executed = false
	_attack_duration = 1.6 if attack_name == &"terminal_adjudication" else 1.35
	if body_sprite != null:
		body_sprite.texture = ATTACK_TEXTURES.get(attack_name, IDLE_TEXTURE)
		body_sprite.hframes = _frame_count(attack_name)
		body_sprite.frame = 0
	_spawn_attack_warning(attack_name)


func _tick_attack(delta: float) -> void:
	_attack_elapsed += delta
	if body_sprite != null:
		body_sprite.frame = mini(_frame_count(_attack_name) - 1, int(floor(_attack_elapsed / _attack_duration * _frame_count(_attack_name))))
	if not _attack_executed and _attack_elapsed >= _attack_duration * 0.58:
		_attack_executed = true
		_execute_attack(_attack_name)
	if _attack_elapsed >= _attack_duration:
		_attack_name = &""
		_attack_cooldown = attack_cooldown
		if body_sprite != null:
			body_sprite.texture = IDLE_TEXTURE
			body_sprite.hframes = 6
			body_sprite.frame = 0


func _execute_attack(attack_name: StringName) -> void:
	var target := _player_position()
	var origin := global_position + Vector2(0.0, -60.0)
	match attack_name:
		&"three_track":
			_fire_parallel(origin, Vector2.RIGHT, 3, 18.0, 1)
		&"route_direct":
			_fire_lane(origin, origin.direction_to(target), 380.0, attack_damage)
		&"data_sweep":
			for angle in [-24.0, 0.0, 24.0]:
				_fire_lane(origin, origin.direction_to(target).rotated(deg_to_rad(angle)), 330.0, 1)
		&"cross_validation":
			_fire_lane(origin, Vector2.RIGHT, 620.0, 1)
			_fire_lane(origin, Vector2.DOWN, 420.0, 1)
		&"forwarded_orb":
			_fire_orb(target)
		&"compression":
			_fire_compression()
		&"intermittent_route":
			_fire_lane(_room_global(ENDPOINTS[0]), Vector2.DOWN, 300.0, 1)
			_fire_lane(_room_global(ENDPOINTS[3]), Vector2.LEFT, 620.0, 1)
		&"ring_triple":
			for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
				_fire_lane(origin, direction, 310.0, 1)
		&"terminal_adjudication":
			_fire_lane(origin, Vector2.RIGHT, 620.0, 2)
			_fire_lane(origin, Vector2.DOWN, 420.0, 2)


func _spawn_attack_warning(attack_name: StringName) -> void:
	var warning_parent := _get_drop_parent() as Node2D
	if warning_parent == null:
		return
	var origin := global_position + Vector2(0.0, -60.0)
	var local_origin := warning_parent.to_local(origin)
	var direction := local_origin.direction_to(warning_parent.to_local(_player_position()))
	match attack_name:
		&"three_track":
			TELEGRAPH.spawn_parallel(warning_parent, local_origin, Vector2.RIGHT, 360.0, 18.0, 3, 0.95)
		&"cross_validation", &"terminal_adjudication":
			TELEGRAPH.spawn_line(warning_parent, local_origin, Vector2.RIGHT, 620.0, 0.95, 4.0)
			TELEGRAPH.spawn_line(warning_parent, local_origin, Vector2.DOWN, 420.0, 0.95, 4.0)
		&"compression":
			for y in [238.0, 300.0, 362.0]:
				TELEGRAPH.spawn_line(warning_parent, Vector2(188.0, y), Vector2.RIGHT, 648.0, 0.95, 4.0)
		_:
			TELEGRAPH.spawn_line(warning_parent, local_origin, direction, 360.0, 0.95, 3.0)


func _fire_lane(origin: Vector2, direction: Vector2, distance: float, damage: int) -> void:
	var final_direction := direction.normalized()
	if final_direction.length() < 0.01:
		final_direction = Vector2.RIGHT
	var endpoint := origin + final_direction * distance
	var shape := RectangleShape2D.new()
	shape.size = Vector2(distance, 30.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(final_direction.angle(), origin + final_direction * distance * 0.5)
	query.collision_mask = 2
	query.exclude = [get_rid()]
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var target := result.get("collider") as Node
		if target != null and target.has_method("hit"):
			target.call("hit", damage, final_direction)
	_spawn_active_lane(origin, endpoint, Color(0.46, 0.86, 0.92, 0.9), 0.22)


func _fire_parallel(origin: Vector2, direction: Vector2, count: int, spacing: float, damage: int) -> void:
	var perpendicular := Vector2(-direction.y, direction.x)
	for index in range(count):
		_fire_lane(origin + perpendicular * (float(index) - (float(count) - 1.0) * 0.5) * spacing, direction, 360.0, damage)


func _fire_orb(target: Vector2) -> void:
	var parent := _get_drop_parent()
	if parent == null:
		return
	var orb := ORB_SCENE.instantiate() as Node2D
	if orb == null:
		return
	var start_local := Vector2(836, 158)
	var relay_local := Vector2(512, 300)
	if parent is Node2D:
		var room := parent as Node2D
		var start_global := room.to_global(start_local)
		var relay_global := room.to_global(relay_local)
		orb.position = start_local
		orb.call("setup", start_global, relay_global, target)
	else:
		orb.global_position = start_local
		orb.call("setup", start_local, relay_local, target)
	parent.call_deferred("add_child", orb)


func _fire_compression() -> void:
	var parent := _get_drop_parent()
	if parent == null:
		return
	for y in [238.0, 300.0, 362.0]:
		_spawn_plate(parent, Vector2(188.0, y), Vector2.RIGHT)
		_spawn_plate(parent, Vector2(836.0, y), Vector2.LEFT)


func _spawn_plate(parent: Node, position: Vector2, direction: Vector2) -> void:
	var plate := PLATE_SCENE.instantiate() as Node2D
	if plate == null:
		return
	if parent is Node2D:
		plate.position = position
	else:
		plate.global_position = position
	plate.call("setup", direction)
	parent.call_deferred("add_child", plate)


func _spawn_active_lane(origin: Vector2, endpoint: Vector2, color: Color, duration: float) -> void:
	var line := Line2D.new()
	line.name = "T0ActiveLane"
	line.z_index = 2
	line.width = 8.0
	line.default_color = color
	var line_parent := _get_drop_parent() as Node2D
	if line_parent == null:
		return
	line.points = PackedVector2Array([line_parent.to_local(origin), line_parent.to_local(endpoint)])
	line_parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, duration)
	tween.tween_callback(line.queue_free)


func _frame_count(attack_name: StringName) -> int:
	match attack_name:
		&"three_track": return 10
		&"route_direct": return 15
		&"data_sweep": return 20
		&"cross_validation": return 19
		&"forwarded_orb": return 21
		&"compression": return 20
		&"intermittent_route": return 21
		&"ring_triple": return 28
		&"terminal_adjudication": return 22
	return 6


func _tick_phase_three_movement(delta: float) -> void:
	position += _phase3_velocity * delta
	var bounced := false
	if position.x < PHASE3_ROOT_BOUNDS.position.x or position.x > PHASE3_ROOT_BOUNDS.end.x:
		position.x = clampf(position.x, PHASE3_ROOT_BOUNDS.position.x, PHASE3_ROOT_BOUNDS.end.x)
		_phase3_velocity.x *= -1.0
		bounced = true
	if position.y < PHASE3_ROOT_BOUNDS.position.y or position.y > PHASE3_ROOT_BOUNDS.end.y:
		var hit_top := position.y < PHASE3_ROOT_BOUNDS.position.y
		position.y = clampf(position.y, PHASE3_ROOT_BOUNDS.position.y, PHASE3_ROOT_BOUNDS.end.y)
		var vertical_speed := maxf(28.0, absf(_phase3_velocity.y))
		_phase3_velocity.y = vertical_speed if hit_top else -vertical_speed
		bounced = true
	if bounced and absf(_phase3_velocity.y) < 0.1:
		_phase3_velocity.y = 28.0


func _set_idle_visual() -> void:
	if body_sprite == null or body_sprite.texture == IDLE_TEXTURE:
		return
	body_sprite.texture = IDLE_TEXTURE
	body_sprite.hframes = 6
	body_sprite.frame = 0


func _set_death_frame(frame_value: float) -> void:
	if body_sprite != null:
		body_sprite.frame = clampi(int(frame_value), 0, 13)


func _finish_death() -> void:
	if _defeated:
		return
	_death_pending = false
	super.die()


func _player_position() -> Vector2:
	if player_detector != null and player_detector.player_is_in_range():
		return player_detector.get_player_position()
	return global_position + Vector2.RIGHT * 300.0


func _get_drop_parent() -> Node:
	var enemies_parent := get_parent()
	return enemies_parent.get_parent() if enemies_parent != null and enemies_parent.name == "Enemies" else enemies_parent


func _room_global(local_position: Vector2) -> Vector2:
	var room := _get_drop_parent() as Node2D
	return room.to_global(local_position) if room != null else local_position
