class_name ChapterDoorVisuals
extends Node2D


const ChapterDoorThemeScript: Script = preload("res://tiny_wizard/room/chapter_door_theme.gd")

const VISUAL_Z := -1
const DOOR_DIRECTIONS: Array[Dictionary] = [
	{
		"name": "right",
		"hidden_property": "hide_right_door",
		"center": Vector2(952, 300),
		"door_size": Vector2(72, 190),
		"sealed_size": Vector2(88, 314),
		"status_offset": Vector2(-30, 0),
	},
	{
		"name": "down",
		"hidden_property": "hide_down_door",
		"center": Vector2(512, 506),
		"door_size": Vector2(208, 74),
		"sealed_size": Vector2(362, 88),
		"status_offset": Vector2(0, -30),
	},
	{
		"name": "left",
		"hidden_property": "hide_left_door",
		"center": Vector2(72, 300),
		"door_size": Vector2(72, 190),
		"sealed_size": Vector2(88, 314),
		"status_offset": Vector2(30, 0),
	},
	{
		"name": "up",
		"hidden_property": "hide_up_door",
		"center": Vector2(512, 94),
		"door_size": Vector2(208, 74),
		"sealed_size": Vector2(362, 88),
		"status_offset": Vector2(0, 30),
	},
]


func _ready() -> void:
	z_as_relative = false
	z_index = VISUAL_Z
	y_sort_enabled = false


func refresh_for_room(room: Node) -> void:
	if room == null:
		return
	_clear_visuals()
	_hide_placeholder_door_sprites(room)

	var chapter_id := int(room.get_meta("chapter_id", 1))
	var theme: Dictionary = ChapterDoorThemeScript.get_theme(chapter_id)
	var state: String = ChapterDoorThemeScript.resolve_door_state(room)
	var state_key: String = ChapterDoorThemeScript.get_state_asset_key(state)

	for direction_value in DOOR_DIRECTIONS:
		var direction: Dictionary = direction_value
		if bool(room.get(str(direction["hidden_property"]))):
			_draw_sealed_wall(direction, theme.get("sealed_wall", {}))
		else:
			_draw_door(direction, theme.get(state_key, theme.get("normal_door", {})), state)


func _clear_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _hide_placeholder_door_sprites(room: Node) -> void:
	var room_walls := room.get_node_or_null("RoomWalls")
	if room_walls == null:
		return
	for door_name in ["RightDoor", "DownDoor", "LeftDoor", "UpDoor"]:
		var door := room_walls.get_node_or_null(door_name)
		if door is CanvasItem:
			(door as CanvasItem).visible = false


func _draw_door(direction: Dictionary, spec: Dictionary, state: String) -> void:
	if spec.is_empty():
		return

	var center: Vector2 = direction.get("center", Vector2.ZERO) as Vector2
	var base_size: Vector2 = direction.get("door_size", Vector2(160, 72)) as Vector2
	var size := base_size * float(spec.get("scale_multiplier", 1.0))
	var direction_name := str(direction.get("name", "up"))
	var tint: Color = spec.get("tint", Color.WHITE) as Color
	var status_color: Color = spec.get("status_color", Color.WHITE) as Color

	_add_rect("ChapterDoorRecess", center, size + _frame_extra(direction_name), Color(0.025, 0.03, 0.036, 0.82), VISUAL_Z)
	_add_atlas_sprite(
		"ChapterDoorBody_%s" % str(spec.get("asset_name", "door")),
		spec.get("texture", null),
		spec.get("region", Rect2()),
		center,
		size,
		tint,
		VISUAL_Z + 1
	)
	_draw_door_frame(direction_name, center, size, tint)
	_draw_status_light(direction, spec, status_color)

	if bool(spec.get("locked", false)) or state in [ChapterDoorThemeScript.STATE_COMBAT_LOCKED, ChapterDoorThemeScript.STATE_EVENT_LOCKED]:
		_draw_lock_bars(direction_name, center, size, spec, status_color)
	if bool(spec.get("corrupted", false)):
		_draw_hive_corruption(direction_name, center, size)


