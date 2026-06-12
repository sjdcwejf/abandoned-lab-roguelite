class_name LabTrainingTarget
extends StaticBody2D


signal target_activated(target: Node)

@export var target_id := "A"
@export var idle_ring_color := Color(0.9, 0.18, 0.12, 1.0)
@export var active_ring_color := Color(0.2, 0.95, 0.78, 1.0)
@export var idle_core_color := Color(0.95, 0.55, 0.16, 1.0)
@export var active_core_color := Color(0.72, 1.0, 0.92, 1.0)

var activated := false
var _pulse_tween: Tween

@onready var outer_ring: Line2D = get_node_or_null("OuterRing") as Line2D
@onready var core: Polygon2D = get_node_or_null("Core") as Polygon2D
@onready var label: Label = get_node_or_null("Label") as Label


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	if label != null:
		label.text = "TARGET %s" % target_id
	_set_visual_state(false)


func hit(_damage := 1, _from := Vector2.ZERO) -> void:
	activate()


func activate() -> void:
	if activated:
		_play_pulse()
		return

	activated = true
	_set_visual_state(true)
	_play_pulse()
	target_activated.emit(self)


func reset_target() -> void:
	activated = false
	_set_visual_state(false)


func _set_visual_state(is_active: bool) -> void:
	if outer_ring != null:
		outer_ring.default_color = active_ring_color if is_active else idle_ring_color
	if core != null:
		core.color = active_core_color if is_active else idle_core_color
	if label != null:
		label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.92, 1.0) if is_active else Color(1.0, 0.82, 0.48, 1.0))


func _play_pulse() -> void:
	if outer_ring == null:
		return
	if _pulse_tween != null:
		_pulse_tween.kill()

	outer_ring.scale = Vector2.ONE
	outer_ring.modulate = Color.WHITE

	_pulse_tween = create_tween()
	_pulse_tween.set_trans(Tween.TRANS_QUAD)
	_pulse_tween.tween_property(outer_ring, "scale", Vector2(1.25, 1.25), 0.08).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(outer_ring, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN_OUT)
