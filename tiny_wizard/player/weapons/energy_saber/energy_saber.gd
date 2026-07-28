extends LabMeleeWeapon


var _blade_tween: Tween
var _blade_idle_time := 0.0
var _blade_base_points := PackedVector2Array()
var _blade_base_width := 7.0

@onready var blade: Line2D = get_node_or_null("Blade") as Line2D
@onready var handle: CanvasItem = get_node_or_null("Handle") as CanvasItem


func _ready() -> void:
	hit_start_delay = 0.075
	visual_lunge_distance = 1.5
	slash_peak_alpha = 0.42
	slash_color = Color(0.38, 1.0, 0.96, 1.0)
	hit_flash_color = Color(0.82, 1.0, 0.98, 1.0)
	projectile_cut_color = Color(0.34, 1.0, 0.95, 0.95)
	super._ready()
	if blade != null:
		_blade_base_points = blade.points
		_blade_base_width = blade.width
		_play_blade_extend()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_blade_idle(delta)


func unequip() -> void:
	_stop_blade_tween()
	if blade != null:
		blade.visible = false
	super.unequip()


func _play_swing_animation() -> void:
	_pulse_blade_for_attack()
	super._play_swing_animation()


func _play_blade_extend() -> void:
	if blade == null:
		return
	_stop_blade_tween()
	blade.visible = true
	blade.width = maxf(_blade_base_width * 0.45, 2.0)
	blade.modulate = Color(0.28, 1.0, 0.95, 0.45)
	_set_blade_length(0.25)

	_blade_tween = create_tween()
	_blade_tween.set_trans(Tween.TRANS_QUAD)
	_blade_tween.tween_method(_set_blade_length, 0.25, 1.0, 0.2).set_ease(Tween.EASE_OUT)
	_blade_tween.parallel().tween_property(blade, "width", _blade_base_width, 0.2).set_ease(Tween.EASE_OUT)
	_blade_tween.parallel().tween_property(blade, "modulate", Color(0.7, 1.0, 0.98, 0.94), 0.2).set_ease(Tween.EASE_OUT)


func _pulse_blade_for_attack() -> void:
	if blade == null:
		return
	_stop_blade_tween()
	blade.visible = true
	_set_blade_length(1.0)
	blade.width = _blade_base_width * 1.12
	blade.modulate = Color(0.92, 1.0, 1.0, 1.0)


func _update_blade_idle(delta: float) -> void:
	if blade == null or not blade.visible:
		return
	if _attack_in_progress or _active_timer > 0.0:
		return
	_blade_idle_time += delta
	var flicker := (sin(_blade_idle_time * 18.0) + 1.0) * 0.5
	blade.width = lerpf(_blade_base_width * 0.92, _blade_base_width * 1.04, flicker)
	blade.modulate = Color(0.56, 1.0, 0.96, 0.82 + 0.1 * flicker)
	if handle != null:
		handle.modulate = Color(0.82 + 0.12 * flicker, 0.94, 0.95, 1.0)


func _set_blade_length(factor: float) -> void:
	if blade == null or _blade_base_points.size() < 2:
		return
	var clamped_factor := clampf(factor, 0.0, 1.0)
	var start := _blade_base_points[0]
	var end := _blade_base_points[_blade_base_points.size() - 1]
	blade.points = PackedVector2Array([start, start.lerp(end, clamped_factor)])


func _stop_blade_tween() -> void:
	if _blade_tween != null and _blade_tween.is_valid():
		_blade_tween.kill()
	_blade_tween = null
