extends LabProjectileWeapon


@export_range(1, 10, 1) var punch_damage := 2
@export var punch_cooldown := 0.34
@export var punch_active_time := 0.12
@export_flags_2d_physics var punch_collision_mask := 8
@export_flags_2d_physics var projectile_collision_mask := 4
@export var punch_knockback_multiplier := 1.35
@export var can_destroy_enemy_projectiles := true
@export var punch_lunge_distance := 16.0
@export var punch_recover_time := 0.12

var _punch_cooldown_timer := 0.0
var _punch_active_timer := 0.0
var _punch_targets_hit := {}
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE
var _punch_tween: Tween
var _hit_flash_tween: Tween

@onready var punch_area: Area2D = get_node_or_null("PunchArea") as Area2D
@onready var punch_shape: CollisionShape2D = get_node_or_null("PunchArea/CollisionShape2D") as CollisionShape2D
@onready var punch_visual: CanvasItem = get_node_or_null("PunchVisual") as CanvasItem
@onready var hit_flash: Node2D = get_node_or_null("HitFlash") as Node2D


func _ready() -> void:
	_base_position = position
	_base_scale = scale
	if punch_area != null:
		punch_area.collision_layer = 0
		punch_area.collision_mask = punch_collision_mask | (projectile_collision_mask if can_destroy_enemy_projectiles else 0)
		punch_area.monitoring = false
		if not punch_area.body_entered.is_connected(_on_punch_area_body_entered):
			punch_area.body_entered.connect(_on_punch_area_body_entered)
		if not punch_area.area_entered.is_connected(_on_punch_area_area_entered):
			punch_area.area_entered.connect(_on_punch_area_area_entered)
	if punch_shape != null:
		punch_shape.disabled = true
	if punch_visual != null:
		punch_visual.visible = false
	if hit_flash != null:
		hit_flash.visible = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _punch_cooldown_timer > 0.0:
		_punch_cooldown_timer -= delta

	if _punch_active_timer <= 0.0:
		return

	_punch_active_timer -= delta
	_damage_overlapping_punch_targets()
	if _punch_active_timer <= 0.0:
		_set_punch_active(false)


func primary_pressed() -> void:
	if _punch_cooldown_timer <= 0.0:
		_start_punch()


func secondary_pressed() -> void:
	fire_projectile()


func unequip() -> void:
	_set_punch_active(false)
	_reset_punch_animation()
	super.unequip()


func _start_punch() -> void:
	_punch_cooldown_timer = punch_cooldown * get_fire_cooldown_multiplier()
	_punch_active_timer = punch_active_time
	_punch_targets_hit.clear()
	_set_punch_active(true)
	_play_punch_animation()
	_damage_overlapping_punch_targets()


func _set_punch_active(is_active: bool) -> void:
	if punch_area != null:
		punch_area.monitoring = is_active
	if punch_shape != null:
		punch_shape.disabled = not is_active
	if punch_visual != null:
		punch_visual.visible = is_active


func _damage_overlapping_punch_targets() -> void:
	if punch_area == null:
		return
	for body in punch_area.get_overlapping_bodies():
		if not _try_destroy_projectile(body):
			_hit_punch_body(body)
	for area in punch_area.get_overlapping_areas():
		_try_destroy_projectile(area)


func _on_punch_area_body_entered(body: Node2D) -> void:
	if _punch_active_timer > 0.0 and not _try_destroy_projectile(body):
		_hit_punch_body(body)


func _on_punch_area_area_entered(area: Area2D) -> void:
	if _punch_active_timer > 0.0:
		_try_destroy_projectile(area)


func _hit_punch_body(body: Node2D) -> void:
	var damage_target := find_damage_target(body)
	if damage_target == null:
		return

	var instance_id := damage_target.get_instance_id()
	if _punch_targets_hit.has(instance_id):
		return

	var knockback_direction := aim_direction
	if owner_character != null and damage_target is Node2D:
		knockback_direction = owner_character.global_position.direction_to((damage_target as Node2D).global_position)
	if knockback_direction.length() < 0.01:
		knockback_direction = Vector2.RIGHT

	if apply_damage_to_target(damage_target, punch_damage, knockback_direction.normalized() * punch_knockback_multiplier):
		_punch_targets_hit[instance_id] = true
		_play_hit_flash()


func _try_destroy_projectile(projectile: Node) -> bool:
	if not can_destroy_enemy_projectiles:
		return false
	if try_destroy_enemy_projectile(projectile, aim_direction):
		_play_hit_flash()
		return true
	return false


func _play_punch_animation() -> void:
	if _punch_tween != null:
		_punch_tween.kill()

	var attack_time: float = max(punch_active_time * 0.75, 0.06)
	var peak_scale: Vector2 = Vector2(_base_scale.x * 1.12, _base_scale.y * 0.92)
	position = _base_position
	scale = _base_scale

	_punch_tween = create_tween()
	_punch_tween.set_trans(Tween.TRANS_QUAD)
	_punch_tween.tween_property(self, "position", _base_position + Vector2(punch_lunge_distance, 0), attack_time).set_ease(Tween.EASE_OUT)
	_punch_tween.parallel().tween_property(self, "scale", peak_scale, attack_time).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(self, "position", _base_position, punch_recover_time).set_ease(Tween.EASE_OUT)
	_punch_tween.parallel().tween_property(self, "scale", _base_scale, punch_recover_time).set_ease(Tween.EASE_OUT)


func _play_hit_flash() -> void:
	if hit_flash == null:
		return
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()

	hit_flash.visible = true
	hit_flash.scale = Vector2(0.55, 0.55)
	hit_flash.modulate = Color(1, 1, 1, 1)

	_hit_flash_tween = create_tween()
	_hit_flash_tween.set_trans(Tween.TRANS_QUAD)
	_hit_flash_tween.tween_property(hit_flash, "scale", Vector2(1.35, 1.35), 0.08).set_ease(Tween.EASE_OUT)
	_hit_flash_tween.parallel().tween_property(hit_flash, "modulate", Color(1, 1, 1, 0), 0.1).set_ease(Tween.EASE_IN)
	_hit_flash_tween.tween_callback(func() -> void: hit_flash.visible = false)


func _reset_punch_animation() -> void:
	if _punch_tween != null:
		_punch_tween.kill()
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()
	position = _base_position
	scale = _base_scale
	if hit_flash != null:
		hit_flash.visible = false
