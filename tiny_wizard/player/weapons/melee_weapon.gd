class_name LabMeleeWeapon
extends LabWeapon


@export_range(1, 10, 1) var damage := 2
@export var cooldown := 0.38
@export var active_time := 0.14
@export_flags_2d_physics var collision_mask := 8
@export_flags_2d_physics var projectile_collision_mask := 4
@export var knockback_multiplier := 1.15
@export var can_destroy_enemy_projectiles := true
@export var swing_start_angle := -0.55
@export var swing_end_angle := 0.5
@export var swing_recover_time := 0.12
@export var swing_scale_peak := Vector2(1.08, 1.08)
@export var hit_start_delay := 0.0
@export var visual_lunge_distance := 1.0
@export var slash_peak_alpha := 0.34
@export var slash_color := Color(0.96, 0.95, 0.78, 1.0)
@export var hit_flash_color := Color(1.0, 0.96, 0.72, 1.0)
@export var projectile_cut_color := Color(0.92, 0.96, 1.0, 1.0)
@export var slash_texture: Texture2D
@export var slash_frame_count := 1
@export var hit_texture: Texture2D
@export var hit_frame_count := 1
@export var projectile_cut_texture: Texture2D
@export var projectile_cut_frame_count := 1

var _cooldown_timer := 0.0
var _active_timer := 0.0
var _activation_delay_timer := 0.0
var _attack_in_progress := false
var _targets_hit := {}
var _projectiles_cut := {}
var _base_rotation := 0.0
var _base_scale := Vector2.ONE
var _base_visual_position := Vector2.ZERO
var _base_visual_rotation := 0.0
var _base_visual_scale := Vector2.ONE
var _swing_tween: Tween
var _slash_frame_tween: Tween
var _hit_flash_tween: Tween
var _effect_tweens: Array[Tween] = []
var _slash_sprite: Sprite2D
var _hit_sprite: Sprite2D
var _fallback_visual_items: Array[CanvasItem] = []

@onready var hit_area: Area2D = get_node_or_null("HitArea") as Area2D
@onready var hit_shape: CollisionShape2D = get_node_or_null("HitArea/CollisionShape2D") as CollisionShape2D
@onready var slash_visual: CanvasItem = get_node_or_null("SlashVisual") as CanvasItem
@onready var hit_flash: Node2D = get_node_or_null("HitFlash") as Node2D


func _ready() -> void:
	_ensure_orientation_nodes()
	_base_rotation = rotation
	_base_scale = scale
	var visual_root := _get_attack_visual_root()
	_base_visual_position = visual_root.position
	_base_visual_rotation = visual_root.rotation
	_base_visual_scale = visual_root.scale
	_setup_texture_visuals()
	if hit_area != null:
		hit_area.collision_layer = 0
		hit_area.collision_mask = collision_mask | (projectile_collision_mask if can_destroy_enemy_projectiles else 0)
		hit_area.monitoring = false
		if not hit_area.body_entered.is_connected(_on_hit_area_body_entered):
			hit_area.body_entered.connect(_on_hit_area_body_entered)
		if not hit_area.area_entered.is_connected(_on_hit_area_area_entered):
			hit_area.area_entered.connect(_on_hit_area_area_entered)
	if hit_shape != null:
		hit_shape.disabled = true
	if slash_visual != null:
		slash_visual.visible = false
	if hit_flash != null:
		hit_flash.visible = false


func _physics_process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	if _activation_delay_timer > 0.0:
		_activation_delay_timer -= delta
		if _activation_delay_timer <= 0.0 and _attack_in_progress:
			_activate_hit_window()

	if _active_timer <= 0.0:
		return

	_active_timer -= delta
	_damage_overlapping_targets()
	if _active_timer <= 0.0:
		_set_active(false)
		_attack_in_progress = false


func primary_pressed() -> void:
	if _cooldown_timer <= 0.0:
		swing()


func unequip() -> void:
	_set_active(false)
	_reset_swing_animation()
	super.unequip()


