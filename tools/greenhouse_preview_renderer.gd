extends SceneTree

const IMAGE_SIZE := Vector2i(1600, 900)
const OUT_ROOMS := "res://docs/previews/chapter2_greenhouse_rooms_godot.png"
const OUT_ENEMIES := "res://docs/previews/chapter2_greenhouse_enemies_godot.png"


class PreviewCanvas:
	extends Node2D

	var mode := "rooms"
	var font: Font

	func _ready() -> void:
		font = _load_preview_font()
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(IMAGE_SIZE)), Color("#0b1112"))
		if mode == "rooms":
			_draw_rooms_preview()
		else:
			_draw_enemies_preview()

	func _load_preview_font() -> Font:
		var font_file := FontFile.new()
		var err := font_file.load_dynamic_font("/System/Library/Fonts/Hiragino Sans GB.ttc")
		if err == OK:
			return font_file
		err = font_file.load_dynamic_font("/System/Library/Fonts/STHeiti Medium.ttc")
		if err == OK:
			return font_file
		return ThemeDB.fallback_font

	func _draw_rooms_preview() -> void:
		_draw_title("第二章：生态温室 / Godot 实际渲染预览", "房间规格图：墙体、门、障碍、目标物和出生点均按可实装节点语言绘制")

		var room_size := Vector2(440, 230)
		var gap := Vector2(45, 42)
		var start := Vector2(95, 130)
		var labels := [
			"温室检疫入口",
			"孢子培养廊",
			"虫巢样本间",
			"温室样本库",
			"渡鸦温室补给站",
			"温室守望者培育舱",
		]
		var kinds := ["start", "combat", "hive", "reward", "merchant", "boss"]
		for index in range(labels.size()):
			var col := index % 3
			var row := index / 3
			var rect := Rect2(start + Vector2(col, row) * (room_size + gap), room_size)
			_draw_greenhouse_room(rect, labels[index], kinds[index])

		_draw_legend(Vector2(95, 825))

	func _draw_enemies_preview() -> void:
		_draw_title("第二章：生态温室 / 小怪 Godot 实际渲染预览", "战斗用俯视像素轮廓：中心点、攻击预警和碰撞体阅读优先")

		var card_size := Vector2(430, 235)
		var gap := Vector2(55, 42)
		var start := Vector2(100, 135)
		var labels := [
			"孢子爬行体",
			"藤蔓喷射体",
			"虫巢工蜂",
			"育槽护卫",
			"腐液囊虫",
			"温室看守幼体",
		]
		var roles := [
			"高速近战 / 死亡孢子",
			"定点远程 / 预警射击",
			"群体飞行 / 折线追击",
			"中型坦克 / 阻挡走位",
			"自爆腐液 / 地面危险",
			"精英幼体 / 突进喷射",
		]
		for index in range(labels.size()):
			var col := index % 3
			var row := index / 3
			var rect := Rect2(start + Vector2(col, row) * (card_size + gap), card_size)
			_draw_enemy_card(rect, labels[index], roles[index], index)

	func _draw_title(title: String, subtitle: String) -> void:
		draw_string(font, Vector2(72, 58), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30, Color("#d8fff2"))
		draw_string(font, Vector2(74, 92), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#78b5a7"))
		draw_line(Vector2(72, 105), Vector2(1528, 105), Color("#1e6c6a"), 2.0)

	func _draw_greenhouse_room(rect: Rect2, label: String, kind: String) -> void:
		var wall := Color("#172325")
		var floor := Color("#11191b")
		var grid := Color("#213437")
		var cyan := Color("#35d5db")
		var green := Color("#79f06d")
		var amber := Color("#d9952d")
		var resin := Color("#1f3427")

		draw_rect(rect, wall)
		var inner := rect.grow(-22)
		draw_rect(inner, floor)
		for x in range(int(inner.position.x), int(inner.end.x), 34):
			draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), grid, 1.0)
		for y in range(int(inner.position.y), int(inner.end.y), 34):
			draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), grid, 1.0)

		_draw_room_doors(rect, cyan, amber)
		_draw_hazard_stripes(Rect2(inner.position + Vector2(16, 8), Vector2(inner.size.x - 32, 8)), amber)
		_draw_label_badge(rect.position + Vector2(14, 14), label)

		match kind:
			"start":
				_draw_airlock(inner)
				_draw_planter(inner.position + Vector2(72, 90), true)
				_draw_planter(inner.position + Vector2(inner.size.x - 140, 90), true)
				_draw_spawn_cross(inner.get_center(), Color("#d8fff2"), "玩家")
			"combat":
				for i in range(4):
					_draw_culture_tank(inner.position + Vector2(62 + i * 78, 62), Color("#5adf7d"))
				_draw_vine_barrier(inner.position + Vector2(105, 148), 145.0)
				_draw_vine_barrier(inner.position + Vector2(275, 122), 90.0)
				_draw_enemy_marker(inner.position + Vector2(120, 104), "爬")
				_draw_enemy_marker(inner.position + Vector2(318, 155), "喷")
			"hive":
				draw_rect(Rect2(inner.position + Vector2(50, 52), Vector2(inner.size.x - 100, inner.size.y - 78)), resin, false, 8.0)
				_draw_spore_pod(inner.position + Vector2(110, 112), true)
				_draw_spore_pod(inner.position + Vector2(210, 76), true)
				_draw_spore_pod(inner.position + Vector2(305, 132), true)
				_draw_enemy_marker(inner.position + Vector2(84, 156), "蜂")
				_draw_enemy_marker(inner.position + Vector2(342, 82), "囊")
			"reward":
				_draw_sample_cache(inner.get_center() + Vector2(0, 18), "补给箱")
				_draw_planter(inner.position + Vector2(66, 65), false)
				_draw_planter(inner.position + Vector2(300, 65), false)
				_draw_vine_barrier(inner.position + Vector2(70, 152), 230.0)
				_draw_enemy_marker(inner.position + Vector2(132, 105), "护")
				_draw_enemy_marker(inner.position + Vector2(308, 108), "蜂")
			"merchant":
				_draw_raven_counter(inner)
				_draw_terminal(inner.get_center() + Vector2(-112, 28))
				draw_string(font, inner.get_center() + Vector2(-44, 63), "无敌人 / Boss 前补给", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8fd6d2"))
			"boss":
				_draw_boss_chamber(inner)
				_draw_spawn_cross(inner.get_center() + Vector2(0, 8), Color("#ff5f4f"), "Boss")
				_draw_spore_pod(inner.position + Vector2(78, 136), false)
				_draw_spore_pod(inner.position + Vector2(324, 88), false)

	func _draw_room_doors(rect: Rect2, cyan: Color, amber: Color) -> void:
		var mid_x := rect.position.x + rect.size.x / 2.0
		var mid_y := rect.position.y + rect.size.y / 2.0
		draw_rect(Rect2(Vector2(mid_x - 35, rect.position.y + 3), Vector2(70, 16)), Color("#2b2119"))
		draw_rect(Rect2(Vector2(mid_x - 28, rect.end.y - 19), Vector2(56, 16)), Color("#2b2119"))
		draw_rect(Rect2(Vector2(rect.position.x + 3, mid_y - 28), Vector2(16, 56)), Color("#2b2119"))
		draw_rect(Rect2(Vector2(rect.end.x - 19, mid_y - 28), Vector2(16, 56)), Color("#2b2119"))
		draw_line(Vector2(mid_x - 24, rect.position.y + 13), Vector2(mid_x + 24, rect.position.y + 13), cyan, 2.0)
		draw_line(Vector2(mid_x - 24, rect.end.y - 11), Vector2(mid_x + 24, rect.end.y - 11), cyan, 2.0)
		draw_rect(Rect2(Vector2(mid_x - 47, rect.position.y + 20), Vector2(94, 6)), amber)
		draw_rect(Rect2(Vector2(mid_x - 47, rect.end.y - 26), Vector2(94, 6)), amber)

	func _draw_airlock(inner: Rect2) -> void:
		var c := inner.get_center()
		draw_rect(Rect2(c + Vector2(-100, -58), Vector2(200, 38)), Color("#0d2b30"), false, 3.0)
		draw_rect(Rect2(c + Vector2(-80, -46), Vector2(160, 10)), Color("#48d6d8"))
		draw_rect(Rect2(c + Vector2(-56, 18), Vector2(112, 18)), Color("#243e40"))
		draw_line(c + Vector2(-72, 64), c + Vector2(72, 64), Color("#d9952d"), 4.0)

	func _draw_planter(pos: Vector2, clean: bool) -> void:
		draw_rect(Rect2(pos, Vector2(86, 42)), Color("#243534"))
		draw_rect(Rect2(pos + Vector2(7, 7), Vector2(72, 28)), Color("#10231a"))
		var leaf := Color("#76f078") if clean else Color("#a4ff55")
		for i in range(5):
			draw_circle(pos + Vector2(18 + i * 13, 21 + sin(float(i)) * 5), 7.0, leaf)

	func _draw_culture_tank(pos: Vector2, liquid: Color) -> void:
		draw_rect(Rect2(pos, Vector2(42, 74)), Color("#18292c"))
		draw_rect(Rect2(pos + Vector2(7, 8), Vector2(28, 54)), Color("#1e6063"))
		draw_rect(Rect2(pos + Vector2(10, 16), Vector2(22, 38)), liquid)
		draw_line(pos + Vector2(8, 8), pos + Vector2(34, 8), Color("#8efcf0"), 2.0)

	func _draw_vine_barrier(pos: Vector2, width: float) -> void:
		for i in range(0, int(width), 18):
			var x := pos.x + i
			draw_line(Vector2(x, pos.y), Vector2(x + 26, pos.y + 18), Color("#2d6c37"), 6.0)
			draw_circle(Vector2(x + 12, pos.y + 8), 5.0, Color("#8df06e"))
		draw_line(pos + Vector2(0, 24), pos + Vector2(width, 24), Color("#d9952d"), 3.0)

	func _draw_spore_pod(pos: Vector2, objective: bool) -> void:
		var pod_color := Color("#84ec6a") if objective else Color("#557d43")
		draw_circle(pos, 21.0, Color("#17301d"))
		draw_circle(pos, 16.0, pod_color)
		draw_circle(pos + Vector2(-5, -5), 6.0, Color("#d8ff9a"))
		if objective:
			draw_arc(pos, 28.0, 0.0, TAU, 24, Color("#ffb348"), 3.0)

	func _draw_sample_cache(pos: Vector2, label: String) -> void:
		draw_rect(Rect2(pos + Vector2(-44, -22), Vector2(88, 44)), Color("#233537"))
		draw_rect(Rect2(pos + Vector2(-34, -12), Vector2(68, 24)), Color("#4ee1da"))
		draw_rect(Rect2(pos + Vector2(-20, 17), Vector2(40, 6)), Color("#d9952d"))
		draw_string(font, pos + Vector2(-28, 48), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#d8fff2"))

	func _draw_raven_counter(inner: Rect2) -> void:
		var c := inner.get_center()
		draw_rect(Rect2(c + Vector2(-52, -16), Vector2(128, 52)), Color("#0c1719"))
		draw_rect(Rect2(c + Vector2(-39, -4), Vector2(78, 12)), Color("#8affcf"))
		draw_polygon([
			c + Vector2(70, -36),
			c + Vector2(106, -18),
			c + Vector2(96, 36),
			c + Vector2(60, 34),
		], [Color("#050606")])
		draw_circle(c + Vector2(85, -13), 6.0, Color("#ffd15b"))
		draw_string(font, c + Vector2(58, 57), "渡鸦", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#d8fff2"))

	func _draw_terminal(pos: Vector2) -> void:
		draw_rect(Rect2(pos + Vector2(-36, -22), Vector2(72, 44)), Color("#111c1d"))
		draw_rect(Rect2(pos + Vector2(-25, -10), Vector2(50, 14)), Color("#45dcd2"))
		draw_line(pos + Vector2(-28, 20), pos + Vector2(28, 20), Color("#d9952d"), 3.0)

	func _draw_boss_chamber(inner: Rect2) -> void:
		var c := inner.get_center()
		draw_circle(c + Vector2(0, 4), 72.0, Color("#193220"))
		draw_circle(c + Vector2(0, 4), 50.0, Color("#314a42"))
		draw_rect(Rect2(c + Vector2(-24, -56), Vector2(48, 112)), Color("#182528"))
		draw_rect(Rect2(c + Vector2(-15, -42), Vector2(30, 84)), Color("#68d56d"))
		for angle in [0.0, PI / 2.0, PI, PI * 1.5]:
			var dir := Vector2(cos(angle), sin(angle))
			draw_line(c, c + dir * 130.0, Color("#2f7a42"), 8.0)

	func _draw_enemy_card(rect: Rect2, label: String, role: String, index: int) -> void:
		draw_rect(rect, Color("#10191b"))
		draw_rect(rect, Color("#1e6c6a"), false, 2.0)
		draw_rect(Rect2(rect.position + Vector2(12, 12), Vector2(rect.size.x - 24, 28)), Color("#123438"))
		draw_string(font, rect.position + Vector2(25, 32), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#d8fff2"))
		draw_string(font, rect.position + Vector2(25, 58), role, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8fd6d2"))
		var c := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.58)
		_draw_enemy_sprite(c, index)
		draw_circle(c, 34.0, Color(0, 0, 0, 0.22))
		draw_arc(c, 46.0, 0.0, TAU, 24, Color("#365557"), 1.0)

	func _draw_enemy_sprite(c: Vector2, index: int) -> void:
		match index:
			0:
				draw_rect(Rect2(c + Vector2(-27, -17), Vector2(54, 34)), Color("#244529"))
				draw_circle(c + Vector2(-27, 0), 17.0, Color("#244529"))
				draw_circle(c + Vector2(27, 0), 17.0, Color("#244529"))
				draw_circle(c + Vector2(-18, -3), 13.0, Color("#8df06e"))
				draw_circle(c + Vector2(17, 0), 13.0, Color("#62be55"))
				_draw_spore_trail(c + Vector2(48, -6))
			1:
				draw_rect(Rect2(c + Vector2(-24, -32), Vector2(48, 64)), Color("#213323"))
				draw_circle(c, 24.0, Color("#77dd62"))
				draw_line(c + Vector2(18, -6), c + Vector2(98, -26), Color("#ff8d39"), 4.0)
				draw_circle(c + Vector2(108, -29), 7.0, Color("#8affcf"))
			2:
				for offset in [Vector2(-28, -4), Vector2(0, -14), Vector2(28, 2)]:
					draw_circle(c + offset, 14.0, Color("#323338"))
					draw_circle(c + offset + Vector2(0, -2), 8.0, Color("#9cff5d"))
					draw_line(c + offset, c + offset + Vector2(20, -20), Color("#6bbd59"), 2.0)
			3:
				draw_rect(Rect2(c + Vector2(-34, -38), Vector2(68, 76)), Color("#28343a"))
				draw_rect(Rect2(c + Vector2(-22, -26), Vector2(44, 52)), Color("#83de69"))
				draw_line(c + Vector2(-42, 38), c + Vector2(42, 38), Color("#d9952d"), 5.0)
			4:
				draw_circle(c, 31.0, Color("#5aa75a"))
				draw_circle(c + Vector2(-8, -7), 15.0, Color("#d8ff83"))
				draw_polygon([c + Vector2(22, -18), c + Vector2(62, 0), c + Vector2(22, 18)], [Color("#9dff55")])
				draw_arc(c, 43.0, 0.2, 1.4, 16, Color("#74f56a"), 4.0)
			5:
				draw_polygon([
					c + Vector2(0, -43),
					c + Vector2(34, -18),
					c + Vector2(26, 34),
					c + Vector2(-26, 34),
					c + Vector2(-34, -18),
				], [Color("#23402d")])
				draw_circle(c, 23.0, Color("#93f16e"))
				draw_line(c, c + Vector2(72, 22), Color("#ff8d39"), 4.0)
				draw_arc(c, 58.0, -0.5, 0.8, 18, Color("#a3ff66"), 3.0)

	func _draw_spore_trail(pos: Vector2) -> void:
		for i in range(4):
			draw_circle(pos + Vector2(i * 16, sin(float(i)) * 8.0), 5.0, Color("#9bff63"))

	func _draw_enemy_marker(pos: Vector2, text: String) -> void:
		draw_circle(pos, 16.0, Color("#081111"))
		draw_circle(pos, 12.0, Color("#ff6f47"))
		draw_circle(pos, 7.0, Color("#0b1112"))
		draw_string(font, pos + Vector2(-7, 34), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#ffcab6"))

	func _draw_spawn_cross(pos: Vector2, color: Color, text: String) -> void:
		draw_line(pos + Vector2(-24, 0), pos + Vector2(24, 0), color, 2.0)
		draw_line(pos + Vector2(0, -24), pos + Vector2(0, 24), color, 2.0)
		draw_circle(pos, 5.0, color)
		draw_string(font, pos + Vector2(14, -12), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)

	func _draw_label_badge(pos: Vector2, text: String) -> void:
		draw_rect(Rect2(pos, Vector2(148, 25)), Color("#071315"))
		draw_rect(Rect2(pos, Vector2(148, 25)), Color("#2bd1cd"), false, 1.0)
		draw_string(font, pos + Vector2(10, 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#d8fff2"))

	func _draw_hazard_stripes(rect: Rect2, color: Color) -> void:
		draw_rect(rect, Color("#1d1710"))
		for x in range(int(rect.position.x), int(rect.end.x), 18):
			draw_line(Vector2(x, rect.end.y), Vector2(x + 12, rect.position.y), color, 3.0)

	func _draw_legend(pos: Vector2) -> void:
		var text := "图例：橙环=敌人出生点  黄环孢子囊=事件目标  青色=可交互/门/终端  绿色=温室生态危险物"
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#9fded7"))


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _render_preview("rooms", OUT_ROOMS)
	await _render_preview("enemies", OUT_ENEMIES)
	print("Saved Godot greenhouse previews:")
	print(ProjectSettings.globalize_path(OUT_ROOMS))
	print(ProjectSettings.globalize_path(OUT_ENEMIES))
	quit(0)


func _render_preview(mode: String, output_path: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = IMAGE_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var canvas := PreviewCanvas.new()
	canvas.mode = mode
	viewport.add_child(canvas)

	await process_frame
	await process_frame

	var image := viewport.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(output_path))
	viewport.queue_free()
	await process_frame
