class_name ChapterDoorAnimator
extends Node2D


var _body: Sprite2D
var _status: AnimatedSprite2D
var _direction := "up"
var _is_open := false


func setup(
	texture: Texture2D,
	region: Rect2,
	position_value: Vector2,
	target_size: Vector2,
	tint: Color,
	status_texture: Texture2D,
	status_region: Rect2,
	status_color: Color,
	direction_name: String,
	is_open: bool,
	node_z: int
) -> void:
	_direction = direction_name
	_is_open = is_open
	position = position_value
	z_index = node_z

	if texture != null and region.size.x > 0.0 and region.size.y > 0.0:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		_body = Sprite2D.new()
		_body.name = "DoorMaterialBody"
		_body.texture = atlas
		_body.centered = true
		_body.modulate = tint
		_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_body.scale = _uniform_fit_scale(region.size, target_size)
		_body.rotation = PI * 0.5 if direction_name in ["left", "right"] else 0.0
		_body.z_index = 1
		add_child(_body)

	if status_texture != null and status_region.size.x > 0.0 and status_region.size.y > 0.0:
		_status = AnimatedSprite2D.new()
		_status.name = "DoorMaterialStatusAnimation"
		_status.sprite_frames = _build_status_frames(status_texture, status_region)
		_status.animation = &"portal_status"
		_status.autoplay = &"portal_status"
		_status.speed_scale = 0.55 if is_open else 0.8
		_status.modulate = status_color
		_status.position = _status_position(direction_name, target_size)
		_status.scale = Vector2.ONE * 1.15
		_status.z_index = 3
		add_child(_status)

	_build_door_seam(target_size, direction_name)
	_start_motion()


func _uniform_fit_scale(source_size: Vector2, target_size: Vector2) -> Vector2:
	var factor: float = min(target_size.x / source_size.x, target_size.y / source_size.y)
	return Vector2.ONE * factor


func _build_status_frames(texture: Texture2D, region: Rect2) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"portal_status")
	frames.set_animation_loop(&"portal_status", true)
	frames.set_animation_speed(&"portal_status", 6.0)
	for frame_index in range(6):
		var frame_atlas := AtlasTexture.new()
		frame_atlas.atlas = texture
		frame_atlas.region = Rect2(
			region.position + Vector2(region.size.x * frame_index, 0),
			region.size
		)
		frames.add_frame(&"portal_status", frame_atlas)
	return frames


func _status_position(direction_name: String, target_size: Vector2) -> Vector2:
	var final_size := _final_door_size(target_size, direction_name)
	if direction_name == "left":
		return Vector2(final_size.x * 0.44, 0)
	if direction_name == "right":
		return Vector2(-final_size.x * 0.44, 0)
	if direction_name == "up":
		return Vector2(0, final_size.y * 0.44)
	return Vector2(0, -final_size.y * 0.44)


func _build_door_seam(target_size: Vector2, direction_name: String) -> void:
	var final_size := _final_door_size(target_size, direction_name)
	var seam := Line2D.new()
	seam.name = "DoorMaterialSeam"
	seam.default_color = Color(0.015, 0.025, 0.035, 0.92)
	seam.width = 3.0
	seam.z_index = 2
	if direction_name in ["up", "down"]:
		seam.points = PackedVector2Array([
			Vector2(0, -final_size.y * 0.34),
			Vector2(0, final_size.y * 0.34),
		])
	else:
		seam.points = PackedVector2Array([
			Vector2(-final_size.x * 0.34, 0),
			Vector2(final_size.x * 0.34, 0),
		])
	add_child(seam)


func _final_door_size(target_size: Vector2, direction_name: String) -> Vector2:
	if direction_name in ["left", "right"]:
		return Vector2(target_size.y, target_size.x)
	return target_size


func _start_motion() -> void:
	if _body == null:
		return
	var travel := Vector2.ZERO
	if _is_open:
		if _direction in ["up", "down"]:
			travel = Vector2(0, -4.0 if _direction == "up" else 4.0)
		else:
			travel = Vector2(-4.0 if _direction == "left" else 4.0, 0)
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_body, "position", travel, 1.1 if _is_open else 1.8)
	tween.tween_property(_body, "position", Vector2.ZERO, 1.1 if _is_open else 1.8)
