class_name LabRavenMerchant
extends Node2D


const CURRENCY_NAME := "Protomatter Fragment"
const CURRENCY_DISPLAY_NAME := "原质碎片"
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const WEAPON_STOCK := [
	preload("res://tiny_wizard/player/weapons/laser_pointer/laser_pointer.tscn"),
	preload("res://tiny_wizard/player/weapons/containment_nailgun/containment_nailgun.tscn"),
	preload("res://tiny_wizard/player/weapons/energy_saber/energy_saber.tscn"),
	preload("res://tiny_wizard/player/weapons/power_gauntlets/power_gauntlets.tscn"),
	preload("res://tiny_wizard/player/weapons/test_sword/test_sword.tscn"),
]
const BUILD_CATALOG := preload("res://tiny_wizard/build/test_data/test_build_catalog.tres")

@export var merchant_title := "渡鸦检疫军械库"
@export_multiline var merchant_message := "A-03 信号就在前方。补好神经接口，数清你的炸药。"
@export_range(0, 99, 1) var weapon_cost := 1
@export_range(0, 99, 1) var organ_cost := 2
@export_range(0, 99, 1) var relic_cost := 2
@export var equip_purchase_immediately := false

var _candidate_character: Node2D
var _dialog_open := false
var _selected_weapon_scene: PackedScene
var _selected_weapon_name := ""
var _offer_preview_instance: Node2D
var _stock_generated := false
var _organ_offer: BuildItemDefinition
var _relic_offer: BuildItemDefinition

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: CanvasItem = $Prompt
@onready var dialog_panel: Control = $DialogPanel
@onready var title_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Title
@onready var message_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Message
@onready var stock_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Stock
@onready var status_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Status
@onready var hint_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Hint
@onready var status_light: CanvasItem = $Console/StatusLight
@onready var offer_preview: Node2D = $Console/OfferPreview


func _ready() -> void:
	CHINESE_FONT_BOOTSTRAP.apply_to_tree(self)
	prompt.visible = false
	dialog_panel.visible = false
	title_label.text = merchant_title
	message_label.text = merchant_message
	stock_label.text = ""
	status_label.text = ""
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)


func _process(_delta: float) -> void:
	if _candidate_character == null:
		return
	if Input.is_action_just_pressed("interact"):
		if _dialog_open:
			_try_purchase(_candidate_character)
		else:
			_open_armory(_candidate_character)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	_ensure_stock(body)
	prompt.visible = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
	_set_dialog_open(false)


func _open_armory(character: Node2D) -> void:
	_ensure_stock(character)
	_refresh_offer(character)
	_set_dialog_open(true)


func _set_dialog_open(open: bool) -> void:
	_dialog_open = open
	dialog_panel.visible = _dialog_open
	if status_light is Polygon2D:
		var light := status_light as Polygon2D
		light.color = Color(0.65, 1.0, 0.62, 1.0) if _dialog_open else Color(0.28, 0.9, 0.95, 1.0)


func _refresh_offer(character: Node2D) -> void:
	var lines := PackedStringArray()
	if _selected_weapon_scene != null:
		_selected_weapon_name = _get_weapon_name(_selected_weapon_scene)
		lines.append("[F] Weapon: %s - %d %s" % [_selected_weapon_name, weapon_cost, CURRENCY_DISPLAY_NAME])
		_build_offer_preview(_selected_weapon_scene)
	else:
		lines.append("[F] Weapon: sold out")
		_clear_offer_preview()
	lines.append("[2] Organ: %s" % _format_build_offer(_organ_offer, organ_cost))
	lines.append("[3] Relic: %s" % _format_build_offer(_relic_offer, relic_cost))
	stock_label.text = "\n".join(lines)
	status_label.text = "You have %d %s." % [_get_currency_count(character), CURRENCY_DISPLAY_NAME]
	hint_label.text = "F: weapon | 2: organ | 3: relic"


func _refresh_offer_legacy(character: Node2D) -> void:
	_selected_weapon_scene = _pick_unowned_weapon(character)
	if _selected_weapon_scene == null:
		_selected_weapon_name = ""
		_clear_offer_preview()
		stock_label.text = "库存：当前构筑无可售新武器。"
		status_label.text = "渡鸦暂时没有新的东西卖给你。"
		hint_label.text = "准备好后离开检疫商店。"
		return

	_selected_weapon_name = _get_weapon_name(_selected_weapon_scene)
	_build_offer_preview(_selected_weapon_scene)
	var currency_count := _get_currency_count(character)
	if weapon_cost <= 0:
		stock_label.text = "库存：%s\n价格：免费" % _selected_weapon_name
		status_label.text = "不需要消耗%s。" % CURRENCY_DISPLAY_NAME
		hint_label.text = "按 F 领取。"
	else:
		stock_label.text = "库存：%s\n价格：%d 个%s" % [_selected_weapon_name, weapon_cost, CURRENCY_DISPLAY_NAME]
		status_label.text = "你持有 %d 个%s。" % [currency_count, CURRENCY_DISPLAY_NAME]
		hint_label.text = "按 F 购买。"