func _draw_sealed_wall(direction: Dictionary, spec: Dictionary) -> void:
	if spec.is_empty():
		return

	var center: Vector2 = direction.get("center", Vector2.ZERO) as Vector2
	var size: Vector2 = direction.get("sealed_size", Vector2(320, 80)) as Vector2
	var direction_name := str(direction.get("name", "up"))
	var tint: Color = spec.get("tint", Color.WHITE) as Color

	_add_rect("ChapterSealedWallBacker", center, size + Vector2(16, 14), Color(0.025, 0.03, 0.035, 0.92), VISUAL_Z)
	_add_atlas_sprite(
		"ChapterSealedWall_%s" % str(spec.get("asset_name", "sealed_wall")),
		spec.get("texture", null),
		spec.get("region", Rect2()),
		center,
		size,
		tint,
		VISUAL_Z + 1
	)
	_draw_sealed_wall_modules(direction_name, center, size, spec)
	if bool(spec.get("corrupted", false)):
		_draw_hive_corruption(direction_name, center, size * 0.88, 0.18)


func _draw_door_frame(direction_name: String, center: Vector2, size: Vector2, tint: Color) -> void:
	var frame_color := Color(tint.r * 0.42, tint.g * 0.42, tint.b * 0.42, 0.88)
	var edge_color := Color(tint.r * 0.72, tint.g * 0.72, tint.b * 0.72, 0.42)
	if direction_name in ["up", "down"]:
		_add_rect("ChapterDoorFrameTop", center + Vector2(0, -size.y * 0.44), Vector2(size.x + 22, 7), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorFrameBottom", center + Vector2(0, size.y * 0.44), Vector2(size.x + 22, 7), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorFrameLeft", center + Vector2(-size.x * 0.52, 0), Vector2(8, size.y + 16), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorFrameRight", center + Vector2(size.x * 0.52, 0), Vector2(8, size.y + 16), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorThreshold", center + Vector2(0, 0), Vector2(size.x * 0.58, 3), edge_color, VISUAL_Z + 3)
	else:
		_add_rect("ChapterDoorFrameLeft", center + Vector2(-size.x * 0.44, 0), Vector2(7, size.y + 22), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorFrameRight", center + Vector2(size.x * 0.44, 0), Vector2(7, size.y + 22), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorFrameTop", center + Vector2(0, -size.y * 0.52), Vector2(size.x + 16, 8), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorFrameBottom", center + Vector2(0, size.y * 0.52), Vector2(size.x + 16, 8), frame_color, VISUAL_Z + 2)
		_add_rect("ChapterDoorThreshold", center + Vector2(0, 0), Vector2(3, size.y * 0.58), edge_color, VISUAL_Z + 3)


func _draw_status_light(direction: Dictionary, spec: Dictionary, status_color: Color) -> void:
	var center: Vector2 = direction.get("center", Vector2.ZERO) as Vector2
	var offset: Vector2 = direction.get("status_offset", Vector2.ZERO) as Vector2
	_add_atlas_sprite(
		"ChapterDoorStatusLight_%s" % str(spec.get("asset_name", "door")),
		spec.get("status_texture", null),
		spec.get("status_region", Rect2(0, 0, 16, 16)),
		center + offset,
		Vector2(20, 20),
		status_color,
		VISUAL_Z + 4
	)


func _draw_lock_bars(direction_name: String, center: Vector2, size: Vector2, spec: Dictionary, status_color: Color) -> void:
	var bar_texture: Texture2D = spec.get("status_texture", null)
	var bar_region: Rect2 = spec.get("status_region", Rect2(0, 0, 16, 16)) as Rect2
	var bar_color := Color(status_color.r, status_color.g, status_color.b, 0.82)
	if direction_name in ["up", "down"]:
		for y_offset in [-size.y * 0.22, size.y * 0.22]:
			_add_atlas_sprite("ChapterDoorLockBar", bar_texture, bar_region, center + Vector2(0, y_offset), Vector2(size.x * 0.64, 8), bar_color, VISUAL_Z + 5)
	else:
		for x_offset in [-size.x * 0.22, size.x * 0.22]:
			_add_atlas_sprite("ChapterDoorLockBar", bar_texture, bar_region, center + Vector2(x_offset, 0), Vector2(8, size.y * 0.64), bar_color, VISUAL_Z + 5)


func _draw_sealed_wall_modules(direction_name: String, center: Vector2, size: Vector2, spec: Dictionary) -> void:
	var texture: Texture2D = spec.get("texture", null)
	var region: Rect2 = spec.get("region", Rect2()) as Rect2
	var tint: Color = spec.get("tint", Color.WHITE) as Color
	var module_color := Color(tint.r * 0.82, tint.g * 0.82, tint.b * 0.82, 0.7)
	if direction_name in ["up", "down"]:
		for x_offset in [-size.x * 0.32, 0.0, size.x * 0.32]:
			_add_atlas_sprite("ChapterSealedWallModule", texture, region, center + Vector2(x_offset, 0), Vector2(size.x * 0.26, size.y * 0.76), module_color, VISUAL_Z + 2)
	else:
		for y_offset in [-size.y * 0.32, 0.0, size.y * 0.32]:
			_add_atlas_sprite("ChapterSealedWallModule", texture, region, center + Vector2(0, y_offset), Vector2(size.x * 0.76, size.y * 0.24), module_color, VISUAL_Z + 2)


func _draw_hive_corruption(direction_name: String, center: Vector2, size: Vector2, alpha := 0.26) -> void:
	var purple := Color(0.32, 0.08, 0.38, alpha)
	var red := Color(0.7, 0.08, 0.08, alpha * 0.78)
	if direction_name in ["up", "down"]:
		_add_line("FinalHiveDoorCorruptionA", PackedVector2Array([
			center + Vector2(-size.x * 0.48, -size.y * 0.25),
			center + Vector2(-size.x * 0.12, size.y * 0.12),
			center + Vector2(size.x * 0.42, size.y * 0.28),
		]), purple, 3.0, VISUAL_Z + 6)
		_add_rect("FinalHiveDoorPulse", center + Vector2(size.x * 0.24, 0), Vector2(8, 8), red, VISUAL_Z + 7)
	else:
		_add_line("FinalHiveDoorCorruptionA", PackedVector2Array([
			center + Vector2(-size.x * 0.24, -size.y * 0.46),
			center + Vector2(size.x * 0.12, -size.y * 0.10),
			center + Vector2(size.x * 0.24, size.y * 0.42),
		]), purple, 3.0, VISUAL_Z + 6)
		_add_rect("FinalHiveDoorPulse", center + Vector2(0, size.y * 0.22), Vector2(8, 8), red, VISUAL_Z + 7)


func _frame_extra(direction_name: String) -> Vector2:
	if direction_name in ["up", "down"]:
		return Vector2(28, 18)
	return Vector2(18, 28)


func _add_atlas_sprite(
	node_name: String,
	texture: Texture2D,
	region: Rect2,
	position: Vector2,
	target_size: Vector2,
	modulate_color: Color,
	node_z: int
) -> void:
	if texture == null:
		return
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return

	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region

	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = atlas
	sprite.centered = true
	sprite.position = position
	sprite.scale = Vector2(target_size.x / region.size.x, target_size.y / region.size.y)
	sprite.modulate = modulate_color
	sprite.z_index = node_z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)


func _add_rect(node_name: String, center: Vector2, size: Vector2, color: Color, node_z: int) -> void:
	var rect := Polygon2D.new()
	rect.name = node_name
	rect.color = color
	rect.z_index = node_z
	var half := size * 0.5
	rect.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(rect)


func _add_line(node_name: String, points: PackedVector2Array, color: Color, width: float, node_z: int) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.z_index = node_z
	add_child(line)
