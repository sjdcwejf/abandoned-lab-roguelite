class_name LabRavenMerchant
extends Node2D


const CURRENCY_NAME := "Protomatter Fragment"
const CURRENCY_DISPLAY_NAME := "原质碎片"
const CHINESE_FONT_BOOTSTRAP := preload("res://tiny_wizard/gui/chinese_font_bootstrap.gd")
const INTERACTION_FEEDBACK := preload("res://tiny_wizard/gui/interaction_feedback.gd")
const WEAPON_CHOICE_OVERLAY := preload("res://tiny_wizard/gui/weapon_choice_overlay/weapon_choice_overlay.gd")
const WEAPON_STOCK := [
	preload("res://tiny_wizard/player/weapons/laser_pointer/laser_pointer.tscn"),
	preload("res://tiny_wizard/player/weapons/containment_nailgun/containment_nailgun.tscn"),
	preload("res://tiny_wizard/player/weapons/energy_saber/energy_saber.tscn"),
	preload("res://tiny_wizard/player/weapons/power_gauntlets/power_gauntlets.tscn"),
	preload("res://tiny_wizard/player/weapons/test_sword/test_sword.tscn"),
	preload("res://tiny_wizard/player/weapons/quarantine_shotgun/quarantine_shotgun.tscn"),
]
const OFFER_NONE := "none"
const OFFER_WEAPON := "weapon"

@export var merchant_title := "渡鸦检疫军械库"
@export_multiline var merchant_message := "A-03 信号就在前方。补好神经接口，数清你的炸药。"
@export_range(0, 99, 1) var weapon_cost := 1
@export var equip_purchase_immediately := true
@export var use_weapon_comparison := true

var _candidate_character: Node2D
var _dialog_open := false
var _selected_offer_type := OFFER_NONE
var _selected_weapon_scene: PackedScene
var _selected_weapon_name := ""
var _offer_preview_instance: Node2D
var _awaiting_weapon_replacement := false
var _retired_weapon_keys := {}
var _choice_overlay: LabWeaponChoiceOverlay
var _visual_time := 0.0

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: CanvasItem = $Prompt
@onready var dialog_panel: Control = $DialogPanel
@onready var title_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Title
@onready var message_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Message
@onready var stock_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Stock
@onready var status_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Status
@onready var hint_label: Label = $DialogPanel/MarginContainer/VBoxContainer/Hint
@onready var status_light: CanvasItem = get_node_or_null("CounterStatusLight") as CanvasItem
@onready var offer_preview: Node2D = $OfferPreview
@onready var raven_sprite: Sprite2D = get_node_or_null("RavenSprite") as Sprite2D
@onready var counter_sprite: Sprite2D = get_node_or_null("CounterSprite") as Sprite2D
@onready var counter_scan_line: Polygon2D = get_node_or_null("CounterScanLine") as Polygon2D


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
	_update_idle_visuals(_delta)
	if _candidate_character == null:
		return
	if _has_active_choice_overlay():
		return
	if _dialog_open and _awaiting_weapon_replacement:
		var replacement_slot := _get_pressed_replacement_slot()
		if replacement_slot >= 0:
			_try_purchase(_candidate_character, replacement_slot)
		return
	if Input.is_action_just_pressed("interact"):
		if _dialog_open:
			_try_purchase(_candidate_character)
		else:
			_open_armory(_candidate_character)


func _update_idle_visuals(delta: float) -> void:
	_visual_time += delta
	var slow_pulse := (sin(_visual_time * 2.6) + 1.0) * 0.5
	var fast_pulse := (sin(_visual_time * 7.2) + 1.0) * 0.5

	if raven_sprite != null:
		raven_sprite.position.y = -40.0 + sin(_visual_time * 1.8) * 0.5

	if counter_sprite != null:
		counter_sprite.position.y = -24.0 + sin(_visual_time * 1.4) * 0.18

	if counter_scan_line != null:
		counter_scan_line.position.x = 58.0 + lerpf(-4.0, 4.0, slow_pulse)
		counter_scan_line.color = Color(0.52, 1.0, 1.0, 0.18 + 0.16 * fast_pulse)

	if status_light is Polygon2D and not _dialog_open:
		var light := status_light as Polygon2D
		light.color = Color(0.22 + 0.08 * slow_pulse, 0.78 + 0.16 * slow_pulse, 0.84 + 0.1 * slow_pulse, 1.0)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if not body.has_node("Visual/WeaponHolder"):
		return
	_candidate_character = body
	if prompt is Label:
		(prompt as Label).text = "按 F 交易"
	prompt.visible = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body != _candidate_character:
		return
	_candidate_character = null
	prompt.visible = false
	_set_dialog_open(false)