func _try_purchase(character: Node2D) -> void:
	if _selected_weapon_scene == null:
		_set_dialog_open(false)
		return

	var inventory := character.get("inventory") as QuiverInventory
	if inventory == null:
		status_label.text = "未检测到背包连接。渡鸦拒绝交易。"
		return

	var currency_count := int(inventory.get_item_amount(CURRENCY_NAME))
	if currency_count < weapon_cost:
		status_label.text = "需要 %d 个%s，你现在有 %d 个。" % [weapon_cost, CURRENCY_DISPLAY_NAME, currency_count]
		return

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		status_label.text = "未检测到武器挂架。"
		return
	if weapon_holder.has_method("has_weapon_scene") and bool(weapon_holder.call("has_weapon_scene", _selected_weapon_scene)):
		status_label.text = "你已经拥有 %s。渡鸦换了一件货。" % _selected_weapon_name
		_refresh_offer(character)
		return

	var purchased_scene := _selected_weapon_scene
	var purchased_name := _selected_weapon_name
	var slot_index := int(weapon_holder.add_weapon_scene(purchased_scene, equip_purchase_immediately))
	if slot_index < 0:
		status_label.text = "武器转移失败。"
		return

	if weapon_cost > 0:
		inventory.remove_item(CURRENCY_NAME, weapon_cost)

	_selected_weapon_scene = null
	_refresh_offer(character)
	if weapon_cost <= 0:
		status_label.text = "已领取 %s，加入 %d 号位。" % [purchased_name, slot_index + 1]
	else:
		status_label.text = "已购买 %s，加入 %d 号位。" % [purchased_name, slot_index + 1]


func _pick_unowned_weapon(character: Node2D) -> PackedScene:
	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null:
		return null

	var owned := {}
	if weapon_holder.has_method("get_owned_weapon_scene_keys"):
		owned = weapon_holder.call("get_owned_weapon_scene_keys") as Dictionary

	for stock_entry in WEAPON_STOCK:
		var weapon_scene: PackedScene = stock_entry as PackedScene
		if weapon_scene == null:
			continue

		var weapon_key := weapon_scene.resource_path
		if weapon_holder.has_method("get_weapon_scene_key"):
			weapon_key = str(weapon_holder.call("get_weapon_scene_key", weapon_scene))
		if not owned.has(weapon_key):
			return weapon_scene

	return null


func _ensure_stock(character: Node2D) -> void:
	if _stock_generated:
		return
	_stock_generated = true
	_selected_weapon_scene = _pick_unowned_weapon(character)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_organ_offer = BuildPoolResolver.pick_candidate(character, BUILD_CATALOG, [&"shop", &"organ"], rng)
	_relic_offer = BuildPoolResolver.pick_candidate(character, BUILD_CATALOG, [&"shop", &"relic"], rng)


func _format_build_offer(definition: BuildItemDefinition, cost: int) -> String:
	if definition == null:
		return "unavailable"
	return "%s - %d %s" % [definition.display_name, cost, CURRENCY_DISPLAY_NAME]


func _unhandled_input(event: InputEvent) -> void:
	if not _dialog_open or _candidate_character == null:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_2:
		_try_purchase_build(_candidate_character, _organ_offer, organ_cost, true)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_3:
		_try_purchase_build(_candidate_character, _relic_offer, relic_cost, false)
		get_viewport().set_input_as_handled()


func _try_purchase_build(character: Node, definition: BuildItemDefinition, cost: int, is_organ_offer: bool) -> bool:
	if definition == null:
		status_label.text = "Build offer unavailable."
		return false
	var controller := character.get_node_or_null("TiemuBuildController") as TiemuBuildController
	var inventory := character.get("inventory") as QuiverInventory
	if controller == null or inventory == null:
		status_label.text = "This character cannot install build items."
		return false
	var currency_count := int(inventory.get_item_amount(CURRENCY_NAME))
	if currency_count < cost:
		status_label.text = "Not enough %s." % CURRENCY_DISPLAY_NAME
		return false
	var result := controller.install(definition)
	if not result.is_success():
		status_label.text = "Installation failed: %s" % result.message
		return false
	if cost > 0:
		inventory.remove_item(CURRENCY_NAME, cost)
	if is_organ_offer:
		_organ_offer = null
	else:
		_relic_offer = null
	status_label.text = "Installed %s." % definition.display_name
	_refresh_offer(character)
	return true


func _get_currency_count(character: Node2D) -> int:
	var inventory := character.get("inventory") as QuiverInventory
	if inventory == null:
		return 0
	return int(inventory.get_item_amount(CURRENCY_NAME))


func _get_weapon_name(weapon_scene: PackedScene) -> String:
	if weapon_scene == null:
		return "未知武器"

	var weapon_name := weapon_scene.resource_path.get_file().get_basename().replace("_", " ").capitalize()
	var weapon := weapon_scene.instantiate()
	if weapon is LabWeapon:
		weapon_name = (weapon as LabWeapon).get_inventory_display_name()
	weapon.free()
	return weapon_name


func _build_offer_preview(weapon_scene: PackedScene) -> void:
	_clear_offer_preview()
	if weapon_scene == null:
		return

	_offer_preview_instance = weapon_scene.instantiate() as Node2D
	if _offer_preview_instance == null:
		return

	offer_preview.add_child(_offer_preview_instance)
	_offer_preview_instance.position = Vector2.ZERO
	_offer_preview_instance.rotation = -0.2
	_offer_preview_instance.scale = Vector2(0.72, 0.72)
	_disable_preview_interaction(_offer_preview_instance)


func _clear_offer_preview() -> void:
	if offer_preview == null:
		return
	for child in offer_preview.get_children():
		child.queue_free()
	_offer_preview_instance = null


func _disable_preview_interaction(root: Node) -> void:
	root.process_mode = Node.PROCESS_MODE_DISABLED
	if root is CollisionObject2D:
		var collision_object := root as CollisionObject2D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
		if collision_object is Area2D:
			(collision_object as Area2D).monitoring = false
			(collision_object as Area2D).monitorable = false

	if root is CollisionShape2D:
		(root as CollisionShape2D).disabled = true

	for child in root.get_children():
		_disable_preview_interaction(child)
