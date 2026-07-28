extends LabMeleeWeapon


@export var idle_vibration := 0.018

enum ChainsawVisualState {
	IDLE,
	STARTUP,
	ATTACK_LOOP,
	SHUTDOWN,
}

var _vibration_time := 0.0
var _visual_state := ChainsawVisualState.IDLE
var _visual_state_time := 0.0
var _attack_held := false
var _contact_target_ids := {}
var _chain_flash_tween: Tween
var _contact_tween: Tween

@onready var chain_glow: CanvasItem = get_node_or_null("ChainGlow") as CanvasItem
@onready var chain_teeth: Line2D = get_node_or_null("ChainTeeth") as Line2D


func _ready() -> void:
	hit_start_delay = 0.0
	visual_lunge_distance = 2.5
	slash_peak_alpha = 0.22
	slash_color = Color(0.55, 1.0, 0.86, 1.0)
	hit_flash_color = Color(0.9, 1.0, 0.72, 1.0)
	projectile_cut_color = Color(0.48, 1.0, 0.9, 0.95)
	super._ready()
	if chain_glow != null:
		chain_glow.visible = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_chainsaw_visual_state(delta)
	_refresh_contact_targets()


func primary_pressed() -> void:
	_attack_held = true
	if _visual_state == ChainsawVisualState.IDLE or _visual_state == ChainsawVisualState.SHUTDOWN:
		_set_chainsaw_visual_state(ChainsawVisualState.STARTUP)
	if _cooldown_timer <= 0.0:
		swing()


func primary_released() -> void:
	_attack_held = false
	if _visual_state == ChainsawVisualState.STARTUP or _visual_state == ChainsawVisualState.ATTACK_LOOP:
		_set_chainsaw_visual_state(ChainsawVisualState.SHUTDOWN)


func unequip() -> void:
	_clear_chainsaw_visuals()
	super.unequip()


func _play_swing_animation() -> void:
	if _swing_tween != null:
		_swing_tween.kill()
	if _chain_flash_tween != null:
		_chain_flash_tween.kill()

	if _visual_state == ChainsawVisualState.STARTUP and _visual_state_time > 0.12:
		_set_chainsaw_visual_state(ChainsawVisualState.ATTACK_LOOP)

	if chain_glow != null:
		chain_glow.visible = true
		chain_glow.modulate = Color(0.55, 1.0, 0.92, 0.74)
		_chain_flash_tween = create_tween()
		_chain_flash_tween.tween_property(chain_glow, "modulate:a", 0.38, maxf(active_time, 0.05))


func _on_successful_hit(damage_target: Object, effect_position: Vector2) -> void:
	var target_id := damage_target.get_instance_id() if damage_target != null else 0
	var first_contact := target_id != 0 and not _contact_target_ids.has(target_id)
	if target_id != 0:
		_contact_target_ids[target_id] = damage_target
	_play_contact_spark(effect_position, first_contact)


func _on_projectile_destroyed(_projectile: Node, effect_position: Vector2) -> void:
	_play_projectile_cut_effect(effect_position)
	if chain_glow != null:
		chain_glow.visible = true
		chain_glow.modulate = Color(0.72, 1.0, 0.94, 0.78)


func _set_chainsaw_visual_state(new_state: int) -> void:
	if _visual_state == new_state:
		return
	_visual_state = new_state
	_visual_state_time = 0.0
	if new_state == ChainsawVisualState.IDLE:
		_contact_target_ids.clear()
		_hide_slash_visual()
		if chain_glow != null:
			chain_glow.visible = false
	elif new_state == ChainsawVisualState.STARTUP:
		if chain_glow != null:
			chain_glow.visible = true
			chain_glow.modulate = Color(1.0, 0.7, 0.22, 0.46)
	elif new_state == ChainsawVisualState.ATTACK_LOOP:
		_configure_slash_visual(slash_peak_alpha, 1.0)
	elif new_state == ChainsawVisualState.SHUTDOWN:
		_set_active(false)
		_active_timer = 0.0
		_activation_delay_timer = 0.0
		_attack_in_progress = false
		_contact_target_ids.clear()