func _open_armory(character: Node2D) -> void:
	_refresh_offer(character)
	_set_dialog_open(true)


func _set_dialog_open(open: bool) -> void:
	_dialog_open = open
	if not _dialog_open:
		_awaiting_weapon_replacement = false
		_close_choice_overlay()
	dialog_panel.visible = _dialog_open
	if status_light is Polygon2D:
		var light := status_light as Polygon2D
		light.color = Color(0.65, 1.0, 0.62, 1.0) if _dialog_open else Color(0.28, 0.9, 0.95, 1.0)


func _refresh_offer(character: Node2D) -> void:
	_awaiting_weapon_replacement = false
	_selected_weapon_scene = _pick_unowned_weapon(character)
	if _selected_weapon_scene == null:
		_show_no_weapon_stock(character)
		return

	_selected_offer_type = OFFER_WEAPON
	_selected_weapon_name = _get_weapon_name(_selected_weapon_scene)
	_build_offer_preview(_selected_weapon_scene)
	var currency_count := _get_currency_count(character)
	var quick_slots_full := _are_quick_slots_full(character)
	var can_afford := weapon_cost <= 0 or currency_count >= weapon_cost
	var replacement_note := "\n武器栏已满：按 1 / 2 / 3 / 4 选择替换槽位。" if quick_slots_full else "\n购买前会打开武器对比。"
	if weapon_cost <= 0:
		stock_label.text = "库存：%s\n价格：免费%s" % [_selected_weapon_name, replacement_note]
		status_label.text = "不需要消耗%s。" % CURRENCY_DISPLAY_NAME
	else:
		stock_label.text = "库存：%s\n价格：%d 个%s%s" % [_selected_weapon_name, weapon_cost, CURRENCY_DISPLAY_NAME, replacement_note]
		status_label.text = "你持有 %d 个%s。" % [currency_count, CURRENCY_DISPLAY_NAME]

	if not can_afford:
		_awaiting_weapon_replacement = false
		status_label.text = "原质不足：需要 %d 个%s，你现在有 %d 个。" % [
			weapon_cost,
			CURRENCY_DISPLAY_NAME,
			currency_count,
		]
		hint_label.text = "清理样本获取原质碎片后再回来交易。"
	elif quick_slots_full:
		_enter_weapon_replacement_mode()
	elif weapon_cost <= 0:
		hint_label.text = "按 F 领取并装备。"
	else:
		hint_label.text = "按 F 购买并装备。"


func _show_no_weapon_stock(character: Node2D) -> void:
	_selected_offer_type = OFFER_NONE
	_selected_weapon_scene = null
	_selected_weapon_name = ""
	_clear_offer_preview()

	var currency_count := _get_currency_count(character)
	stock_label.text = "库存：当前无武器可供购买。"
	status_label.text = "你持有 %d 个%s。%s可用于购买武器。" % [
		currency_count,
		CURRENCY_DISPLAY_NAME,
		CURRENCY_DISPLAY_NAME,
	]
	hint_label.text = "本商人没有新的武器库存。离开商店，前往下一处渡鸦军械终端。"


func _try_purchase(character: Node2D, replacement_slot := -1) -> void:
	var validation := _validate_purchase(character)
	if not bool(validation.get("ok", false)):
		status_label.text = str(validation.get("message", "交易失败。"))
		INTERACTION_FEEDBACK.show_from(self, status_label.text, 1.4)
		if bool(validation.get("refresh", false)):
			_refresh_offer(character)
		return

	if _selected_offer_type == OFFER_WEAPON and replacement_slot < 0 and _are_quick_slots_full(character):
		_enter_weapon_replacement_mode()
		return

	if _selected_offer_type == OFFER_WEAPON and use_weapon_comparison and replacement_slot < 0:
		_show_purchase_comparison(character, validation.get("weapon_holder") as Node)
		return

	_complete_purchase(character, replacement_slot)


