extends "res://tiny_wizard/enemies/protomatter_drop_enemy.gd"


const BOLT_SCENE := preload("res://tiny_wizard/enemies/quarantine_spitter/quarantine_bolt.tscn")

@export var fire_origin_offset := Vector2(0.0, -48.0)

var _visual_node: Node2D
var _visual_base_scale := Vector2.ONE
var _visual_base_modulate := Color.WHITE
var _visual_tween: Tween


func _ready() -> void:
	super._ready()
	_visual_node = get_node_or_null("Visual") as Node2D
	if _visual_node != null:
		_visual_base_scale = _visual_node.scale
		_visual_base_modulate = _visual_node.modulate


func request_fire(target_position: Vector2) -> void:
	var projectile_parent := _get_drop_parent()
	if projectile_parent == null:
		return

	var origin := global_position + fire_origin_offset
	var direction := origin.direction_to(target_position)
	if direction.length() < 0.01:
		direction = Vector2.RIGHT

	var projectile := BOLT_SCENE.instantiate() as Node2D
	if projectile == null:
		return
	if projectile_parent is Node2D:
		projectile.position = (projectile_parent as Node2D).to_local(origin)
	else:
		projectile.global_position = origin
	projectile.call("setup", direction)
	projectile_parent.call_deferred("add_child", projectile)


func play_fire_windup(target_position: Vector2, duration: float) -> void:
	if _visual_node != null:
		if _visual_tween != null:
			_visual_tween.kill()
		_visual_tween = create_tween()
		_visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_visual_tween.tween_property(_visual_node, "scale", _visual_base_scale * 1.14, duration)
		_visual_tween.parallel().tween_property(_visual_node, "modulate", Color(1.0, 0.78, 0.28, 1.0), duration)

	var direction := global_position.direction_to(target_position)
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	var warning := Line2D.new()
	warning.name = "射击预警"
	warning.z_index = -1
	warning.width = 3.0
	warning.default_color = Color(1.0, 0.52, 0.12, 0.78)
	warning.points = PackedVector2Array([
		fire_origin_offset,
		fire_origin_offset + direction.normalized() * 300.0,
	])
	add_child(warning)
	var warning_tween := warning.create_tween()
	warning_tween.tween_property(warning, "modulate", Color(1.0, 0.82, 0.35, 0.12), maxf(0.08, duration))
	warning_tween.tween_callback(warning.queue_free)


func finish_attack_visual() -> void:
	if _visual_node == null:
		return
	if _visual_tween != null:
		_visual_tween.kill()
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(_visual_node, "scale", _visual_base_scale, 0.14)
	_visual_tween.parallel().tween_property(_visual_node, "modulate", _visual_base_modulate, 0.14)
