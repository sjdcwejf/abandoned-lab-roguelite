class_name ExosuitFactoryOverlay
extends Node2D


const FACILITY_CRATES_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/crates_spritesheet.png")
const FACILITY_DOODADS_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/doodads_spritesheet.png")
const FACILITY_COMPUTER_TEXTURE = preload("res://tiny_wizard/assets/third_party/sci_fi_facility/computer_spritesheet.png")
const LAB_STUFF_TEXTURE = preload("res://tiny_wizard/assets/third_party/land_of_pixels_lab/32px/tilesStuff.png")
const ROBOT_FACTORY_PAGE_01 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_01.png")
const ROBOT_FACTORY_PAGE_03 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_03.png")
const ROBOT_FACTORY_PAGE_04 = preload("res://tiny_wizard/assets/third_party/robot_factory_tileset_pack/page_04.png")

@export var variant := "combat"


func _ready() -> void:
	z_index = -2
	_build_floor_tint()
	_build_industrial_floor_panels()
	_build_tile_grid()
	_build_warning_tracks()
	_build_energy_lines()
	_build_factory_equipment()
	_build_factory_asset_props()
	_build_robot_factory_props()
	_build_solid_blocking_props()
	_build_oil_scuffs()


func _build_floor_tint() -> void:
	var floor := Polygon2D.new()
	floor.name = "FactoryFloorTint"
	floor.color = Color(0.075, 0.078, 0.085, 0.58)
	floor.polygon = PackedVector2Array([
		Vector2(72, 92),
		Vector2(952, 92),
		Vector2(952, 508),
		Vector2(72, 508),
	])
	add_child(floor)


func _build_tile_grid() -> void:
	for x in range(128, 912, 64):
		_add_line(Vector2(x, 104), Vector2(x, 496), Color(0.28, 0.31, 0.33, 0.26), 1.0)
	for y in range(128, 488, 64):
		_add_line(Vector2(86, y), Vector2(938, y), Color(0.28, 0.31, 0.33, 0.26), 1.0)


func _build_industrial_floor_panels() -> void:
	for x in range(128, 896, 96):
		for y in range(128, 488, 96):
			var color := Color(0.12, 0.12, 0.12, 0.32)
			if (x / 96 + y / 96) % 2 == 0:
				color = Color(0.07, 0.075, 0.08, 0.44)
			_add_floor_panel(Vector2(x + 32, y + 32), Vector2(72, 72), color)


func _build_warning_tracks() -> void:
	var strips := _variant_warning_strips()
	for strip in strips:
		_add_warning_strip(strip.get("position", Vector2.ZERO), strip.get("size", Vector2(150, 22)), bool(strip.get("vertical", false)))


func _build_energy_lines() -> void:
	var lines := _variant_energy_lines()
	for line in lines:
		_add_line(
			line.get("from", Vector2.ZERO),
			line.get("to", Vector2.ZERO),
			line.get("color", Color(0.22, 0.82, 0.96, 0.42)),
			line.get("width", 3.0)
		)


func _build_factory_equipment() -> void:
	for item in _variant_equipment():
		_add_equipment(
			item.get("position", Vector2.ZERO),
			item.get("size", Vector2(90, 44)),
			item.get("kind", "rack"),
			bool(item.get("glow", false))
		)


func _build_factory_asset_props() -> void:
	for prop in _variant_asset_props():
		var texture: Texture2D = prop.get("texture") as Texture2D
		var region: Rect2 = prop.get("region", Rect2(0, 0, 16, 16)) as Rect2
		var position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
		var scale_value: Vector2 = prop.get("scale", Vector2.ONE) as Vector2
		var color: Color = prop.get("modulate", Color.WHITE) as Color
		_add_asset_sprite(texture, region, position, scale_value, color)


func _build_robot_factory_props() -> void:
	for prop in _variant_robot_factory_props():
		var texture: Texture2D = prop.get("texture") as Texture2D
		var region: Rect2 = prop.get("region", Rect2(0, 0, 64, 64)) as Rect2
		var position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
		var scale_value: Vector2 = prop.get("scale", Vector2.ONE) as Vector2
		var color: Color = prop.get("modulate", Color.WHITE) as Color
		var z_value := int(prop.get("z_index", 4))
		_add_asset_sprite(texture, region, position, scale_value, color, z_value)