func _validate_purchase(character: Node2D) -> Dictionary:
	if _selected_offer_type == OFFER_NONE:
		return {"ok": false, "message": "当前无武器可供购买。原质碎片可用于购买武器。"}
	if _selected_offer_type == OFFER_WEAPON and _selected_weapon_scene == null:
		return {"ok": false, "message": "渡鸦暂时没有可售武器。"}

	var inventory := character.get("inventory") as QuiverInventory
	if inventory == null:
		return {"ok": false, "message": "未检测到背包连接。渡鸦拒绝交易。"}

	var currency_count := int(inventory.get_item_amount(CURRENCY_NAME))
	if currency_count < weapon_cost:
		return {
			"ok": false,
			"message": "需要 %d 个%s，你现在有 %d 个。" % [weapon_cost, CURRENCY_DISPLAY_NAME, currency_count],
		}

	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("add_weapon_scene"):
		return {"ok": false, "message": "未检测到武器挂架。"}
	if weapon_holder.has_method("has_weapon_scene") and bool(weapon_holder.call("has_weapon_scene", _selected_weapon_scene)):
		return {
			"ok": false,
			"message": "你已经拥有 %s。渡鸦换了一件货。" % _selected_weapon_name,
			"refresh": true,
		}

	return {
		"ok": true,
		"inventory": inventory,
		"weapon_holder": weapon_holder,
	}


func _show_purchase_comparison(character: Node2D, weapon_holder: Node) -> void:
	if _has_active_choice_overlay():
		return

	var has_free_slot := true
	if weapon_holder.has_method("has_free_quick_slot"):
		has_free_slot = bool(weapon_holder.call("has_free_quick_slot"))

	var price_text := "价格：免费"
	if weapon_cost > 0:
		price_text = "价格：%d 个%s" % [weapon_cost, CURRENCY_DISPLAY_NAME]

	_choice_overlay = WEAPON_CHOICE_OVERLAY.present(self, {
		"weapon_holder": weapon_holder,
		"weapon_scene": _selected_weapon_scene,
		"title": "渡鸦交易确认",
		"action": "购买",
		"cost": price_text,
		"allow_empty_slot": has_free_slot,
	})
	var active_overlay := _choice_overlay
	_choice_overlay.tree_exiting.connect(func() -> void:
		if _choice_overlay == active_overlay:
			_choice_overlay = null
	)
	_choice_overlay.confirmed.connect(func(slot_index: int) -> void:
		_choice_overlay = null
		if is_instance_valid(character):
			_complete_purchase(character, slot_index)
	)
	_choice_overlay.cancelled.connect(func() -> void:
		_choice_overlay = null
		status_label.text = "交易已取消，未消耗%s。" % CURRENCY_DISPLAY_NAME
	)