func swing() -> void:
	_cooldown_timer = cooldown * get_fire_cooldown_multiplier()
	_active_timer = 0.0
	_activation_delay_timer = maxf(hit_start_delay, 0.0)
	_attack_in_progress = true
	_targets_hit.clear()
	_projectiles_cut.clear()
	_set_active(false)
	_play_swing_animation()
	if _activation_delay_timer <= 0.0:
		_activate_hit_window()


func _activate_hit_window() -> void:
	if _active_timer > 0.0:
		return
	_activation_delay_timer = 0.0
	_active_timer = active_time
	_set_active(true)
	_damage_overlapping_targets()


func _set_active(is_active: bool) -> void:
	if hit_area != null:
		hit_area.monitoring = is_active
	if hit_shape != null:
		hit_shape.disabled = not is_active


func _damage_overlapping_targets() -> void:
	if hit_area == null:
		return
	for body in hit_area.get_overlapping_bodies():
		if not _try_destroy_projectile(body):
			_hit_body(body)
	for area in hit_area.get_overlapping_areas():
		_try_destroy_projectile(area)


func _on_hit_area_body_entered(body: Node2D) -> void:
	if _active_timer > 0.0 and not _try_destroy_projectile(body):
		_hit_body(body)


func _on_hit_area_area_entered(area: Area2D) -> void:
	if _active_timer > 0.0:
		_try_destroy_projectile(area)


func _hit_body(body: Node2D) -> void:
	var damage_target := find_damage_target(body)
	if damage_target == null:
		return

	var instance_id := damage_target.get_instance_id()
	if _targets_hit.has(instance_id):
		return

	var knockback_direction := aim_direction
	if owner_character != null and damage_target is Node2D:
		knockback_direction = owner_character.global_position.direction_to((damage_target as Node2D).global_position)
	if knockback_direction.length() < 0.01:
		knockback_direction = Vector2.RIGHT

	if apply_damage_to_target(damage_target, damage, knockback_direction.normalized() * knockback_multiplier):
		_targets_hit[instance_id] = true
		_on_successful_hit(damage_target, _get_effect_position(damage_target))


func _try_destroy_projectile(projectile: Node) -> bool:
	if not can_destroy_enemy_projectiles:
		return false
	if projectile == null or not projectile.is_in_group(ENEMY_PROJECTILE_GROUP):
		return false
	var projectile_id := projectile.get_instance_id()
	if _projectiles_cut.has(projectile_id):
		return true
	var effect_position := _get_effect_position(projectile)
	if try_destroy_enemy_projectile(projectile, aim_direction):
		_projectiles_cut[projectile_id] = true
		_on_projectile_destroyed(projectile, effect_position)
		return true
	return false


func _play_swing_animation() -> void:
	if _swing_tween != null:
		_swing_tween.kill()
	if _slash_frame_tween != null:
		_slash_frame_tween.kill()

	var visual_root := _get_attack_visual_root()
	var peak_scale: Vector2 = Vector2(_base_visual_scale.x * swing_scale_peak.x, _base_visual_scale.y * swing_scale_peak.y)
	var attack_time: float = max(active_time, 0.06)
	visual_root.rotation = _base_visual_rotation + swing_start_angle
	visual_root.position = _base_visual_position + Vector2(-visual_lunge_distance, 0)
	visual_root.scale = _base_visual_scale
	_configure_slash_visual(0.0, 0.55, 0)

	_swing_tween = create_tween()
	_swing_tween.set_trans(Tween.TRANS_SINE)
	if hit_start_delay > 0.0:
		_swing_tween.tween_property(visual_root, "rotation", _base_visual_rotation + swing_start_angle * 1.08, hit_start_delay).set_ease(Tween.EASE_IN)
		_swing_tween.parallel().tween_property(visual_root, "position", _base_visual_position + Vector2(-visual_lunge_distance, 0), hit_start_delay).set_ease(Tween.EASE_IN)
	_swing_tween.tween_callback(func() -> void:
		_configure_slash_visual(slash_peak_alpha, 1.0, 0)
		_start_slash_frame_animation(attack_time + swing_recover_time * 0.45)
	)
	_swing_tween.tween_property(visual_root, "rotation", _base_visual_rotation + swing_end_angle, attack_time).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(visual_root, "scale", peak_scale, attack_time * 0.7).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(visual_root, "position", _base_visual_position + Vector2(visual_lunge_distance, 0), attack_time * 0.8).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_callback(func() -> void: _configure_slash_visual(slash_peak_alpha * 0.8, 1.0, maxi(0, slash_frame_count - 1)))
	_swing_tween.tween_property(visual_root, "rotation", _base_visual_rotation, swing_recover_time).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(visual_root, "scale", _base_visual_scale, swing_recover_time).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(visual_root, "position", _base_visual_position, swing_recover_time).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_callback(_hide_slash_visual)