func _build_solid_blocking_props() -> void:
	for prop in _variant_solid_blocking_props():
		var position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = prop.get("size", Vector2(64, 64)) as Vector2
		var name_suffix := str(prop.get("name", "Factory"))
		_add_solid_blocking_prop(name_suffix, position, size)


func _build_oil_scuffs() -> void:
	var scuffs := [
		{"position": Vector2(332, 406), "size": Vector2(130, 42), "alpha": 0.26},
		{"position": Vector2(708, 202), "size": Vector2(118, 38), "alpha": 0.22},
		{"position": Vector2(540, 448), "size": Vector2(160, 34), "alpha": 0.2},
	]
	for scuff in scuffs:
		var position: Vector2 = scuff.get("position", Vector2.ZERO) as Vector2
		var size: Vector2 = scuff.get("size", Vector2(100, 30)) as Vector2
		var alpha := float(scuff.get("alpha", 0.2))
		_add_oil_scuff(position, size, alpha)


func _variant_warning_strips() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(512, 176), "size": Vector2(260, 22)},
				{"position": Vector2(512, 424), "size": Vector2(260, 22)},
			]
		"test":
			return [
				{"position": Vector2(512, 160), "size": Vector2(300, 22)},
				{"position": Vector2(512, 440), "size": Vector2(300, 22)},
				{"position": Vector2(222, 300), "size": Vector2(162, 22), "vertical": true},
				{"position": Vector2(802, 300), "size": Vector2(162, 22), "vertical": true},
			]
		"merchant":
			return [
				{"position": Vector2(512, 200), "size": Vector2(340, 22)},
				{"position": Vector2(512, 422), "size": Vector2(300, 22)},
			]
		"boss":
			return [
				{"position": Vector2(512, 154), "size": Vector2(420, 24)},
				{"position": Vector2(512, 446), "size": Vector2(420, 24)},
				{"position": Vector2(180, 300), "size": Vector2(260, 22), "vertical": true},
				{"position": Vector2(844, 300), "size": Vector2(260, 22), "vertical": true},
			]
	return [
		{"position": Vector2(512, 154), "size": Vector2(280, 20)},
		{"position": Vector2(512, 446), "size": Vector2(280, 20)},
	]


func _variant_energy_lines() -> Array[Dictionary]:
	match variant:
		"weapon":
			return [
				{"from": Vector2(308, 246), "to": Vector2(716, 246), "color": Color(0.24, 0.9, 1.0, 0.52), "width": 4.0},
				{"from": Vector2(308, 380), "to": Vector2(716, 380), "color": Color(0.24, 0.9, 1.0, 0.38), "width": 3.0},
			]
		"merchant":
			return [
				{"from": Vector2(360, 300), "to": Vector2(664, 300), "color": Color(0.24, 0.9, 1.0, 0.48), "width": 4.0},
			]
		"boss":
			return [
				{"from": Vector2(248, 300), "to": Vector2(776, 300), "color": Color(0.9, 0.18, 0.12, 0.45), "width": 4.0},
				{"from": Vector2(512, 174), "to": Vector2(512, 426), "color": Color(0.9, 0.18, 0.12, 0.28), "width": 3.0},
			]
	return [
		{"from": Vector2(250, 302), "to": Vector2(774, 302), "color": Color(0.24, 0.9, 1.0, 0.22), "width": 2.0},
	]


