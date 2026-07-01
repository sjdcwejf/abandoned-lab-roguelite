class_name LabCryoZone
extends Area2D


const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const THERMAL_LINING_RELIC := &"thermal_lining"

@export var player_slow_multiplier := 0.6
@export var enemy_slow_multiplier := 0.7
@export var status_refresh_interval := 0.18
@export var status_duration := 0.36
@export var duration := 0.0
@export var radius := 58.0
@export var rect_size := Vector2(128.0, 82.0)
@export var use_rectangle_shape := true
@export var show_player_feedback := true
@export var enter_message := "移动速度降低"
@export var exit_message := "低温影响解除"

var _tracked_bodies: Array[Node] = []
var _refresh_timer := 0.0
var _life_timer := 0.0
var _has_shown_enter_feedback := false
var _has_shown_exit_feedback := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 10
	monitoring = true
	monitorable = false
	_life_timer = duration
	_setup_collision_shape()
	_build_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_physics_process(true)


func setup_circle(new_radius: float, lifetime := 0.0) -> void:
	use_rectangle_shape = false
	radius = maxf(12.0, new_radius)
	duration = lifetime
	_life_timer = duration
	if is_inside_tree():
		_setup_collision_shape()
		_rebuild_visual()


func setup_rect(new_size: Vector2, lifetime := 0.0) -> void:
	use_rectangle_shape = true
	rect_size = Vector2(maxf(24.0, new_size.x), maxf(24.0, new_size.y))
	duration = lifetime
	_life_timer = duration
	if is_inside_tree():
		_setup_collision_shape()
		_rebuild_visual()


func _physics_process(delta: float) -> void:
	if duration > 0.0:
		_life_timer -= delta
		if _life_timer <= 0.0:
			queue_free()
			return

	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = status_refresh_interval
	_prune_tracked_bodies()
	for body in _tracked_bodies:
		_apply_cryo_slow(body)


func _on_body_entered(body: Node) -> void:
	if body == null or _tracked_bodies.has(body):
		return
	if not _can_apply_to_body(body):
		return
	_tracked_bodies.append(body)
	_apply_cryo_slow(body)
	if show_player_feedback and _is_player_body(body) and not _has_shown_enter_feedback:
		_has_shown_enter_feedback = true
		_show_world_message(body, enter_message, Color(0.62, 0.92, 1.0, 1.0))


func _on_body_exited(body: Node) -> void:
	_tracked_bodies.erase(body)
	if show_player_feedback and _is_player_body(body) and not _has_shown_exit_feedback:
		_has_shown_exit_feedback = true
		_show_world_message(body, exit_message, Color(0.82, 1.0, 1.0, 1.0))


func _apply_cryo_slow(body: Node) -> void:
	if not _can_apply_to_body(body):
		return
	var multiplier := enemy_slow_multiplier
	if _is_player_body(body):
		multiplier = _get_player_slow_multiplier(body)
	LabStatusEffectController.apply_slow(body, status_duration, multiplier)


func _get_player_slow_multiplier(body: Node) -> float:
	var multiplier := player_slow_multiplier
	var relic_controller := body.get_node_or_null("RelicController") as RelicController
	if relic_controller != null and relic_controller.has_relic(THERMAL_LINING_RELIC):
		var slow_strength := 1.0 - multiplier
		multiplier = 1.0 - slow_strength * 0.5
	return clampf(multiplier, 0.05, 1.0)


func _can_apply_to_body(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if not ("physics_stats" in body):
		return false
	return body.get("physics_stats") != null


func _is_player_body(body: Node) -> bool:
	return body != null and body.has_node("Visual/WeaponHolder")


func _prune_tracked_bodies() -> void:
	for index in range(_tracked_bodies.size() - 1, -1, -1):
		var body := _tracked_bodies[index]
		if body == null or not is_instance_valid(body):
			_tracked_bodies.remove_at(index)


func _setup_collision_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)
	if use_rectangle_shape:
		var rect := RectangleShape2D.new()
		rect.size = rect_size
		shape_node.shape = rect
	else:
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape_node.shape = circle


func _build_visual() -> void:
	var base := Polygon2D.new()
	base.name = "CryoFog"
	base.z_index = -1
	base.color = Color(0.36, 0.78, 1.0, 0.22)
	base.polygon = _rect_points(rect_size) if use_rectangle_shape else _circle_points(radius, 28)
	add_child(base)

	var rim := Line2D.new()
	rim.name = "CryoRim"
	rim.z_index = 1
	rim.width = 3.0
	rim.closed = true
	rim.default_color = Color(0.58, 0.94, 1.0, 0.78)
	rim.points = _rect_line_points(rect_size) if use_rectangle_shape else _circle_points(radius, 32)
	add_child(rim)

	var mist := Line2D.new()
	mist.name = "ColdMist"
	mist.z_index = 2
	mist.width = 2.0
	mist.default_color = Color(0.86, 0.98, 1.0, 0.36)
	mist.points = PackedVector2Array([
		Vector2(-rect_size.x * 0.42, -6.0),
		Vector2(-rect_size.x * 0.18, -12.0),
		Vector2(rect_size.x * 0.08, -2.0),
		Vector2(rect_size.x * 0.36, -10.0),
	])
	add_child(mist)


func _rebuild_visual() -> void:
	for child in get_children():
		if child is Polygon2D or child is Line2D:
			child.queue_free()
	_build_visual()


func _show_world_message(target: Node, text: String, color: Color) -> void:
	if text == "" or not target is Node2D:
		return
	var parent := get_tree().current_scene
	if parent == null:
		return
	var label := Label.new()
	label.name = "CryoFeedback"
	label.text = text
	label.z_index = 90
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(label)
	var target_pos := (target as Node2D).global_position + Vector2(-58.0, -84.0)
	label.global_position = target_pos
	var tween := label.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position", target_pos + Vector2(0.0, -22.0), 0.85)
	tween.parallel().tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.85)
	tween.tween_callback(label.queue_free)


func _rect_points(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _rect_line_points(size: Vector2) -> PackedVector2Array:
	return _rect_points(size)


func _circle_points(circle_radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var final_count := maxi(8, count)
	for index in range(final_count):
		var angle := TAU * float(index) / float(final_count)
		points.append(Vector2.from_angle(angle) * circle_radius)
	return points