func _update_chainsaw_visual_state(delta: float) -> void:
	_vibration_time += delta
	_visual_state_time += delta

	match _visual_state:
		ChainsawVisualState.IDLE:
			_apply_chainsaw_visual(0.0, sin(_vibration_time * 15.0) * idle_vibration * 6.0, 0.0)
			_update_chain_teeth(0.35)
		ChainsawVisualState.STARTUP:
			var startup_factor := clampf(_visual_state_time / 0.16, 0.0, 1.0)
			_apply_chainsaw_visual(lerpf(-1.0, 2.0, startup_factor), sin(_vibration_time * 38.0) * startup_factor, sin(_vibration_time * 34.0) * 0.05 * startup_factor)
			_update_chain_teeth(lerpf(0.5, 1.0, startup_factor))
			if startup_factor >= 1.0:
				if _attack_held:
					_set_chainsaw_visual_state(ChainsawVisualState.ATTACK_LOOP)
				else:
					_set_chainsaw_visual_state(ChainsawVisualState.SHUTDOWN)
		ChainsawVisualState.ATTACK_LOOP:
			_apply_chainsaw_visual(2.5, sin(_vibration_time * 55.0), sin(_vibration_time * 45.0) * 0.08)
			_update_chain_teeth(1.0)
			_configure_slash_visual(slash_peak_alpha * (0.75 + 0.25 * sin(_vibration_time * 42.0)), 1.0)
			if not _attack_held:
				_set_chainsaw_visual_state(ChainsawVisualState.SHUTDOWN)
		ChainsawVisualState.SHUTDOWN:
			var shutdown_factor := clampf(_visual_state_time / 0.13, 0.0, 1.0)
			_apply_chainsaw_visual(lerpf(2.0, 0.0, shutdown_factor), sin(_vibration_time * 28.0) * (1.0 - shutdown_factor), sin(_vibration_time * 26.0) * 0.04 * (1.0 - shutdown_factor))
			_update_chain_teeth(1.0 - shutdown_factor)
			if chain_glow != null:
				chain_glow.modulate.a = maxf(0.0, 0.45 * (1.0 - shutdown_factor))
			if shutdown_factor >= 1.0:
				_set_chainsaw_visual_state(ChainsawVisualState.IDLE)


func _apply_chainsaw_visual(forward_offset: float, shake_y: float, angle_offset: float) -> void:
	var visual_root := _get_attack_visual_root()
	visual_root.position = _base_visual_position + Vector2(forward_offset, shake_y)
	visual_root.rotation = _base_visual_rotation + angle_offset
	visual_root.scale = _base_visual_scale


func _update_chain_teeth(speed_factor: float) -> void:
	if chain_teeth == null:
		return
	var flicker := (sin(_vibration_time * lerpf(24.0, 72.0, speed_factor)) + 1.0) * 0.5
	chain_teeth.default_color = Color(0.92, 1.0, 0.9, 0.42 + 0.46 * flicker)
	chain_teeth.width = lerpf(2.2, 3.4, speed_factor)


func _play_contact_spark(effect_position: Vector2, first_contact: bool) -> void:
	if _contact_tween != null and _contact_tween.is_valid():
		_contact_tween.kill()
	_play_hit_flash(effect_position, true)
	if hit_flash != null:
		hit_flash.scale = Vector2(0.55, 0.55) if first_contact else Vector2(0.42, 0.42)
		hit_flash.modulate = Color(0.92, 1.0, 0.8, 0.95) if first_contact else Color(0.55, 1.0, 0.9, 0.72)
	var visual_root := _get_attack_visual_root()
	visual_root.position = _base_visual_position + Vector2(1.4, sin(_vibration_time * 70.0))


func _refresh_contact_targets() -> void:
	if _visual_state == ChainsawVisualState.IDLE or _visual_state == ChainsawVisualState.SHUTDOWN or hit_area == null:
		_contact_target_ids.clear()
		return

	var overlapping := {}
	for body in hit_area.get_overlapping_bodies():
		var damage_target := find_damage_target(body)
		if damage_target != null:
			overlapping[damage_target.get_instance_id()] = true

	for target_id in _contact_target_ids.keys():
		if not overlapping.has(target_id):
			_contact_target_ids.erase(target_id)


func _clear_chainsaw_visuals() -> void:
	_attack_held = false
	_visual_state = ChainsawVisualState.IDLE
	_visual_state_time = 0.0
	_contact_target_ids.clear()
	if _chain_flash_tween != null and _chain_flash_tween.is_valid():
		_chain_flash_tween.kill()
	if _contact_tween != null and _contact_tween.is_valid():
		_contact_tween.kill()
	if chain_glow != null:
		chain_glow.visible = false