func _variant_equipment() -> Array[Dictionary]:
	match variant:
		"start":
			return [
				{"position": Vector2(208, 300), "size": Vector2(112, 236), "kind": "pipe", "glow": true},
				{"position": Vector2(816, 300), "size": Vector2(112, 236), "kind": "pipe", "glow": true},
				{"position": Vector2(512, 120), "size": Vector2(260, 42), "kind": "door"},
			]
		"drone":
			return [
				{"position": Vector2(206, 220), "size": Vector2(124, 86), "kind": "rack"},
				{"position": Vector2(818, 396), "size": Vector2(124, 86), "kind": "rack"},
				{"position": Vector2(512, 128), "size": Vector2(300, 42), "kind": "conveyor"},
				{"position": Vector2(512, 472), "size": Vector2(300, 42), "kind": "conveyor"},
			]
		"test":
			return [
				{"position": Vector2(188, 302), "size": Vector2(92, 240), "kind": "rack", "glow": true},
				{"position": Vector2(836, 302), "size": Vector2(92, 240), "kind": "rack", "glow": true},
			]
		"weapon":
			return [
				{"position": Vector2(228, 304), "size": Vector2(126, 230), "kind": "rack", "glow": true},
				{"position": Vector2(796, 304), "size": Vector2(126, 230), "kind": "rack", "glow": true},
				{"position": Vector2(512, 236), "size": Vector2(188, 44), "kind": "terminal", "glow": true},
			]
		"elite":
			return [
				{"position": Vector2(188, 196), "size": Vector2(130, 84), "kind": "bay", "glow": true},
				{"position": Vector2(836, 404), "size": Vector2(130, 84), "kind": "bay", "glow": true},
				{"position": Vector2(512, 120), "size": Vector2(310, 42), "kind": "conveyor"},
			]
		"merchant":
			return [
				{"position": Vector2(512, 224), "size": Vector2(320, 76), "kind": "terminal", "glow": true},
				{"position": Vector2(216, 390), "size": Vector2(118, 140), "kind": "rack"},
				{"position": Vector2(808, 390), "size": Vector2(118, 140), "kind": "rack"},
			]
		"boss":
			return [
				{"position": Vector2(512, 130), "size": Vector2(420, 80), "kind": "door", "glow": true},
				{"position": Vector2(184, 302), "size": Vector2(100, 300), "kind": "bay", "glow": true},
				{"position": Vector2(840, 302), "size": Vector2(100, 300), "kind": "bay", "glow": true},
			]
	return [
		{"position": Vector2(184, 306), "size": Vector2(100, 240), "kind": "rack", "glow": true},
		{"position": Vector2(840, 306), "size": Vector2(100, 240), "kind": "rack", "glow": true},
		{"position": Vector2(512, 128), "size": Vector2(280, 42), "kind": "conveyor"},
	]


func _variant_asset_props() -> Array[Dictionary]:
	var crate_region := Rect2(0, 0, 16, 16)
	var metal_crate_region := Rect2(16, 0, 16, 16)
	var parts_bin_region := Rect2(32, 48, 16, 16)
	var tool_region := Rect2(32, 0, 16, 16)
	var computer_region := Rect2(0, 0, 16, 16)
	var terminal_region := Rect2(882, 304, 80, 56)
	match variant:
		"start":
			return [
				{"texture": FACILITY_CRATES_TEXTURE, "region": crate_region, "position": Vector2(212, 420), "scale": Vector2(1.6, 1.6)},
				{"texture": FACILITY_CRATES_TEXTURE, "region": metal_crate_region, "position": Vector2(812, 178), "scale": Vector2(1.6, 1.6)},
				{"texture": FACILITY_COMPUTER_TEXTURE, "region": computer_region, "position": Vector2(512, 132), "scale": Vector2(1.8, 1.8), "modulate": Color(1.0, 0.86, 0.65, 0.9)},
			]
		"weapon", "merchant":
			return [
				{"texture": LAB_STUFF_TEXTURE, "region": terminal_region, "position": Vector2(512, 224), "scale": Vector2(1.0, 1.0), "modulate": Color(1.0, 0.82, 0.55, 0.92)},
				{"texture": FACILITY_CRATES_TEXTURE, "region": parts_bin_region, "position": Vector2(230, 420), "scale": Vector2(1.7, 1.7)},
				{"texture": FACILITY_CRATES_TEXTURE, "region": parts_bin_region, "position": Vector2(794, 420), "scale": Vector2(1.7, 1.7)},
				{"texture": FACILITY_DOODADS_TEXTURE, "region": tool_region, "position": Vector2(366, 390), "scale": Vector2(1.5, 1.5), "modulate": Color(1.0, 0.72, 0.4, 0.9)},
			]
		"test", "elite", "boss":
			return [
				{"texture": FACILITY_CRATES_TEXTURE, "region": metal_crate_region, "position": Vector2(186, 186), "scale": Vector2(1.7, 1.7)},
				{"texture": FACILITY_CRATES_TEXTURE, "region": metal_crate_region, "position": Vector2(838, 414), "scale": Vector2(1.7, 1.7)},
				{"texture": FACILITY_DOODADS_TEXTURE, "region": Rect2(0, 16, 16, 16), "position": Vector2(512, 152), "scale": Vector2(1.6, 1.6), "modulate": Color(1.0, 0.45, 0.28, 0.88)},
			]
	return [
		{"texture": FACILITY_CRATES_TEXTURE, "region": crate_region, "position": Vector2(202, 420), "scale": Vector2(1.5, 1.5)},
		{"texture": FACILITY_CRATES_TEXTURE, "region": metal_crate_region, "position": Vector2(822, 182), "scale": Vector2(1.5, 1.5)},
		{"texture": FACILITY_DOODADS_TEXTURE, "region": tool_region, "position": Vector2(512, 128), "scale": Vector2(1.4, 1.4), "modulate": Color(1.0, 0.72, 0.36, 0.86)},
	]


