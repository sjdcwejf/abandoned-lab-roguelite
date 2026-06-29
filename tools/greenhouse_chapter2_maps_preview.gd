extends SceneTree

const MAP_SIZE := Vector2i(1600, 900)
const PREVIEW_DIR := "res://docs/previews"
const ROOM_RECT := Rect2(Vector2(112, 82), Vector2(1376, 736))
const FLOOR_RECT := Rect2(Vector2(192, 162), Vector2(1216, 576))

const ROOM_SPECS := [
	{"kind": "entry", "file": "chapter2_greenhouse_01_entry.png", "seed": 2101},
	{"kind": "spore_corridor", "file": "chapter2_greenhouse_02_spore_corridor.png", "seed": 2102},
	{"kind": "hive_sample", "file": "chapter2_greenhouse_03_hive_sample_room.png", "seed": 2103},
	{"kind": "sample_vault", "file": "chapter2_greenhouse_04_sample_vault.png", "seed": 2104},
	{"kind": "weapon_cache", "file": "chapter2_greenhouse_05_weapon_cache.png", "seed": 2105},
	{"kind": "raven_supply", "file": "chapter2_greenhouse_06_raven_supply.png", "seed": 2106},
	{"kind": "boss_nursery", "file": "chapter2_greenhouse_07_boss_nursery.png", "seed": 2107},
]