func _on_successful_hit(damage_target: Object, effect_position: Vector2) -> void:
	_play_hit_flash(effect_position, damage_target is Node2D)


func _on_projectile_destroyed(_projectile: Node, effect_position: Vector2) -> void:
	_play_projectile_cut_effect(effect_position)


func _play_hit_flash(effect_position := Vector2.ZERO, use_global_position := false) -> void:
	var flash_node := _hit_sprite if _hit_sprite != null else hit_flash
	if flash_node == null:
		return
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()

	flash_node.visible = true
	flash_node.scale = Vector2(0.55, 0.55)
	flash_node.modulate = hit_flash_color
	_set_sprite_frame(_hit_sprite, 0)
	if use_global_position:
		flash_node.position = _get_attack_visual_root().to_local(effect_position)

	_hit_flash_tween = create_tween()
	_hit_flash_tween.set_trans(Tween.TRANS_QUAD)
	_hit_flash_tween.tween_method(_set_hit_sprite_frame, 0, maxi(0, hit_frame_count - 1), 0.1)
	_hit_flash_tween.parallel().tween_property(flash_node, "scale", Vector2(1.25, 1.25), 0.08).set_ease(Tween.EASE_OUT)
	_hit_flash_tween.parallel().tween_property(flash_node, "modulate", Color(1, 1, 1, 0), 0.1).set_ease(Tween.EASE_IN)
	_hit_flash_tween.tween_callback(func() -> void: flash_node.visible = false)


func _reset_swing_animation() -> void:
	if _swing_tween != null:
		_swing_tween.kill()
	if _slash_frame_tween != null:
		_slash_frame_tween.kill()
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()
	for tween in _effect_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_effect_tweens.clear()
	_activation_delay_timer = 0.0
	_active_timer = 0.0
	_attack_in_progress = false
	_targets_hit.clear()
	_projectiles_cut.clear()
	rotation = _base_rotation
	scale = _base_scale
	var visual_root := _get_attack_visual_root()
	visual_root.position = _base_visual_position
	visual_root.rotation = _base_visual_rotation
	visual_root.scale = _base_visual_scale
	_hide_slash_visual()
	if hit_flash != null:
		hit_flash.visible = false
	if _hit_sprite != null:
		_hit_sprite.visible = false


func _get_attack_visual_root() -> Node2D:
	if _visual_root != null:
		return _visual_root
	return self


func _configure_slash_visual(alpha: float, slash_scale := 1.0, frame := 0) -> void:
	var visual_item := _slash_sprite if _slash_sprite != null else slash_visual
	if visual_item == null:
		return
	visual_item.visible = alpha > 0.0
	visual_item.modulate = Color(slash_color.r, slash_color.g, slash_color.b, alpha)
	_set_sprite_frame(_slash_sprite, frame)
	_set_fallback_visuals_visible(alpha <= 0.0 or _slash_sprite == null)
	var slash_node := visual_item as Node2D
	if slash_node != null:
		slash_node.scale = Vector2(slash_scale, slash_scale)


func _hide_slash_visual() -> void:
	if slash_visual != null:
		slash_visual.visible = false
	if _slash_sprite != null:
		_slash_sprite.visible = false
	_set_fallback_visuals_visible(true)


func _get_effect_position(target: Object) -> Vector2:
	if target is Node2D:
		return (target as Node2D).global_position
	return get_fire_origin()


