class_name LabSleepPod
extends Node2D


@export var character_id := ""
@export var pod_label := "休眠仓"
@export var accent_color := Color(0.35, 0.85, 0.95, 1.0)

var _is_open := false
var _wake_tween: Tween

@onready var chamber: Node2D = $Chamber
@onready var glass: Polygon2D = $Chamber/Glass
@onready var occupant: CanvasItem = $Chamber/Occupant
@onready var status_light: Polygon2D = $Chamber/StatusLight
@onready var label: Label = $Label
@onready var wake_point: Marker2D = $WakePoint


func _ready() -> void:
	label.text = pod_label
	status_light.color = accent_color
	glass.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.34)


func wake_up() -> void:
	if _is_open:
		return
	_is_open = true

	if _wake_tween != null:
		_wake_tween.kill()

	status_light.color = Color(0.55, 1.0, 0.42, 1.0)
	occupant.visible = false

	_wake_tween = create_tween()
	_wake_tween.set_trans(Tween.TRANS_QUAD)
	_wake_tween.tween_property(chamber, "rotation", -0.12, 0.14).set_ease(Tween.EASE_OUT)
	_wake_tween.parallel().tween_property(glass, "modulate", Color(1, 1, 1, 0.28), 0.14).set_ease(Tween.EASE_OUT)


func get_wake_position() -> Vector2:
	return wake_point.global_position


func is_open() -> bool:
	return _is_open
