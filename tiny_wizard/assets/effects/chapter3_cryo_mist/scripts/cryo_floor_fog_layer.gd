class_name CryoFloorFogLayer
extends Node2D


const NOISE_TEXTURE: Texture2D = preload("res://tiny_wizard/assets/effects/chapter3_cryo_mist/noise/Noiselong.png")

@export var fog_size := Vector2(520, 92)
@export var alpha := 0.1
@export var drift := Vector2(18, -2)
@export var drift_seconds := 10.0
@export var tint := Color(0.9, 0.97, 1.0, 1.0)

var _sprites: Array[Sprite2D] = []


func _ready() -> void:
	_build_sprites()
	_start_motion()


func configure(size_value: Vector2, alpha_value: float, drift_value: Vector2, tint_value: Color, seconds_value: float) -> void:
	fog_size = size_value
	alpha = alpha_value
	drift = drift_value
	tint = tint_value
	drift_seconds = seconds_value
	if is_inside_tree():
		_apply_sprite_settings()


func _build_sprites() -> void:
	for child in get_children():
		child.queue_free()
	_sprites.clear()
	_sprites.append(_make_fog_sprite("GroundFogA", Vector2.ZERO, alpha))
	_sprites.append(_make_fog_sprite("GroundFogB", Vector2(fog_size.x * 0.22, 4), alpha * 0.55))
	_apply_sprite_settings()


func _make_fog_sprite(node_name: String, offset: Vector2, local_alpha: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = NOISE_TEXTURE
	sprite.centered = true
	sprite.position = offset
	sprite.modulate = Color(tint.r, tint.g, tint.b, local_alpha)
	sprite.z_index = 0
	add_child(sprite)
	return sprite


func _apply_sprite_settings() -> void:
	if NOISE_TEXTURE == null:
		return
	var texture_size := NOISE_TEXTURE.get_size()
	var scale_value := Vector2(fog_size.x / texture_size.x, fog_size.y / texture_size.y)
	for index in range(_sprites.size()):
		var sprite := _sprites[index]
		sprite.scale = scale_value
		var local_alpha := alpha if index == 0 else alpha * 0.55
		sprite.modulate = Color(tint.r, tint.g, tint.b, local_alpha)


func _start_motion() -> void:
	if _sprites.is_empty():
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_sprites[0], "position", drift, drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_sprites[0], "modulate:a", alpha * 0.45, drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_sprites[1], "position", Vector2(fog_size.x * 0.22, 4) - drift * 0.65, drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_sprites[1], "modulate:a", alpha * 0.35, drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_sprites[0], "position", Vector2.ZERO, drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_sprites[0], "modulate:a", alpha, drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_sprites[1], "position", Vector2(fog_size.x * 0.22, 4), drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_sprites[1], "modulate:a", alpha * 0.55, drift_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
