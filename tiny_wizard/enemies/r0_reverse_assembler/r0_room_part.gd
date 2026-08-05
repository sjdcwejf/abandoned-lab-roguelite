extends Area2D


signal retract_started(part: Node)
signal absorption_completed(part: Node)
signal absorption_interrupted(part: Node)
signal part_destroyed(part: Node)

@export var part_id: StringName = &"left_rivet"
@export var max_life := 5

var _current_life := 5
var _absorbing := false
var _destroyed := false
var _absorption_target := Vector2.ZERO
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE


func _ready() -> void:
	_current_life = max_life
	_base_position = global_position
	_base_scale = scale
	collision_layer = 8
	collision_mask = 0
	monitoring = true
	monitorable = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func hit(damage := 1, _from := Vector2.ZERO) -> void:
	if _destroyed:
		return
	_current_life -= maxi(1, int(damage))
	modulate = Color(1.0, 0.45, 0.32, 1.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color.WHITE, 0.12)
	if _current_life > 0:
		return

	_destroyed = true
	collision_layer = 0
	monitoring = false
	part_destroyed.emit(self)
	var fade := create_tween()
	fade.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade.tween_property(self, "scale", _base_scale * 0.45, 0.16)
	fade.parallel().tween_property(self, "modulate", Color(0.7, 0.8, 0.78, 0.0), 0.16)
	fade.tween_callback(queue_free)


func begin_absorption(target_position: Vector2) -> bool:
	if _destroyed or _absorbing:
		return false
	_absorbing = true
	_absorption_target = target_position
	_retract_source_collision_same_tick()
	retract_started.emit(self)

	var move := create_tween()
	move.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	move.tween_property(self, "global_position", target_position, 1.2)
	move.parallel().tween_property(self, "scale", _base_scale * 0.62, 1.2)
	move.parallel().tween_property(self, "rotation", rotation + TAU * 1.5, 1.2)
	move.tween_callback(_finish_absorption)
	return true


func _retract_source_collision_same_tick() -> void:
	# The room blocker is released as the module starts moving, so the player
	# cannot be trapped by a visual retract animation.
	collision_layer = 8


func _finish_absorption() -> void:
	if _destroyed:
		return
	_absorbing = false
	absorption_completed.emit(self)
	queue_free()


func _draw() -> void:
	var steel := Color(0.16, 0.18, 0.18, 1.0)
	var light_steel := Color(0.58, 0.60, 0.56, 1.0)
	var dark := Color(0.035, 0.045, 0.047, 1.0)
	var cyan := Color(0.18, 0.86, 0.90, 1.0)
	var amber := Color(0.92, 0.54, 0.16, 1.0)

	draw_rect(Rect2(-22, 10, 44, 6), Color(0.01, 0.012, 0.012, 0.55), true)
	match part_id:
		&"left_rivet":
			draw_rect(Rect2(-22, -7, 44, 12), dark, true)
			draw_rect(Rect2(-20, -5, 40, 8), steel, true)
			draw_circle(Vector2(-13, -1), 7.0, light_steel)
			draw_circle(Vector2(-13, -1), 3.0, dark)
			draw_line(Vector2(-4, -1), Vector2(18, -1), amber, 3.0)
			draw_rect(Rect2(10, -6, 7, 4), cyan, true)
		&"right_plate":
			draw_rect(Rect2(-17, -12, 34, 24), dark, true)
			draw_polygon(PackedVector2Array([
				Vector2(-12, -9), Vector2(11, -9), Vector2(16, -3),
				Vector2(12, 10), Vector2(-12, 10), Vector2(-16, 3),
			]), PackedColorArray([light_steel]))
			draw_line(Vector2(-9, -5), Vector2(9, -5), dark, 2.0)
			draw_line(Vector2(-6, 4), Vector2(8, 4), amber, 3.0)
			draw_rect(Rect2(-4, -1, 8, 3), cyan, true)
		&"north_rotor":
			draw_rect(Rect2(-20, -7, 40, 14), dark, true)
			draw_circle(Vector2.ZERO, 12.0, steel)
			draw_circle(Vector2.ZERO, 5.0, dark)
			for index in range(4):
				var rotor_angle := TAU * float(index) / 4.0
				draw_line(Vector2.from_angle(rotor_angle) * 5.0, Vector2.from_angle(rotor_angle) * 12.0, light_steel, 3.0)
			draw_rect(Rect2(-3, -2, 6, 4), cyan, true)
			draw_rect(Rect2(-18, 8, 36, 3), amber, true)