func _variant_robot_factory_props() -> Array[Dictionary]:
	match variant:
		"weapon":
			return [
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(0, 0, 184, 110), "position": Vector2(230, 290), "scale": Vector2(0.55, 0.55), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(0, 106, 184, 118), "position": Vector2(796, 292), "scale": Vector2(0.55, 0.55), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(396, 318, 180, 82), "position": Vector2(512, 224), "scale": Vector2(0.78, 0.78), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(576, 408, 132, 112), "position": Vector2(350, 420), "scale": Vector2(0.7, 0.7), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(344, 522, 128, 96), "position": Vector2(674, 420), "scale": Vector2(0.68, 0.68), "z_index": 5},
			]
		"combat":
			return [
				{"texture": ROBOT_FACTORY_PAGE_03, "region": Rect2(250, 100, 500, 92), "position": Vector2(512, 150), "scale": Vector2(0.86, 0.86), "z_index": 4},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(0, 0, 184, 110), "position": Vector2(238, 260), "scale": Vector2(0.58, 0.58), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(0, 106, 184, 118), "position": Vector2(786, 342), "scale": Vector2(0.58, 0.58), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(204, 0, 240, 80), "position": Vector2(512, 430), "scale": Vector2(0.92, 0.72), "z_index": 3},
				{"texture": ROBOT_FACTORY_PAGE_01, "region": Rect2(370, 530, 260, 88), "position": Vector2(512, 220), "scale": Vector2(0.82, 0.82), "z_index": 4},
			]
		"elite", "boss":
			return [
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(0, 520, 256, 170), "position": Vector2(190, 314), "scale": Vector2(0.56, 0.56), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_04, "region": Rect2(0, 520, 256, 170), "position": Vector2(834, 314), "scale": Vector2(0.56, 0.56), "z_index": 5},
				{"texture": ROBOT_FACTORY_PAGE_03, "region": Rect2(376, 0, 376, 110), "position": Vector2(512, 146), "scale": Vector2(0.92, 0.92), "z_index": 5},
			]
	return []


func _variant_solid_blocking_props() -> Array[Dictionary]:
	match variant:
		"weapon":
			return [
				{"name": "LeftExosuitRack", "position": Vector2(230, 304), "size": Vector2(104, 210)},
				{"name": "RightExosuitRack", "position": Vector2(796, 304), "size": Vector2(104, 210)},
				{"name": "QualityTerminal", "position": Vector2(512, 224), "size": Vector2(168, 54)},
				{"name": "LeftPartsTable", "position": Vector2(350, 420), "size": Vector2(88, 52)},
				{"name": "RightPartsTable", "position": Vector2(674, 420), "size": Vector2(88, 52)},
			]
		"combat":
			return [
				{"name": "LeftRobotArmBase", "position": Vector2(238, 262), "size": Vector2(84, 84)},
				{"name": "RightRobotArmBase", "position": Vector2(786, 342), "size": Vector2(84, 84)},
				{"name": "NorthAssemblyBridge", "position": Vector2(512, 150), "size": Vector2(370, 42)},
				{"name": "CenterPartsBench", "position": Vector2(512, 220), "size": Vector2(190, 48)},
			]
		"elite", "boss":
			return [
				{"name": "LeftMechFrame", "position": Vector2(190, 314), "size": Vector2(92, 210)},
				{"name": "RightMechFrame", "position": Vector2(834, 314), "size": Vector2(92, 210)},
				{"name": "NorthCraneBridge", "position": Vector2(512, 146), "size": Vector2(350, 52)},
			]
	return []