class GreenhouseMapCanvas:
	extends Node2D

	const BG := Color("#061012")
	const WALL_OUTER := Color("#10191d")
	const WALL_RIM := Color("#4b565d")
	const WALL_BODY := Color("#232e33")
	const WALL_INNER := Color("#10191c")
	const FLOOR_A := Color("#172326")
	const FLOOR_B := Color("#1b282b")
	const FLOOR_LINE := Color("#2d3b40")
	const CYAN := Color("#44d4df")
	const CYAN_DIM := Color("#1c7480")
	const AMBER := Color("#c07a24")
	const GREEN_DARK := Color("#18281d")
	const GREEN_MID := Color("#294b31")
	const GREEN_LEAF := Color("#506d43")
	const GLASS := Color("#24464a")
	const GLASS_HI := Color("#79e8df")

	var kind := "entry"
	var rng := RandomNumberGenerator.new()

	func _init(room_kind: String, seed_value: int) -> void:
		kind = room_kind
		rng.seed = seed_value

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE)), BG)
		_draw_room_shell(ROOM_RECT)
		_draw_floor(FLOOR_RECT)
		_draw_wall_modules(ROOM_RECT)
		_draw_doors(ROOM_RECT)
		_draw_base_damage(FLOOR_RECT)

		match kind:
			"entry":
				_draw_entry_room(FLOOR_RECT)
			"spore_corridor":
				_draw_spore_corridor(FLOOR_RECT)
			"hive_sample":
				_draw_hive_sample_room(FLOOR_RECT)
			"sample_vault":
				_draw_sample_vault(FLOOR_RECT)
			"weapon_cache":
				_draw_weapon_cache(FLOOR_RECT)
			"raven_supply":
				_draw_raven_supply(FLOOR_RECT)
			"boss_nursery":
				_draw_boss_nursery(FLOOR_RECT)

		_draw_edge_overgrowth(ROOM_RECT)
		_draw_light_pass(ROOM_RECT, FLOOR_RECT)

	func _draw_room_shell(room: Rect2) -> void:
		draw_rect(room.grow(14), Color("#050809"))
		draw_rect(room, WALL_OUTER)
		draw_rect(room.grow(-10), WALL_RIM)
		draw_rect(room.grow(-18), WALL_BODY)
		draw_rect(room.grow(-46), Color("#172126"))
		draw_rect(room.grow(-76), WALL_INNER)
		draw_line(room.position + Vector2(12, 12), Vector2(room.end.x - 12, room.position.y + 12), Color("#69747c"), 4.0)
		draw_line(room.position + Vector2(12, 12), Vector2(room.position.x + 12, room.end.y - 12), Color("#505c64"), 4.0)
		draw_line(Vector2(room.position.x + 12, room.end.y - 12), room.end - Vector2(12, 12), Color("#050809"), 5.0)
		draw_line(Vector2(room.end.x - 12, room.position.y + 12), room.end - Vector2(12, 12), Color("#050809"), 5.0)
		for corner in [
			room.position + Vector2(36, 36),
			Vector2(room.end.x - 76, room.position.y + 36),
			Vector2(room.position.x + 36, room.end.y - 76),
			room.end - Vector2(76, 76),
		]:
			draw_rect(Rect2(corner, Vector2(40, 40)), Color("#3a454b"))
			draw_rect(Rect2(corner + Vector2(10, 10), Vector2(20, 20)), Color("#091012"))

	func _draw_floor(floor: Rect2) -> void:
		draw_rect(floor, FLOOR_A)
		var tile := 64
		for x in range(int(floor.position.x), int(floor.end.x), tile):
			for y in range(int(floor.position.y), int(floor.end.y), tile):
				var cell := Rect2(Vector2(x, y), Vector2(tile - 2, tile - 2))
				var shade := FLOOR_A if int((x + y) / tile) % 2 == 0 else FLOOR_B
				draw_rect(cell, shade)
				draw_rect(cell, FLOOR_LINE, false, 1.0)
				if rng.randf() < 0.18:
					_draw_tile_crack(cell)
		var c := floor.get_center()
		draw_line(Vector2(c.x, floor.position.y + 32), Vector2(c.x, floor.end.y - 32), Color("#1d8088", 0.32), 2.0)
		draw_line(Vector2(floor.position.x + 112, c.y), Vector2(c.x - 300, c.y), Color("#6d4c1b", 0.38), 2.0)
		draw_line(Vector2(c.x + 300, c.y), Vector2(floor.end.x - 112, c.y), Color("#6d4c1b", 0.38), 2.0)

	func _draw_tile_crack(cell: Rect2) -> void:
		var p := cell.position + Vector2(rng.randf_range(10, cell.size.x - 10), rng.randf_range(10, cell.size.y - 10))
		for i in range(rng.randi_range(2, 4)):
			var q := p + Vector2(rng.randf_range(-20, 20), rng.randf_range(-14, 14))
			draw_line(p, q, Color("#44545a", 0.45), 1.0)
			p = q

	func _draw_wall_modules(room: Rect2) -> void:
		for i in range(7):
			var x := room.position.x + 150 + i * 164
			_draw_wall_panel(Rect2(Vector2(x, room.position.y + 38), Vector2(96, 42)), i)
			_draw_wall_panel(Rect2(Vector2(x, room.end.y - 80), Vector2(96, 42)), i + 1)
		_draw_side_light_stack(Vector2(room.position.x + 34, room.position.y + 182), false)
		_draw_side_light_stack(Vector2(room.end.x - 62, room.position.y + 190), true)

	func _draw_wall_panel(rect: Rect2, index: int) -> void:
		draw_rect(rect, Color("#151f22"))
		draw_rect(rect.grow(-4), Color("#263138"))
		draw_line(rect.position + Vector2(14, 12), rect.position + Vector2(rect.size.x - 14, 12), CYAN if index % 3 == 0 else AMBER, 2.0)
		draw_line(rect.position + Vector2(18, rect.size.y - 10), rect.position + Vector2(rect.size.x - 18, rect.size.y - 10), Color("#071011"), 2.0)

	func _draw_side_light_stack(pos: Vector2, right: bool) -> void:
		for i in range(2):
			var rect := Rect2(pos + Vector2(0, i * 208), Vector2(28, 132))
			draw_rect(rect.grow(7), Color("#070d0f"))
			draw_rect(rect, Color("#16272c"))
			draw_rect(rect.grow(-7), Color("#254850"))
			draw_rect(Rect2(rect.position + Vector2(9, 25), Vector2(10, 82)), CYAN)
			var stripe_x := rect.position.x - 18 if right else rect.end.x + 8
			_draw_hazard_stripes(Rect2(Vector2(stripe_x, rect.position.y + 12), Vector2(12, rect.size.y - 24)), true)

	func _draw_doors(room: Rect2) -> void:
		var c := room.get_center()
		_draw_door_h(Rect2(Vector2(c.x - 128, room.position.y + 8), Vector2(256, 72)))
		_draw_door_h(Rect2(Vector2(c.x - 128, room.end.y - 80), Vector2(256, 72)))

	func _draw_door_h(rect: Rect2) -> void:
		draw_rect(rect.grow(9), Color("#050809"))
		draw_rect(rect, Color("#171e21"))
		draw_rect(rect.grow(-8), Color("#333a3f"))
		draw_rect(rect.grow(-22), Color("#2d2b23"))
		draw_rect(Rect2(rect.position + Vector2(62, 27), Vector2(rect.size.x - 124, 18)), CYAN)
		_draw_hazard_stripes(Rect2(rect.position + Vector2(14, 8), Vector2(rect.size.x - 28, 8)), false)
		_draw_hazard_stripes(Rect2(rect.position + Vector2(14, rect.size.y - 16), Vector2(rect.size.x - 28, 8)), false)

	func _draw_base_damage(floor: Rect2) -> void:
		for i in range(14):
			var p := floor.position + Vector2(rng.randf_range(44, floor.size.x - 44), rng.randf_range(44, floor.size.y - 44))
			var size := Vector2(rng.randf_range(18, 54), rng.randf_range(8, 24))
			draw_rect(Rect2(p - size * 0.5, size), Color("#0d1714", rng.randf_range(0.22, 0.36)))
		for i in range(18):
			var p := floor.position + Vector2(rng.randf_range(34, floor.size.x - 34), rng.randf_range(34, floor.size.y - 34))
			var q := p + Vector2(rng.randf_range(-36, 36), rng.randf_range(-26, 26))
			draw_line(p, q, Color("#49585e", 0.35), 1.0)

	func _draw_entry_room(floor: Rect2) -> void:
		_draw_large_culture_pod(Rect2(floor.position + Vector2(86, 232), Vector2(228, 284)), 0)
		_draw_large_culture_pod(Rect2(Vector2(floor.end.x - 324, floor.position.y + 222), Vector2(228, 292)), 1)
		_draw_planter(Rect2(floor.position + Vector2(248, 112), Vector2(168, 68)), 0)
		_draw_planter(Rect2(Vector2(floor.end.x - 416, floor.position.y + 104), Vector2(168, 68)), 1)
		_draw_terminal(floor.position + Vector2(56, 52))
		_draw_warning_plate(Vector2(floor.end.x - 182, floor.position.y + 72))
		_draw_pollution_patch(Rect2(floor.position + Vector2(72, 472), Vector2(220, 48)), 0.55)
		_draw_pollution_patch(Rect2(Vector2(floor.end.x - 292, floor.position.y + 456), Vector2(214, 54)), 0.50)

	func _draw_spore_corridor(floor: Rect2) -> void:
		for i in range(3):
			_draw_tube_tank(Rect2(floor.position + Vector2(126 + i * 154, 104), Vector2(82, 180)), i)
		for i in range(3):
			_draw_tube_tank(Rect2(Vector2(floor.end.x - 208 - i * 154, floor.end.y - 286), Vector2(82, 180)), i + 3)
		_draw_planter(Rect2(floor.position + Vector2(118, 452), Vector2(260, 72)), 0)
		_draw_planter(Rect2(Vector2(floor.end.x - 378, floor.position.y + 72), Vector2(260, 72)), 1)
		_draw_pollution_patch(Rect2(floor.position + Vector2(95, 92), Vector2(430, 230)), 0.36)
		_draw_pollution_patch(Rect2(Vector2(floor.end.x - 525, floor.end.y - 320), Vector2(430, 230)), 0.36)
		_draw_broken_glass(floor.position + Vector2(462, 178), 8)
		_draw_broken_glass(Vector2(floor.end.x - 420, floor.end.y - 172), 8)

	func _draw_hive_sample_room(floor: Rect2) -> void:
		for x in [floor.position.x + 244, floor.get_center().x, floor.end.x - 244]:
			_draw_hive_egg(Vector2(x, floor.position.y + 178), 0.78)
		_draw_hive_egg(floor.position + Vector2(220, 468), 0.62)
		_draw_hive_egg(Vector2(floor.end.x - 220, floor.end.y - 112), 0.62)
		_draw_pollution_patch(Rect2(floor.position + Vector2(148, 84), Vector2(floor.size.x - 296, 190)), 0.56)
		_draw_pollution_patch(Rect2(floor.position + Vector2(130, 428), Vector2(310, 92)), 0.42)
		_draw_pollution_patch(Rect2(Vector2(floor.end.x - 440, floor.end.y - 156), Vector2(310, 92)), 0.42)
		_draw_cracked_sample_crate(floor.position + Vector2(88, 350))
		_draw_cracked_sample_crate(Vector2(floor.end.x - 184, 350))

	func _draw_sample_vault(floor: Rect2) -> void:
		_draw_reward_crate(Rect2(floor.get_center() - Vector2(48, 34), Vector2(96, 68)))
		for pos in [
			floor.position + Vector2(112, 110),
			floor.position + Vector2(112, 386),
			Vector2(floor.end.x - 284, floor.position.y + 102),
			Vector2(floor.end.x - 284, floor.end.y - 168),
		]:
			_draw_sample_shelf(Rect2(pos, Vector2(172, 92)))
		_draw_large_culture_pod(Rect2(floor.position + Vector2(418, 388), Vector2(160, 132)), 2)
		_draw_large_culture_pod(Rect2(Vector2(floor.end.x - 578, floor.position.y + 82), Vector2(160, 132)), 3)
		_draw_pollution_patch(Rect2(floor.position + Vector2(78, 88), Vector2(262, 110)), 0.30)
		_draw_pollution_patch(Rect2(Vector2(floor.end.x - 340, floor.end.y - 190), Vector2(252, 120)), 0.30)

	func _draw_weapon_cache(floor: Rect2) -> void:
		_draw_weapon_rack(Rect2(floor.position + Vector2(140, 166), Vector2(214, 230)), false)
		_draw_weapon_rack(Rect2(Vector2(floor.end.x - 354, floor.position.y + 190), Vector2(214, 230)), true)
		_draw_armory_plinth(Rect2(floor.get_center() - Vector2(74, 44), Vector2(148, 88)))
		_draw_cracked_sample_crate(floor.position + Vector2(96, 466))
		_draw_cracked_sample_crate(Vector2(floor.end.x - 192, 92))
		_draw_pollution_patch(Rect2(floor.position + Vector2(112, 112), Vector2(270, 382)), 0.36)
		_draw_pollution_patch(Rect2(Vector2(floor.end.x - 382, floor.position.y + 118), Vector2(270, 382)), 0.32)

	func _draw_raven_supply(floor: Rect2) -> void:
		_draw_shop_counter(Rect2(Vector2(floor.get_center().x - 156, floor.position.y + 96), Vector2(312, 86)))
		_draw_supply_shelf(Rect2(floor.position + Vector2(96, 104), Vector2(160, 220)))
		_draw_supply_shelf(Rect2(Vector2(floor.end.x - 256, floor.position.y + 112), Vector2(160, 220)))
		_draw_supply_shelf(Rect2(floor.position + Vector2(144, floor.end.y - 160), Vector2(196, 72)))
		_draw_supply_shelf(Rect2(Vector2(floor.end.x - 340, floor.end.y - 150), Vector2(196, 72)))
		_draw_pollution_patch(Rect2(floor.position + Vector2(86, 358), Vector2(240, 76)), 0.24)
		_draw_pollution_patch(Rect2(Vector2(floor.end.x - 326, floor.end.y - 250), Vector2(240, 74)), 0.24)

	func _draw_boss_nursery(floor: Rect2) -> void:
		var c := floor.get_center()
		_draw_boss_incubator(c + Vector2(0, -26))
		for pos in [
			floor.position + Vector2(120, 104),
			Vector2(floor.end.x - 260, floor.position.y + 112),
			floor.position + Vector2(124, floor.end.y - 202),
			Vector2(floor.end.x - 264, floor.end.y - 198),
		]:
			_draw_planter(Rect2(pos, Vector2(140, 96)), 2)
		_draw_pollution_patch(Rect2(c - Vector2(300, 210), Vector2(600, 152)), 0.48)
		_draw_pollution_patch(Rect2(c + Vector2(-430, 156), Vector2(256, 72)), 0.30)
		_draw_pollution_patch(Rect2(c + Vector2(174, 156), Vector2(256, 72)), 0.30)
		_draw_broken_glass(c + Vector2(-242, -152), 10)
		_draw_broken_glass(c + Vector2(266, 148), 10)

	func _draw_large_culture_pod(rect: Rect2, variant: int) -> void:
		draw_rect(rect.grow(10), Color("#071011"))
		draw_rect(rect, Color("#303b40"))
		draw_rect(rect.grow(-9), Color("#152327"))
		draw_rect(rect.grow(-22), GLASS)
		draw_rect(rect.grow(-36), Color("#2a564d", 0.45))
		draw_line(rect.position + Vector2(22, 18), rect.position + Vector2(rect.size.x - 22, 18), GLASS_HI, 2.0)
		for offset in [-42, -16, 10, 38]:
			_draw_plant_stem(rect.get_center() + Vector2(offset, rect.size.y * 0.28), 74 + abs(offset) * 0.3)
		if variant % 2 == 1:
			_draw_broken_glass(rect.position + Vector2(rect.size.x * 0.70, rect.size.y * 0.26), 5)
			draw_line(rect.position + Vector2(rect.size.x * 0.68, 46), rect.position + Vector2(rect.size.x * 0.82, 120), Color("#7bded5", 0.22), 2.0)
		draw_rect(Rect2(rect.position + Vector2(28, rect.size.y - 70), Vector2(rect.size.x - 56, 46)), Color("#102018"))
		for i in range(6):
			_draw_leaf_row(rect.position + Vector2(44 + i * 24, rect.size.y - 42), 0.62)

	func _draw_tube_tank(rect: Rect2, variant: int) -> void:
		draw_rect(rect.grow(8), Color("#071011"))
		draw_rect(rect, Color("#303c40"))
		draw_rect(rect.grow(-8), GLASS)
		draw_rect(rect.grow(-20), Color("#2c684f", 0.55))
		draw_line(rect.position + Vector2(14, 16), rect.position + Vector2(rect.size.x - 16, 16), GLASS_HI, 2.0)
		_draw_plant_stem(rect.get_center() + Vector2(0, rect.size.y * 0.32), 92.0)
		if variant % 2 == 0:
			_draw_broken_glass(rect.get_center() + Vector2(14, -24), 4)

	func _draw_plant_stem(base: Vector2, height: float) -> void:
		var top := base - Vector2(0, height)
		draw_line(base, top, Color("#203d24"), 4.0)
		_draw_leaf(top + Vector2(-12, 20), -2.4, 18.0, GREEN_LEAF)
		_draw_leaf(top + Vector2(14, 42), -0.8, 18.0, GREEN_LEAF)

	func _draw_planter(rect: Rect2, variant: int) -> void:
		draw_rect(rect.grow(7), Color("#071011"))
		draw_rect(rect, Color("#2f3a3e"))
		draw_rect(rect.grow(-10), Color("#102018"))
		for i in range(6):
			_draw_leaf_row(rect.position + Vector2(20 + i * (rect.size.x - 40) / 5.0, rect.size.y * (0.58 + 0.04 * (variant % 2))), 0.48)

	func _draw_leaf_row(pos: Vector2, scale: float) -> void:
		for i in range(3):
			var angle := -PI * 0.5 + (i - 1) * 0.52
			var end := pos + Vector2(cos(angle), sin(angle)) * 18.0 * scale
			draw_line(pos, end, GREEN_DARK, 2.0)
			_draw_leaf(end, angle, 14.0 * scale, Color("#526f45", 0.92))

	func _draw_leaf(pos: Vector2, angle: float, length: float, color: Color) -> void:
		var forward := Vector2(cos(angle), sin(angle))
		var side := Vector2(-forward.y, forward.x)
		draw_polygon(PackedVector2Array([
			pos - forward * length * 0.34,
			pos + side * length * 0.32,
			pos + forward * length * 0.58,
			pos - side * length * 0.32,
		]), [color])
		draw_line(pos - forward * length * 0.2, pos + forward * length * 0.45, Color("#1a3120", color.a), 1.0)

	func _draw_pollution_patch(rect: Rect2, alpha: float) -> void:
		draw_rect(rect, Color("#102018", alpha))
		draw_rect(rect.grow(-8), Color("#243a25", alpha * 0.42))
		for i in range(3):
			var y := rect.position.y + 12 + i * (rect.size.y - 24) / 2.0
			draw_line(Vector2(rect.position.x + 14, y), Vector2(rect.end.x - 14, y + rng.randf_range(-5, 5)), Color("#406236", alpha * 0.46), 2.0)

	func _draw_terminal(pos: Vector2) -> void:
		var rect := Rect2(pos, Vector2(94, 142))
		draw_rect(rect.grow(6), Color("#071011"))
		draw_rect(rect, Color("#1d292d"))
		draw_rect(Rect2(pos + Vector2(16, 16), Vector2(62, 48)), Color("#1b5b5a"))
		draw_rect(Rect2(pos + Vector2(26, 28), Vector2(42, 9)), GLASS_HI)
		for i in range(4):
			draw_line(pos + Vector2(24, 76 + i * 7), pos + Vector2(70, 76 + i * 7), Color("#48e1dc", 0.35), 1.0)

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

	func _draw_broken_glass(center: Vector2, count: int) -> void:
		for i in range(count):
			var p := center + Vector2(rng.randf_range(-38, 38), rng.randf_range(-24, 24))
			draw_polygon(PackedVector2Array([
				p,
				p + Vector2(rng.randf_range(8, 18), rng.randf_range(-4, 8)),
				p + Vector2(rng.randf_range(2, 10), rng.randf_range(8, 18)),
			]), [Color("#9beee7", 0.20)])

	func _draw_hive_egg(pos: Vector2, scale: float) -> void:
		draw_circle(pos, 54.0 * scale, Color("#0a0f0d"))
		draw_circle(pos, 42.0 * scale, Color("#263020"))
		draw_circle(pos, 28.0 * scale, Color("#6c7a43"))
		draw_arc(pos, 42.0 * scale, 0.0, TAU, 32, Color("#1b2a19"), 5.0)
		for i in range(5):
			_draw_leaf(pos + Vector2(rng.randf_range(-26, 26), rng.randf_range(-26, 26)) * scale, rng.randf_range(0, TAU), 12.0 * scale, Color("#8f9b57", 0.58))

	func _draw_cracked_sample_crate(pos: Vector2) -> void:
		var rect := Rect2(pos, Vector2(96, 72))
		draw_rect(rect.grow(6), Color("#071011"))
		draw_rect(rect, Color("#37342b"))
		draw_rect(rect.grow(-10), Color("#1e2924"))
		draw_line(rect.position + Vector2(14, 20), rect.end - Vector2(20, 24), Color("#725124"), 3.0)
		draw_line(rect.position + Vector2(20, rect.size.y - 18), rect.end - Vector2(18, rect.size.y - 16), CYAN_DIM, 2.0)

	func _draw_reward_crate(rect: Rect2) -> void:
		draw_rect(rect.grow(8), Color("#071011"))
		draw_rect(rect, Color("#433a28"))
		draw_rect(rect.grow(-8), Color("#8b6328"))
		draw_rect(Rect2(rect.position + Vector2(34, 22), Vector2(28, 24)), Color("#e1b348"))
		draw_rect(rect, Color("#18120a", 0.20), false, 3.0)

	func _draw_sample_shelf(rect: Rect2) -> void:
		draw_rect(rect.grow(6), Color("#071011"))
		draw_rect(rect, Color("#263138"))
		for i in range(3):
			var jar := Rect2(rect.position + Vector2(20 + i * 46, 18), Vector2(26, 50))
			draw_rect(jar, GLASS)
			draw_rect(jar.grow(-6), Color("#496b3d", 0.52))
			draw_line(jar.position + Vector2(5, 7), jar.position + Vector2(20, 7), GLASS_HI, 1.0)

	func _draw_weapon_rack(rect: Rect2, flipped: bool) -> void:
		draw_rect(rect.grow(8), Color("#071011"))
		draw_rect(rect, Color("#263138"))
		draw_rect(rect.grow(-12), Color("#11191c"))
		for i in range(4):
			var y := rect.position.y + 38 + i * 42
			draw_line(Vector2(rect.position.x + 28, y), Vector2(rect.end.x - 28, y), Color("#4b5660"), 4.0)
			var x1: float = rect.position.x + (62.0 if flipped else rect.size.x - 62.0)
			draw_line(Vector2(x1, y - 14), Vector2(rect.get_center().x, y + 12), CYAN_DIM, 4.0)

	func _draw_armory_plinth(rect: Rect2) -> void:
		draw_rect(rect.grow(8), Color("#071011"))
		draw_rect(rect, Color("#2c3335"))
		draw_rect(rect.grow(-14), Color("#163034"))
		draw_line(rect.position + Vector2(30, rect.size.y * 0.50), rect.end - Vector2(30, rect.size.y * 0.50), CYAN, 5.0)

	func _draw_shop_counter(rect: Rect2) -> void:
		draw_rect(rect.grow(8), Color("#071011"))
		draw_rect(rect, Color("#372f25"))
		draw_rect(rect.grow(-10), Color("#1e282a"))
		draw_rect(Rect2(rect.position + Vector2(30, 18), Vector2(rect.size.x - 60, 18)), Color("#284b50"))
		draw_line(rect.position + Vector2(26, rect.size.y - 16), rect.end - Vector2(26, 16), AMBER, 2.0)

	func _draw_supply_shelf(rect: Rect2) -> void:
		draw_rect(rect.grow(6), Color("#071011"))
		draw_rect(rect, Color("#2e332f"))
		var rows := clampi(int((rect.size.y - 16.0) / 56.0), 1, 3)
		var step := (rect.size.y - 30.0) / float(rows)
		for i in range(rows):
			var y := 14.0 + i * step
			draw_rect(Rect2(rect.position + Vector2(16, y), Vector2(rect.size.x - 32, 28)), Color("#423a2b"))
			draw_rect(Rect2(rect.position + Vector2(28, y + 4), Vector2(24, 20)), Color("#496b3d"))
			draw_rect(Rect2(rect.position + Vector2(rect.size.x - 56, y + 4), Vector2(24, 20)), Color("#1f5960"))

	func _draw_boss_incubator(pos: Vector2) -> void:
		draw_circle(pos, 134, Color("#071011"))
		draw_circle(pos, 118, Color("#1b2729"))
		draw_arc(pos, 118, 0, TAU, 64, Color("#536068"), 7.0)
		draw_circle(pos, 82, Color("#263c32"))
		draw_circle(pos, 58, Color("#426343"))
		for i in range(6):
			var a := TAU * i / 6.0
			draw_line(pos + Vector2(cos(a), sin(a)) * 86, pos + Vector2(cos(a), sin(a)) * 132, Color("#31593a"), 5.0)
		draw_rect(Rect2(pos - Vector2(36, 138), Vector2(72, 34)), Color("#172326"))
		draw_rect(Rect2(pos - Vector2(22, 130), Vector2(44, 12)), CYAN_DIM)

	func _draw_edge_overgrowth(room: Rect2) -> void:
		_draw_vine(room.position + Vector2(92, 146), [Vector2(0, 0), Vector2(112, 44), Vector2(212, 78), Vector2(316, 84)])
		_draw_vine(Vector2(room.end.x - 420, room.position.y + 142), [Vector2(316, 0), Vector2(220, 44), Vector2(124, 72), Vector2(28, 78)])
		_draw_vine(Vector2(room.position.x + 102, room.end.y - 184), [Vector2(0, 126), Vector2(112, 78), Vector2(222, 62)])
		_draw_vine(Vector2(room.end.x - 420, room.end.y - 182), [Vector2(316, 124), Vector2(218, 82), Vector2(122, 68)])

	func _draw_vine(origin: Vector2, offsets: Array) -> void:
		for i in range(offsets.size() - 1):
			var a: Vector2 = origin + offsets[i]
			var b: Vector2 = origin + offsets[i + 1]
			draw_line(a, b, Color("#1c3822"), 5.0)
			draw_line(a, b, Color("#365b34"), 2.0)
			if i > 0:
				_draw_leaf(b, (b - a).angle() + 0.85, 16.0, Color("#4d6f42", 0.82))

	func _draw_light_pass(room: Rect2, floor: Rect2) -> void:
		draw_rect(floor, Color("#79ff8d", 0.012))
		draw_line(room.position + Vector2(250, 38), room.position + Vector2(412, 38), Color("#31dce7", 0.30), 3.0)
		draw_line(Vector2(room.end.x - 412, room.position.y + 38), Vector2(room.end.x - 250, room.position.y + 38), Color("#31dce7", 0.30), 3.0)

	func _draw_hazard_stripes(rect: Rect2, vertical: bool) -> void:
		draw_rect(rect, Color("#14100a"))
		if vertical:
			for y in range(int(rect.position.y) - 18, int(rect.end.y), 20):
				draw_line(Vector2(rect.position.x, y + 16), Vector2(rect.end.x, y), AMBER, 3.0)
		else:
			for x in range(int(rect.position.x) - 18, int(rect.end.x), 20):
				draw_line(Vector2(x, rect.end.y), Vector2(x + 16, rect.position.y), AMBER, 3.0)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dir := DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("docs/previews")

	var thumbs: Array[Image] = []
	for spec in ROOM_SPECS:
		var image := await _render_room(spec["kind"], spec["seed"])
		var output := ProjectSettings.globalize_path(PREVIEW_DIR.path_join(spec["file"]))
		var err := image.save_png(output)
		if err != OK:
			push_error("Failed to save preview: %s" % output)
			quit(1)
			return
		var thumb := image.duplicate()
		thumb.convert(Image.FORMAT_RGBA8)
		thumb.resize(560, 315, Image.INTERPOLATE_NEAREST)
		thumbs.append(thumb)
		print(output)

	var overview := Image.create(1900, 1165, false, Image.FORMAT_RGBA8)
	overview.fill(Color("#061012"))
	for i in range(thumbs.size()):
		var col := i % 3
		var row := i / 3
		var pos := Vector2i(60 + col * 610, 60 + row * 365)
		overview.blit_rect(thumbs[i], Rect2i(Vector2i.ZERO, thumbs[i].get_size()), pos)
	var overview_path := ProjectSettings.globalize_path(PREVIEW_DIR.path_join("chapter2_greenhouse_full_map_set_godot.png"))
	var overview_err := overview.save_png(overview_path)
	if overview_err != OK:
		push_error("Failed to save overview: %s" % overview_path)
		quit(1)
		return
	print(overview_path)
	quit(0)


func _render_room(kind: String, seed_value: int) -> Image:
	var viewport := SubViewport.new()
	viewport.size = MAP_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var canvas := GreenhouseMapCanvas.new(kind, seed_value)
	viewport.add_child(canvas)
	await process_frame
	await process_frame
	await process_frame

	var image := viewport.get_texture().get_image()
	root.remove_child(viewport)
	viewport.queue_free()
	return image