func _complete_purchase(character: Node2D, replacement_slot := -1) -> void:
	var validation := _validate_purchase(character)
	if not bool(validation.get("ok", false)):
		status_label.text = str(validation.get("message", "交易失败。"))
		INTERACTION_FEEDBACK.show_from(self, status_label.text, 1.4)
		if bool(validation.get("refresh", false)):
			_refresh_offer(character)
		return

	var inventory := validation.get("inventory") as QuiverInventory
	var weapon_holder := validation.get("weapon_holder") as Node
	if inventory == null or weapon_holder == null:
		status_label.text = "交易连接中断。"
		return

	var purchased_scene := _selected_weapon_scene
	var purchased_name := _selected_weapon_name
	var replaced_weapon_name := ""
	var replaced_weapon_scene: PackedScene
	var slot_index := -1
	if weapon_holder.has_method("has_free_quick_slot") and not bool(weapon_holder.call("has_free_quick_slot")):
		if replacement_slot < 0:
			_enter_weapon_replacement_mode()
			return
		if not weapon_holder.has_method("replace_weapon_scene_in_slot"):
			status_label.text = "武器栏已满，当前挂架不支持替换。"
			return
		if weapon_holder.has_method("get_weapon_display_name_at_slot"):
			replaced_weapon_name = str(weapon_holder.call("get_weapon_display_name_at_slot", replacement_slot))
		replaced_weapon_scene = _get_weapon_scene_at_slot(weapon_holder, replacement_slot)
		slot_index = int(weapon_holder.call("replace_weapon_scene_in_slot", purchased_scene, replacement_slot))
	else:
		slot_index = int(weapon_holder.add_weapon_scene(purchased_scene, equip_purchase_immediately))
	if slot_index < 0:
		status_label.text = "武器转移失败。"
		return

	if weapon_cost > 0:
		inventory.remove_item(CURRENCY_NAME, weapon_cost)
	if replaced_weapon_scene != null:
		_retire_weapon_scene(weapon_holder, replaced_weapon_scene)

	_refresh_offer(character)
	var no_weapon_stock_after_purchase := _selected_offer_type == OFFER_NONE
	if replaced_weapon_name != "":
		status_label.text = "已获得 %s，替换了 %s，并装备到 %d 号位。" % [purchased_name, replaced_weapon_name, slot_index + 1]
	elif weapon_cost <= 0:
		status_label.text = "已领取 %s，加入 %d 号位。" % [purchased_name, slot_index + 1]
	else:
		status_label.text = "已购买 %s，加入 %d 号位。" % [purchased_name, slot_index + 1]
	if no_weapon_stock_after_purchase:
		status_label.text += "\n当前无武器可供购买。%s可用于购买武器。" % CURRENCY_DISPLAY_NAME
		hint_label.text = "本商人没有新的武器库存。离开商店，前往下一处渡鸦军械终端。"
	INTERACTION_FEEDBACK.show_from(self, "交易完成：%s。" % purchased_name, 1.35)


func _enter_weapon_replacement_mode() -> void:
	_awaiting_weapon_replacement = true
	status_label.text = "武器栏已满：请选择要替换的槽位。确认前不会扣除%s。" % CURRENCY_DISPLAY_NAME
	hint_label.text = "按 1 / 2 / 3 / 4 替换对应武器并购买。"


func _has_active_choice_overlay() -> bool:
	if _choice_overlay == null:
		return false
	if is_instance_valid(_choice_overlay):
		return true
	_choice_overlay = null
	return false


func _close_choice_overlay() -> void:
	if _choice_overlay == null:
		return
	if is_instance_valid(_choice_overlay):
		_choice_overlay.queue_free()
	_choice_overlay = null


func _get_pressed_replacement_slot() -> int:
	for slot_index in range(4):
		var action_name := "weapon_slot_%d" % (slot_index + 1)
		if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
			return slot_index
	return -1


func _are_quick_slots_full(character: Node2D) -> bool:
	var weapon_holder := character.get_node_or_null("Visual/WeaponHolder")
	if weapon_holder == null or not weapon_holder.has_method("has_free_quick_slot"):
		return false
	return not bool(weapon_holder.call("has_free_quick_slot"))


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
		if _retired_weapon_keys.has(weapon_key):
			continue
		if not owned.has(weapon_key):
			return weapon_scene

	return null


func _get_weapon_scene_at_slot(weapon_holder: Node, slot_index: int) -> PackedScene:
	var weapon_scenes := weapon_holder.get("weapon_scenes") as Array
	if weapon_scenes == null or slot_index < 0 or slot_index >= weapon_scenes.size():
		return null
	return weapon_scenes[slot_index] as PackedScene


func _retire_weapon_scene(weapon_holder: Node, weapon_scene: PackedScene) -> void:
	if weapon_scene == null:
		return
	var weapon_key := weapon_scene.resource_path
	if weapon_holder.has_method("get_weapon_scene_key"):
		weapon_key = str(weapon_holder.call("get_weapon_scene_key", weapon_scene))
	if weapon_key != "":
		_retired_weapon_keys[weapon_key] = true


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
	_offer_preview_instance.scale = Vector2(0.45, 0.45)
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
