extends LabMeleeWeapon


@export var idle_vibration := 0.018

var _vibration_time := 0.0
var _chain_flash_tween: Tween

@onready var chain_glow: CanvasItem = get_node_or_null("ChainGlow") as CanvasItem
@onready var chain_teeth: Line2D = get_node_or_null("ChainTeeth") as Line2D


func _ready() -> void:
	super._ready()
	if chain_glow != null:
		chain_glow.visible = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_chain_vibration(delta)


func unequip() -> void:
	if _chain_flash_tween != null:
		_chain_flash_tween.kill()
	if chain_glow != null:
		chain_glow.visible = false
	super.unequip()


func _play_swing_animation() -> void:
	if _swing_tween != null:
		_swing_tween.kill()
	if _chain_flash_tween != null:
		_chain_flash_tween.kill()

	var attack_time: float = max(active_time, 0.05)
	var offset := sin(_vibration_time * 37.0) * idle_vibration
	rotation = _base_rotation + offset
	scale = _base_scale * Vector2(1.04, 1.03)

	_swing_tween = create_tween()
	_swing_tween.set_trans(Tween.TRANS_SINE)
	_swing_tween.tween_property(self, "rotation", _base_rotation - offset, attack_time * 0.5).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(self, "rotation", _base_rotation, swing_recover_time).set_ease(Tween.EASE_OUT)
	_swing_tween.parallel().tween_property(self, "scale", _base_scale, swing_recover_time).set_ease(Tween.EASE_OUT)

	if chain_glow != null:
		chain_glow.visible = true
		chain_glow.modulate = Color(0.55, 1.0, 0.92, 0.84)
		_chain_flash_tween = create_tween()
		_chain_flash_tween.tween_property(chain_glow, "modulate:a", 0.28, attack_time + swing_recover_time)
		_chain_flash_tween.tween_callback(func() -> void: chain_glow.visible = false)


func _update_chain_vibration(delta: float) -> void:
	_vibration_time += delta
	if chain_teeth == null:
		return
	var flicker := (sin(_vibration_time * 48.0) + 1.0) * 0.5
	chain_teeth.default_color = Color(0.92, 1.0, 0.9, 0.55 + 0.35 * flicker)