func _add_warning_strip(center: Vector2, size: Vector2, vertical := false) -> void:
	var half := size * 0.5
	var body := Polygon2D.new()
	body.name = "WarningStrip"
	body.color = Color(0.62, 0.38, 0.08, 0.42)
	if vertical:
		body.polygon = PackedVector2Array([
			center + Vector2(-half.y, -half.x),
			center + Vector2(half.y, -half.x),
			center + Vector2(half.y, half.x),
			center + Vector2(-half.y, half.x),
		])
	else:
		body.polygon = PackedVector2Array([
			center + Vector2(-half.x, -half.y),
			center + Vector2(half.x, -half.y),
			center + Vector2(half.x, half.y),
			center + Vector2(-half.x, half.y),
		])
	add_child(body)

	var stripe_count := 8
	for i in range(stripe_count):
		var offset := -half.x + i * (size.x / float(stripe_count))
		if vertical:
			_add_line(center + Vector2(-half.y, offset), center + Vector2(half.y, offset + 18), Color(1.0, 0.68, 0.12, 0.55), 2.0)
		else:
			_add_line(center + Vector2(offset, -half.y), center + Vector2(offset + 18, half.y), Color(1.0, 0.68, 0.12, 0.55), 2.0)


func _add_floor_panel(center: Vector2, size: Vector2, color: Color) -> void:
	var half := size * 0.5
	var panel := Polygon2D.new()
	panel.name = "FactoryFloorPanel"
	panel.color = color
	panel.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(panel)


func _add_oil_scuff(center: Vector2, size: Vector2, alpha: float) -> void:
	var half := size * 0.5
	var scuff := Polygon2D.new()
	scuff.name = "OilScuff"
	scuff.color = Color(0.01, 0.01, 0.012, alpha)
	scuff.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y * 0.2),
		center + Vector2(-half.x * 0.42, -half.y),
		center + Vector2(half.x * 0.76, -half.y * 0.55),
		center + Vector2(half.x, half.y * 0.12),
		center + Vector2(half.x * 0.34, half.y),
		center + Vector2(-half.x * 0.7, half.y * 0.62),
	])
	add_child(scuff)


func _add_asset_sprite(texture: Texture2D, region: Rect2, position: Vector2, scale_value: Vector2, color: Color, z_value := 3) -> void:
	if texture == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	var sprite := Sprite2D.new()
	sprite.name = "FactoryAssetProp"
	sprite.texture = atlas
	sprite.position = position
	sprite.scale = scale_value
	sprite.modulate = color
	sprite.z_index = z_value
	add_child(sprite)


func _add_solid_blocking_prop(name_suffix: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "SolidBlocker%s" % name_suffix
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 15
	body.add_to_group("solid_blocking_prop")
	body.set_meta("solid_blocking_prop", true)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _add_equipment(center: Vector2, size: Vector2, kind: String, glow: bool) -> void:
	var half := size * 0.5
	var body := Polygon2D.new()
	body.name = "FactoryEquipment"
	body.color = Color(0.075, 0.088, 0.098, 0.86)
	if kind == "bay":
		body.color = Color(0.09, 0.08, 0.076, 0.88)
	elif kind == "terminal":
		body.color = Color(0.045, 0.06, 0.064, 0.9)
	body.polygon = PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])
	add_child(body)

	var rim_color := Color(0.26, 0.86, 0.98, 0.68) if glow else Color(0.62, 0.66, 0.64, 0.42)
	_add_line(center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), rim_color, 2.0)
	_add_line(center + Vector2(half.x, -half.y), center + Vector2(half.x, half.y), rim_color, 2.0)
	_add_line(center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y), rim_color, 2.0)
	_add_line(center + Vector2(-half.x, half.y), center + Vector2(-half.x, -half.y), rim_color, 2.0)

	if kind in ["rack", "bay"]:
		for line_index in range(3):
			var y := center.y - half.y * 0.45 + line_index * half.y * 0.45
			_add_line(Vector2(center.x - half.x * 0.64, y), Vector2(center.x + half.x * 0.64, y), Color(0.72, 0.78, 0.76, 0.28), 2.0)
	if kind == "conveyor":
		for line_index in range(4):
			var x := center.x - half.x * 0.75 + line_index * half.x * 0.5
			_add_line(Vector2(x, center.y - half.y * 0.42), Vector2(x + 42, center.y + half.y * 0.42), Color(0.85, 0.55, 0.12, 0.34), 2.0)
	if glow:
		_add_line(center + Vector2(-half.x * 0.54, 0), center + Vector2(half.x * 0.54, 0), Color(0.35, 0.95, 1.0, 0.72), 3.0)


func _add_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.name = "FactoryLine"
	line.z_index = 1
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	add_child(line)
