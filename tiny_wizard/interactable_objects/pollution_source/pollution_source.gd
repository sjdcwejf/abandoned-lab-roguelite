class_name LabPollutionSource
extends StaticBody2D


signal pollution_source_destroyed(source: Node)

const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")

@export var max_health := 6
@export var display_name := "原质污染源"

var _health := 0
var _destroyed := false
var _flash_tween: Tween

@onready var outer_ring: Line2D = get_node_or_null("OuterRing") as Line2D
@onready var core: Polygon2D = get_node_or_null("Core") as Polygon2D
@onready var glow: Polygon2D = get_node_or_null("Glow") as Polygon2D
@onready var label: Label = get_node_or_null("Label") as Label
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	_health = max_health
	if label != null:
		label.text = display_name
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	_update_visual()


func hit(damage := 1, from := Vector2.ZERO) -> void:
	if _destroyed:
		return

	var amount := maxi(1, int(damage))
	_health = maxi(0, _health - amount)
	_play_hit_feedback(from)
	_update_visual()
	if _health <= 0:
		_destroy()


func _destroy() -> void:
	if _destroyed:
		return

	_destroyed = true
	pollution_source_destroyed.emit(self)
	collision_layer = 0
	collision_mask = 0
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if label != null:
		label.text = "污染源清除"

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(1.22, 1.22), 0.08).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color(0.4, 1.0, 0.64, 0.85), 0.08)
	tween.tween_property(self, "scale", Vector2(0.08, 0.08), 0.18).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate", Color(0.4, 1.0, 0.64, 0.0), 0.18)
	tween.finished.connect(queue_free)


func _update_visual() -> void:
	var health_ratio := 1.0
	if max_health > 0:
		health_ratio = clampf(float(_health) / float(max_health), 0.0, 1.0)

	if outer_ring != null:
		outer_ring.default_color = Color(0.28, 1.0, 0.58, 0.92).lerp(Color(0.98, 0.25, 0.45, 0.96), 1.0 - health_ratio)
	if core != null:
		core.color = Color(0.68, 0.15, 0.95, 1.0).lerp(Color(0.2, 1.0, 0.52, 1.0), health_ratio)
	if glow != null:
		glow.color = Color(0.16, 0.95, 0.42, 0.18 + health_ratio * 0.28)


func _play_hit_feedback(from: Vector2) -> void:
	if _flash_tween != null:
		_flash_tween.kill()

	var recoil := Vector2.ZERO
	if from.length() > 0.01:
		recoil = from.normalized() * 4.0

	position += recoil
	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_QUAD)
	_flash_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.04)
	_flash_tween.tween_property(self, "position", position - recoil, 0.08).set_ease(Tween.EASE_OUT)
	_flash_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.08)