func _play_projectile_cut_effect(effect_position: Vector2) -> void:
	var cut := _create_projectile_cut_visual()
	if cut == null:
		return
	cut.global_position = effect_position
	cut.global_rotation = aim_direction.angle() + PI * 0.35
	add_child(cut)

	var tween := create_tween()
	_effect_tweens.append(tween)
	if cut is Sprite2D:
		tween.tween_method(func(value: int) -> void:
			_set_sprite_frame(cut as Sprite2D, value)
		, 0, maxi(0, projectile_cut_frame_count - 1), 0.08)
	tween.tween_property(cut, "scale", Vector2(1.45, 1.45), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cut, "modulate", Color(1, 1, 1, 0), 0.08).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if is_instance_valid(cut):
			cut.queue_free()
	)


func _setup_texture_visuals() -> void:
	var visual_root := _get_attack_visual_root()
	if slash_texture != null:
		_cache_fallback_visual_items(visual_root)
		_slash_sprite = Sprite2D.new()
		_slash_sprite.name = "AttackSprite"
		_slash_sprite.texture = slash_texture
		_slash_sprite.hframes = maxi(1, slash_frame_count)
		_slash_sprite.centered = true
		_slash_sprite.position = Vector2(48, 0)
		_slash_sprite.z_index = 30
		_slash_sprite.visible = false
		visual_root.add_child(_slash_sprite)
		if slash_visual != null:
			slash_visual.visible = false
	if hit_texture != null:
		_hit_sprite = Sprite2D.new()
		_hit_sprite.name = "ContactEffect"
		_hit_sprite.texture = hit_texture
		_hit_sprite.hframes = maxi(1, hit_frame_count)
		_hit_sprite.centered = true
		_hit_sprite.position = hit_flash.position if hit_flash != null else Vector2(66, 0)
		_hit_sprite.z_index = 32
		_hit_sprite.visible = false
		visual_root.add_child(_hit_sprite)
		if hit_flash != null:
			hit_flash.visible = false


func _create_projectile_cut_visual() -> Node2D:
	if projectile_cut_texture != null:
		var cut_sprite := Sprite2D.new()
		cut_sprite.name = "ProjectileCutEffect"
		cut_sprite.top_level = true
		cut_sprite.z_index = 35
		cut_sprite.texture = projectile_cut_texture
		cut_sprite.hframes = maxi(1, projectile_cut_frame_count)
		cut_sprite.centered = true
		cut_sprite.modulate = projectile_cut_color
		return cut_sprite

	var cut_line := Line2D.new()
	cut_line.name = "ProjectileCutEffect"
	cut_line.top_level = true
	cut_line.z_index = 35
	cut_line.width = 2.0
	cut_line.default_color = projectile_cut_color
	cut_line.points = PackedVector2Array([Vector2(-8, -3), Vector2(8, 3)])
	return cut_line


func _set_hit_sprite_frame(value: int) -> void:
	_set_sprite_frame(_hit_sprite, value)


func _set_slash_sprite_frame(value: int) -> void:
	_set_sprite_frame(_slash_sprite, value)


func _set_sprite_frame(sprite: Sprite2D, value: int) -> void:
	if sprite == null:
		return
	sprite.frame = clampi(value, 0, maxi(0, sprite.hframes - 1))


func _start_slash_frame_animation(duration: float) -> void:
	if _slash_sprite == null:
		return
	if _slash_frame_tween != null and _slash_frame_tween.is_valid():
		_slash_frame_tween.kill()
	_slash_frame_tween = create_tween()
	_slash_frame_tween.tween_method(_set_slash_sprite_frame, 0, maxi(0, slash_frame_count - 1), maxf(duration, 0.04))


func _cache_fallback_visual_items(visual_root: Node2D) -> void:
	_fallback_visual_items.clear()
	for child in visual_root.get_children():
		if child == slash_visual or child == hit_flash:
			continue
		if child is CanvasItem:
			_fallback_visual_items.append(child as CanvasItem)


func _set_fallback_visuals_visible(is_visible: bool) -> void:
	for item in _fallback_visual_items:
		if item != null and is_instance_valid(item):
			item.visible = is_visible
