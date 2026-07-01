extends SceneTree

const IMAGE_SIZE := Vector2i(1600, 900)
const OUTPUT_PATH := "res://docs/previews/chapter2_greenhouse_quarantine_entry_impl_godot.png"


class GreenhouseEntryCanvas:
	extends Node2D

	const BG := Color("#071012")
	const WALL_DARK := Color("#071012")
	const WALL_OUTER := Color("#121b1f")
	const WALL_MID := Color("#2c363b")
	const WALL_LIT := Color("#536068")
	const FLOOR_A := Color("#182326")
	const FLOOR_B := Color("#1b282b")
	const FLOOR_LINE := Color("#2d3b40")
	const CYAN := Color("#46dfe8")
	const CYAN_DIM := Color("#1d8791")
	const AMBER := Color("#c47a22")
	const AMBER_DARK := Color("#5e3d18")
	const GREEN_DARK := Color("#1d3325")
	const GREEN_MID := Color("#35593a")
	const GREEN_LEAF := Color("#5f7f4a")
	const GLASS := Color("#22464b")
	const GLASS_LIGHT := Color("#79f4e8")

	var font: Font

	func _ready() -> void:
		font = _load_preview_font()
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(IMAGE_SIZE)), BG)

		var room := Rect2(Vector2(108, 82), Vector2(1384, 734))
		var floor := Rect2(Vector2(190, 164), Vector2(1220, 570))

		_draw_drop_shadow(room)
		_draw_room_shell(room)
		_draw_floor(floor)
		_draw_wall_equipment(room, floor)
		_draw_doors(room, floor)
		_draw_main_quarantine_mark(floor)
		_draw_containment_props(floor)
		_draw_terminal_and_signage(floor)
		_draw_controlled_overgrowth(room, floor)
		_draw_final_lighting(room, floor)

	func _load_preview_font() -> Font:
		var font_file := FontFile.new()
		if font_file.load_dynamic_font("/System/Library/Fonts/Hiragino Sans GB.ttc") == OK:
			return font_file
		if font_file.load_dynamic_font("/System/Library/Fonts/STHeiti Medium.ttc") == OK:
			return font_file
		return ThemeDB.fallback_font

	func _draw_drop_shadow(room: Rect2) -> void:
		for i in range(14):
			draw_rect(
				room.grow(16 + i * 8),
				Color(0, 0, 0, 0.030),
				false,
				10.0
			)

	func _draw_room_shell(room: Rect2) -> void:
		draw_rect(room.grow(12), Color("#05090a"))
		draw_rect(room, WALL_OUTER)
		draw_rect(room.grow(-12), WALL_LIT)
		draw_rect(room.grow(-18), WALL_MID)
		draw_rect(room.grow(-46), Color("#151f23"))
		draw_rect(room.grow(-76), Color("#10191c"))

		# Strong bevels make the room read as a real Godot top-down tile space.
		draw_line(room.position + Vector2(10, 10), Vector2(room.end.x - 10, room.position.y + 10), Color("#65717a"), 4.0)
		draw_line(room.position + Vector2(10, 10), Vector2(room.position.x + 10, room.end.y - 10), Color("#4f5c64"), 4.0)
		draw_line(Vector2(room.position.x + 12, room.end.y - 12), room.end - Vector2(12, 12), Color("#05090a"), 5.0)
		draw_line(Vector2(room.end.x - 12, room.position.y + 12), room.end - Vector2(12, 12), Color("#05090a"), 5.0)

		for p in [
			room.position + Vector2(38, 38),
			Vector2(room.end.x - 78, room.position.y + 38),
			Vector2(room.position.x + 38, room.end.y - 78),
			room.end - Vector2(78, 78),
		]:
			draw_rect(Rect2(p, Vector2(40, 40)), Color("#3b464c"))
			draw_rect(Rect2(p + Vector2(10, 10), Vector2(20, 20)), Color("#0a1012"))

	func _draw_floor(floor: Rect2) -> void:
		draw_rect(floor, FLOOR_A)
		var tile := 64
		for x in range(int(floor.position.x), int(floor.end.x), tile):
			for y in range(int(floor.position.y), int(floor.end.y), tile):
				var rect := Rect2(Vector2(x, y), Vector2(tile - 2, tile - 2))
				var shade := FLOOR_A if ((x + y) / tile) % 2 == 0 else FLOOR_B
				draw_rect(rect, shade)
				draw_rect(rect, FLOOR_LINE, false, 1.0)
				if int((x - floor.position.x) / tile + (y - floor.position.y) / tile) % 5 == 0:
					draw_line(rect.position + Vector2(12, rect.size.y - 15), rect.position + Vector2(rect.size.x - 14, 14), Color("#334348", 0.28), 1.0)

		# Clean technical routing lines, not random decoration.
		var c := floor.get_center()
		draw_line(Vector2(c.x, floor.position.y + 30), Vector2(c.x, floor.end.y - 30), Color("#1c8d96", 0.38), 2.0)
		draw_line(Vector2(floor.position.x + 112, c.y), Vector2(c.x - 270, c.y), Color("#8e621e", 0.42), 2.0)
		draw_line(Vector2(c.x + 270, c.y), Vector2(floor.end.x - 112, c.y), Color("#8e621e", 0.42), 2.0)

	func _draw_wall_equipment(room: Rect2, floor: Rect2) -> void:
		for i in range(7):
			var x := floor.position.x + 74 + i * 165
			_draw_wall_panel(Rect2(Vector2(x, room.position.y + 38), Vector2(96, 42)), i)
			_draw_wall_panel(Rect2(Vector2(x, room.end.y - 80), Vector2(96, 42)), i + 2)

		_draw_side_light_stack(Vector2(room.position.x + 36, room.position.y + 180), false)
		_draw_side_light_stack(Vector2(room.end.x - 64, room.position.y + 180), true)
		_draw_warning_plate(Vector2(room.end.x - 230, room.position.y + 122))
		_draw_grate(Rect2(floor.position + Vector2(430, 448), Vector2(120, 58)))
		_draw_grate(Rect2(Vector2(floor.end.x - 496, floor.position.y + 76), Vector2(120, 58)))

	func _draw_wall_panel(rect: Rect2, index: int) -> void:
		draw_rect(rect, Color("#151f22"))
		draw_rect(rect.grow(-4), Color("#263138"))
		var accent := CYAN if index % 3 == 0 else AMBER
		draw_line(rect.position + Vector2(14, 12), rect.position + Vector2(rect.size.x - 14, 12), accent, 2.0)
		draw_line(rect.position + Vector2(18, rect.size.y - 10), rect.position + Vector2(rect.size.x - 18, rect.size.y - 10), Color("#071011"), 2.0)

	func _draw_side_light_stack(pos: Vector2, right: bool) -> void:
		for i in range(2):
			var rect := Rect2(pos + Vector2(0, i * 204), Vector2(28, 132))
			draw_rect(rect.grow(8), Color("#091011"))
			draw_rect(rect, Color("#16272c"))
			draw_rect(rect.grow(-7), Color("#28515a"))
			draw_rect(Rect2(rect.position + Vector2(9, 24), Vector2(10, 84)), CYAN)
			var stripe_x := rect.position.x - 18 if right else rect.end.x + 8
			_draw_hazard_stripes(Rect2(Vector2(stripe_x, rect.position.y + 12), Vector2(14, rect.size.y - 24)), true)

	func _draw_doors(room: Rect2, floor: Rect2) -> void:
		var c := room.get_center()
		_draw_horizontal_door(Rect2(Vector2(c.x - 128, room.position.y + 8), Vector2(256, 72)), "温室封存门")
		_draw_horizontal_door(Rect2(Vector2(c.x - 128, room.end.y - 80), Vector2(256, 72)), "返回前哨")
		_draw_vertical_door(Rect2(Vector2(room.position.x + 8, c.y - 118), Vector2(72, 236)))
		_draw_vertical_door(Rect2(Vector2(room.end.x - 80, c.y - 118), Vector2(72, 236)))

		draw_string(font, Vector2(c.x - 84, room.position.y + 112), "BIOLOCK / 检疫锁", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#68ced0", 0.78))
		draw_line(Vector2(c.x - 130, room.position.y + 100), Vector2(c.x + 130, room.position.y + 100), Color("#2ed9df", 0.45), 2.0)
		draw_string(font, Vector2(c.x - 80, room.end.y - 100), "QUARANTINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#68ced0", 0.70))

	func _draw_horizontal_door(rect: Rect2, _label: String) -> void:
		draw_rect(rect.grow(9), Color("#05090a"))
		draw_rect(rect, Color("#161c20"))
		draw_rect(rect.grow(-8), Color("#343a3d"))
		draw_rect(rect.grow(-22), Color("#303026"))
		draw_rect(Rect2(rect.position + Vector2(60, 27), Vector2(rect.size.x - 120, 18)), CYAN)
		_draw_hazard_stripes(Rect2(rect.position + Vector2(14, 8), Vector2(rect.size.x - 28, 10)), false)
		_draw_hazard_stripes(Rect2(rect.position + Vector2(14, rect.size.y - 18), Vector2(rect.size.x - 28, 10)), false)
		draw_line(rect.position + Vector2(28, 20), rect.position + Vector2(rect.size.x - 28, 20), Color("#080c0d"), 3.0)
		draw_line(rect.position + Vector2(28, rect.size.y - 20), rect.position + Vector2(rect.size.x - 28, rect.size.y - 20), Color("#080c0d"), 3.0)

	func _draw_vertical_door(rect: Rect2) -> void:
		draw_rect(rect.grow(9), Color("#05090a"))
		draw_rect(rect, Color("#141b1f"))
		draw_rect(rect.grow(-8), Color("#30383c"))
		draw_rect(rect.grow(-20), Color("#263e43"))
		draw_rect(Rect2(rect.position + Vector2(30, 50), Vector2(12, rect.size.y - 100)), CYAN)
		_draw_hazard_stripes(Rect2(rect.position + Vector2(6, 16), Vector2(10, rect.size.y - 32)), true)
		_draw_hazard_stripes(Rect2(rect.position + Vector2(rect.size.x - 16, 16), Vector2(10, rect.size.y - 32)), true)

	func _draw_main_quarantine_mark(floor: Rect2) -> void:
		var c := floor.get_center()
		var w := 356.0
		var h := 228.0
		var pts := PackedVector2Array([
			c + Vector2(-w * 0.36, -h * 0.50),
			c + Vector2(w * 0.36, -h * 0.50),
			c + Vector2(w * 0.50, -h * 0.18),
			c + Vector2(w * 0.50, h * 0.18),
			c + Vector2(w * 0.36, h * 0.50),
			c + Vector2(-w * 0.36, h * 0.50),
			c + Vector2(-w * 0.50, h * 0.18),
			c + Vector2(-w * 0.50, -h * 0.18),
		])
		draw_polygon(pts, [Color("#121b1d", 0.55)])
		for i in range(pts.size()):
			draw_line(pts[i], pts[(i + 1) % pts.size()], AMBER, 3.0)

		_draw_hazard_stripes(Rect2(c + Vector2(-250, -154), Vector2(500, 12)), false)
		_draw_hazard_stripes(Rect2(c + Vector2(-250, 142), Vector2(500, 12)), false)
		_draw_biohazard(c + Vector2(0, -44), AMBER)
		draw_string(font, c + Vector2(-58, 18), "检 疫 区", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, Color("#ca8b2a"))
		draw_string(font, c + Vector2(-94, 52), "GREENHOUSE ENTRY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8f712d"))

	func _draw_biohazard(pos: Vector2, color: Color) -> void:
		draw_arc(pos + Vector2(0, -11), 26.0, deg_to_rad(210), deg_to_rad(330), 24, color, 4.0)
		draw_arc(pos + Vector2(-22, 21), 26.0, deg_to_rad(-30), deg_to_rad(90), 24, color, 4.0)
		draw_arc(pos + Vector2(22, 21), 26.0, deg_to_rad(90), deg_to_rad(210), 24, color, 4.0)
		draw_circle(pos, 7.0, color)

	func _draw_containment_props(floor: Rect2) -> void:
		_draw_large_case(Rect2(floor.position + Vector2(92, 246), Vector2(226, 282)), "培养柜 A")
		_draw_large_case(Rect2(Vector2(floor.end.x - 318, floor.position.y + 246), Vector2(226, 282)), "培养柜 B")
		_draw_planter(Rect2(floor.position + Vector2(250, 106), Vector2(160, 72)))
		_draw_planter(Rect2(Vector2(floor.end.x - 410, floor.position.y + 106), Vector2(160, 72)))
		_draw_planter(Rect2(floor.position + Vector2(140, floor.size.y - 92), Vector2(176, 62)))
		_draw_planter(Rect2(Vector2(floor.end.x - 316, floor.end.y - 92), Vector2(176, 62)))

	func _draw_large_case(rect: Rect2, label: String) -> void:
		draw_rect(rect.grow(10), Color("#071011"))
		draw_rect(rect, Color("#303c40"))
		draw_rect(rect.grow(-10), Color("#162327"))
		draw_rect(rect.grow(-24), GLASS)
		draw_rect(rect.grow(-36), Color("#2a594d", 0.48))
		draw_line(rect.position + Vector2(24, 18), rect.position + Vector2(rect.size.x - 24, 18), GLASS_LIGHT, 2.0)
		draw_line(rect.position + Vector2(34, 38), rect.position + Vector2(rect.size.x - 52, 38), Color("#d7fff5", 0.16), 2.0)
		for offset in [-56, -28, 0, 28, 56]:
			_draw_vertical_plant_stem(rect.get_center() + Vector2(offset, 72), 100 + abs(offset) * 0.25)
		draw_rect(Rect2(rect.position + Vector2(28, rect.size.y - 78), Vector2(rect.size.x - 56, 52)), Color("#102018"))
		for x in range(0, 7):
			_draw_leaf_row(rect.position + Vector2(48 + x * 22, rect.size.y - 50), 0.70)
		draw_string(font, rect.position + Vector2(54, rect.size.y + 30), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#8ccdc2"))

	func _draw_vertical_plant_stem(base: Vector2, height: float) -> void:
		var top := base - Vector2(0, height)
		draw_line(base, top, Color("#244b2d"), 4.0)
		_draw_leaf(top + Vector2(-12, 24), -2.3, 22.0, GREEN_LEAF)
		_draw_leaf(top + Vector2(14, 44), -0.8, 20.0, GREEN_LEAF)
		_draw_leaf(top + Vector2(-10, 70), -2.6, 18.0, Color("#4c6d40"))

	func _draw_planter(rect: Rect2) -> void:
		draw_rect(rect.grow(7), Color("#071011"))
		draw_rect(rect, Color("#2f3a3e"))
		draw_rect(rect.grow(-10), Color("#122119"))
		for i in range(6):
			_draw_leaf_row(rect.position + Vector2(22 + i * (rect.size.x - 44) / 5.0, rect.size.y * 0.58), 0.50)

	func _draw_leaf_row(pos: Vector2, scale: float) -> void:
		for i in range(3):
			var angle := -PI * 0.5 + (i - 1) * 0.55
			var end := pos + Vector2(cos(angle), sin(angle)) * 18.0 * scale
			draw_line(pos, end, GREEN_DARK, 2.0)
			_draw_leaf(end, angle, 14.0 * scale, Color("#547449", 0.92))

	func _draw_terminal_and_signage(floor: Rect2) -> void:
		_draw_terminal(floor.position + Vector2(54, 46))
		_draw_warning_plate(Vector2(floor.end.x - 238, floor.end.y - 92))
		var title_rect := Rect2(floor.position + Vector2(0, -22), Vector2(280, 58))
		draw_rect(title_rect, Color("#071011", 0.92))
		draw_rect(title_rect, Color("#3a7479"), false, 2.0)
		draw_string(font, title_rect.position + Vector2(18, 22), "第二章：生态温室", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#8cece0"))
		draw_string(font, title_rect.position + Vector2(18, 46), "温室检疫入口 / 实装预览", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#d9fbec"))

	func _draw_terminal(pos: Vector2) -> void:
		var rect := Rect2(pos, Vector2(94, 142))
		draw_rect(rect.grow(6), Color("#071011"))
		draw_rect(rect, Color("#1c292d"))
		draw_rect(Rect2(pos + Vector2(16, 16), Vector2(62, 48)), Color("#1b5c5b"))
		draw_rect(Rect2(pos + Vector2(26, 28), Vector2(42, 9)), GLASS_LIGHT)
		for i in range(4):
			draw_line(pos + Vector2(24, 76 + i * 7), pos + Vector2(70, 76 + i * 7), Color("#48e1dc", 0.35), 1.0)
		draw_string(font, pos + Vector2(-4, 170), "检疫终端", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#91d6cc"))

	func _draw_warning_plate(pos: Vector2) -> void:
		var rect := Rect2(pos, Vector2(78, 58))
		draw_rect(rect.grow(5), Color("#071011"))
		draw_rect(rect, Color("#2e332f"))
		draw_rect(rect.grow(-8), Color("#79521c"))
		draw_polygon(PackedVector2Array([
			rect.get_center() + Vector2(0, -14),
			rect.get_center() + Vector2(-17, 15),
			rect.get_center() + Vector2(17, 15),
		]), [Color("#ffc03a")])
		draw_line(rect.get_center() + Vector2(0, -5), rect.get_center() + Vector2(0, 8), Color("#111111"), 3.0)
		draw_circle(rect.get_center() + Vector2(0, 14), 2.0, Color("#111111"))

	func _draw_grate(rect: Rect2) -> void:
		draw_rect(rect, Color("#081011"))
		draw_rect(rect.grow(-6), Color("#202b2f"))
		for i in range(6):
			draw_line(rect.position + Vector2(15 + i * 18, 9), rect.position + Vector2(15 + i * 18, rect.size.y - 9), Color("#071011"), 3.0)

	func _draw_controlled_overgrowth(room: Rect2, floor: Rect2) -> void:
		# Plants are confined to believable sources: planters, wall cracks, and glass cases.
		_draw_vine(Vector2(room.position.x + 80, room.position.y + 154), [
			Vector2(30, 20), Vector2(110, 55), Vector2(170, 100), Vector2(260, 112)
		])
		_draw_vine(Vector2(room.end.x - 386, room.position.y + 150), [
			Vector2(300, 10), Vector2(220, 52), Vector2(150, 92), Vector2(68, 96)
		])
		_draw_vine(Vector2(room.position.x + 96, room.end.y - 220), [
			Vector2(34, 160), Vector2(118, 120), Vector2(190, 74), Vector2(260, 62)
		])
		_draw_vine(Vector2(room.end.x - 382, room.end.y - 220), [
			Vector2(304, 152), Vector2(226, 118), Vector2(146, 82), Vector2(72, 70)
		])

		for x in [floor.position.x + 300, floor.position.x + 348, floor.position.x + 396, floor.end.x - 402, floor.end.x - 350, floor.end.x - 298]:
			_draw_hanging_vine(Vector2(x, floor.position.y - 24), 96)

		# A few dark stains near plant sources, never in the central gameplay lane.
		_draw_green_stain(Rect2(floor.position + Vector2(104, 486), Vector2(168, 36)))
		_draw_green_stain(Rect2(Vector2(floor.end.x - 272, floor.position.y + 494), Vector2(160, 34)))
		_draw_green_stain(Rect2(Vector2(floor.position.x + 72, floor.position.y + 156), Vector2(132, 28)))
		_draw_green_stain(Rect2(Vector2(floor.end.x - 208, floor.position.y + 150), Vector2(132, 28)))

	func _draw_vine(origin: Vector2, offsets: Array[Vector2]) -> void:
		for i in range(offsets.size() - 1):
			var a := origin + offsets[i]
			var b := origin + offsets[i + 1]
			draw_line(a, b, Color("#203d24"), 5.0)
			draw_line(a, b, Color("#365b34"), 2.0)
			if i > 0:
				_draw_leaf(b, (b - a).angle() + 0.9, 18.0, Color("#4d6f42", 0.9))
				_draw_leaf(b - (b - a).normalized() * 18.0, (b - a).angle() - 1.0, 14.0, Color("#405f39", 0.85))

	func _draw_hanging_vine(start: Vector2, length: float) -> void:
		var end := start + Vector2(-8, length)
		draw_line(start, end, Color("#203d24"), 4.0)
		draw_line(start, end, Color("#365b34"), 1.5)
		_draw_leaf(start + Vector2(-4, length * 0.55), PI * 0.8, 14.0, Color("#4d6f42", 0.84))

	func _draw_green_stain(rect: Rect2) -> void:
		draw_rect(rect, Color("#182818", 0.55))
		draw_line(rect.position + Vector2(10, rect.size.y * 0.5), rect.end - Vector2(12, rect.size.y * 0.45), Color("#395933", 0.30), 2.0)

	func _draw_leaf(pos: Vector2, angle: float, length: float, color: Color) -> void:
		var forward := Vector2(cos(angle), sin(angle))
		var side := Vector2(-forward.y, forward.x)
		var width := length * 0.34
		draw_polygon(PackedVector2Array([
			pos - forward * length * 0.34,
			pos + side * width,
			pos + forward * length * 0.58,
			pos - side * width,
		]), [color])
		draw_line(pos - forward * length * 0.20, pos + forward * length * 0.44, Color("#1b3322", color.a), 1.0)

	func _draw_final_lighting(room: Rect2, floor: Rect2) -> void:
		draw_rect(floor, Color("#8dff9a", 0.016))
		draw_rect(Rect2(room.position + Vector2(28, 178), Vector2(20, 142)), Color("#31dce7", 0.20))
		draw_rect(Rect2(room.position + Vector2(28, 446), Vector2(20, 142)), Color("#31dce7", 0.20))
		draw_rect(Rect2(Vector2(room.end.x - 48, room.position.y + 178), Vector2(20, 142)), Color("#31dce7", 0.20))
		draw_rect(Rect2(Vector2(room.end.x - 48, room.position.y + 446), Vector2(20, 142)), Color("#31dce7", 0.20))
		draw_line(room.position + Vector2(250, 38), room.position + Vector2(412, 38), Color("#31dce7", 0.35), 3.0)
		draw_line(Vector2(room.end.x - 412, room.position.y + 38), Vector2(room.end.x - 250, room.position.y + 38), Color("#31dce7", 0.35), 3.0)

	func _draw_hazard_stripes(rect: Rect2, vertical: bool) -> void:
		draw_rect(rect, Color("#14100a"))
		if vertical:
			for y in range(int(rect.position.y) - 18, int(rect.end.y), 18):
				draw_line(Vector2(rect.position.x, y + 16), Vector2(rect.end.x, y), AMBER, 3.0)
		else:
			for x in range(int(rect.position.x) - 18, int(rect.end.x), 18):
				draw_line(Vector2(x, rect.end.y), Vector2(x + 16, rect.position.y), AMBER, 3.0)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = IMAGE_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var canvas := GreenhouseEntryCanvas.new()
	viewport.add_child(canvas)
	await process_frame
	await process_frame
	await process_frame

	var image := viewport.get_texture().get_image()
	var output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var err := image.save_png(output)
	if err != OK:
		push_error("Failed to save preview: %s" % output)
		quit(1)
		return

	print("Saved Godot greenhouse entry implementation preview:")
	print(output)
	quit(0)
