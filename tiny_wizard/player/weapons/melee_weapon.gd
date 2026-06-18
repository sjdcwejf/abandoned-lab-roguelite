class_name LabMeleeWeapon
extends LabWeapon


@export_range(1, 10, 1) var damage := 2
@export var cooldown := 0.38
@export var active_time := 0.14
@export_flags_2d_physics var collision_mask := 8
@export var swing_start_angle := -0.55
@export var swing_end_angle := 0.5
@export var swing_recover_time := 0.12
@export var swing_scale_peak := Vector2(1.08, 1.08)

var _cooldown_timer := 0.0
var _active_timer := 0.0
var _targets_hit := {}
var _base_rotation := 0.0
var _base_scale := Vector2.ONE
var _swing_tween: Tween
var _hit_flash_tween: Tween

@onready var hit_area: Area2D = get_node_or_null("HitArea") as Area2D
@onready var hit_shape: CollisionShape2D = get_node_or_null("HitArea/CollisionShape2D") as CollisionShape2D
@onready var slash_visual: CanvasItem = get_node_or_null("SlashVisual") as CanvasItem
@onready var hit_flash: Node2D = get_node_or_null("HitFlash") as Node2D


func _ready() -> void:
	_base_rotation = rotation
	_base_scale = scale
	if hit_area != null:
		hit_area.collision_layer = 0
		hit_area.collision_mask = collision_mask
		hit_area.monitoring = false
		if not hit_area.body_entered.is_connected(_on_hit_area_body_entered):
			hit_area.body_entered.connect(_on_hit_area_body_entered)
	if hit_shape != null:
		hit_shape.disabled = true
	if slash_visual != null:
		slash_visual.visible = false
	if hit_flash != null:
		hit_flash.visible = false


func _physics_process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	if _active_timer <= 0.0:
		return

	_active_timer -= delta
	_damage_overlapping_targets()
	if _active_timer <= 0.0:
		_set_active(false)


func primary_pressed() -> void:
	if _cooldown_timer <= 0.0:
		swing()


func unequip() -> void:
	_set_active(false)
	_reset_swing_animation()
	super.unequip()


func swing() -> void:
	_cooldown_timer = cooldown * get_fire_cooldown_multiplier()
	_active_timer = active_time
	_targets_hit.clear()
	_set_active(true)
	_play_swing_animation()
	_damage_overlapping_targets()


func _set_active(is_active: bool) -> void:
	if hit_area != null:
		hit_area.monitoring = is_active
	if hit_shape != null:
		hit_shape.disabled = not is_active
	if slash_visual != null:
		slash_visual.visible = is_active


func _damage_overlapping_targets() -> void:
	if hit_area == null:
		return
	for body in hit_area.get_overlapping_bodies():
		_hit_body(body)


func _on_hit_area_body_entered(body: Node2D) -> void:
	if _active_timer > 0.0:
		_hit_body(body)


func _hit_body(body: Node2D) -> void:
	var damage_target := find_damage_target(body)
	if damage_target == null:
		return

	var instance_id := damage_target.get_instance_id()
	if _targets_hit.has(instance_id):
		return

	if apply_damage_to_target(damage_target, damage, Vector2.ZERO, get_fire_origin()):
		_targets_hit[instance_id] = true
		_play_hit_flash()


func _play_swing_animation() -> void:
	if _swing_tween != null:
		_swing_tween.kill()

	var peak_scale: Vector2 = Vector2(_base_scale.x * swing_scale_peak.x, _base_scale.y * swing_scale_peak.y)
	var attack_time: float = max(active_time, 0.06)
	rotation = _base_rotation + swing_start_angle
	scale = _base_scale

	_swing_tween = create_tween()
	_swing_tween.set_trans(Tween.TRANS_SINE)
	_swing_tween.tween_property(self, "rotation", _base_rotation + swing_end_angle, attack_time).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(self, "scale", peak_scale, attack_time * 0.7).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(self, "rotation", _base_rotation, swing_recover_time).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(self, "scale", _base_scale, swing_recover_time).set_ease(Tween.EASE_OUT)


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
	_hit_flash_tween.tween_property(hit_flash, "scale", Vector2(1.25, 1.25), 0.08).set_ease(Tween.EASE_OUT)
	_hit_flash_tween.parallel().tween_property(hit_flash, "modulate", Color(1, 1, 1, 0), 0.1).set_ease(Tween.EASE_IN)
	_hit_flash_tween.tween_callback(func() -> void: hit_flash.visible = false)


func _reset_swing_animation() -> void:
	if _swing_tween != null:
		_swing_tween.kill()
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()
	rotation = _base_rotation
	scale = _base_scale
	if hit_flash != null:
		hit_flash.visible = false
